//
//  HeadlineViewModel.swift
//  headline
//
//  Created by MinJung on 10/29/24.
//

import Foundation
import Combine
import SwiftUI

class HeadlineViewModel: ObservableObject {
    @Published private(set) var totalCount: Int = 0
    @Published private(set) var headlines: [Headline] = []
    @Published private(set) var isLoading = false
    @Published private(set) var requestParam: HeadlineAPI.RequestParams
    
    let loadSavedHeadlines = PassthroughSubject<Void, Never>()
    let requestHeadlines = PassthroughSubject<HeadlineAPI.RequestParams, Never>()
    let completeRequestHeadlines = PassthroughSubject<[Headline], Never>()
    let changeCountry = PassthroughSubject<Void, Never>()
    let requestHeadlinesMore = PassthroughSubject<Void, Never>()
    
    private var cancellableSet: Set<AnyCancellable> = []
    
    init() {
        requestParam = .init(country: .kr)
        bindEvents()
        requestHeadlines.send(requestParam)
    }
}

extension HeadlineViewModel {
    private func bindEvents() {
        loadSavedHeadlines
            .map { [weak self] _ in
                return self?.requestParam.country
            }
            .compactMap { $0 }
            .flatMap { country in
                return StorageUtil.shared.loadAllItems(country)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] headlines in
                guard let self else { return }
                self.headlines = headlines ?? []
                totalCount = headlines?.count ?? 0
                isLoading = false
            }
            .store(in: &cancellableSet)
        
        requestHeadlines
            .map { [weak self] param in
                guard let self else {
                    return nil
                }
                
                requestParam = param
                isLoading = true
                
                if param.page == 1 {
                    headlines = []
                }
                
                return param
            }
            .compactMap { $0 }
            .flatMap { param in
                return HeadlineAPI.shared.requestHeadlines(requestParams: param)
            }
            .sink { [weak self] response in
                guard let self else { return }
                
                switch response {
                case.success(let result):
                    guard result.status == "ok" else { return }
                    
                    totalCount = result.totalResults ?? 0
                    
                    Task { [weak self] in
                        guard let self else { return }
                        var newHeadlines: [Headline] = []
                        
                        for article in result.articles ?? [] {
                            let item = await convertData(article: article, country: requestParam.country)
                            let clone = item
                            newHeadlines.append(clone)
                            
                            Task { @MainActor [weak self] in
                                guard let self else { return }
                                headlines.append(clone)
                            }
                        }
                        
                        completeRequestHeadlines.send(newHeadlines)
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    loadSavedHeadlines.send()
                }
            }
            .store(in: &cancellableSet)
        
        completeRequestHeadlines
            .receive(on: DispatchQueue.main)
            .map { [weak self] headlines in
                self?.isLoading = false
                return headlines
            }
            .receive(on: DispatchQueue.global())
            .sink { [weak self] headlines in
                guard let self else { return }
                
                if headlines.isEmpty {
                    StorageUtil.shared.deleteAllItems()
                        .filter { $0 == true }
                        .flatMap { _ in
                            print("All data is deleted.")
                            return StorageUtil.shared.saveItems(headlines)
                        }
                        .sink { isSaved in
                            print("data is saved \(isSaved ? "successfully" : "fail")")
                        }
                        .store(in: &cancellableSet)
                } else {
                    StorageUtil.shared.saveItems(headlines)
                        .sink { isSaved in
                            print("data is saved \(isSaved ? "successfully" : "fail")")
                        }
                        .store(in: &cancellableSet)
                }
            }
            .store(in: &cancellableSet)
        
        changeCountry
            .sink { [weak self] _ in
                guard let self else { return }
                guard isLoading == false else { return }
                
                switch requestParam.country {
                case .kr:
                    requestHeadlines.send(.init(country: .us))
                case .us:
                    requestHeadlines.send(.init(country: .kr))
                }
            }
            .store(in: &cancellableSet)
        
        requestHeadlinesMore
            .sink { [weak self] _ in
                guard let self else { return }
                requestHeadlines.send(.init(
                    country: requestParam.country,
                    pageSize: requestParam.pageSize,
                    page: requestParam.page + 1)
                )
            }
            .store(in: &cancellableSet)
    }
    
    private func convertData(article: Article, country: HeadlineAPI.QueryParam.Country) async -> Headline {
        let item = Headline()
        item.country = country.rawValue
        item.title = article.title
        item.imageUrl = article.urlToImage
        item.publishedAt = article.publishedAt
        item.url = article.url
        if item.image == nil {
            _ = await StorageUtil.shared.saveImageToDocument(item)
        }
        
        return item
    }
}
