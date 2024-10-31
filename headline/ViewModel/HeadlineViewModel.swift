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
    @Published var status: ViewStatus = .loading
    @Published var totalCount: Int = 0
    @Published var headlines: [Headline] = []
    
    let loadSavedHeadlines = PassthroughSubject<Void, Never>()
    let requestHeadlines = PassthroughSubject<HeadlineAPI.RequestParams, Never>()
    let completeRequestHeadlines = PassthroughSubject<[Headline], Never>()
    
    private var cancellableSet: Set<AnyCancellable> = []
    
    enum ViewStatus {
        case loading
        case finished
        case error
    }
    
    init() {
        bindEvents()
        requestHeadlines.send(.init(country: .us))
    }
}

extension HeadlineViewModel {
    private func bindEvents() {
        loadSavedHeadlines
            .flatMap { _ in
                return StorageUtil.shared.loadAllItems()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] headlines in
                self?.headlines = headlines ?? []
            }
            .store(in: &cancellableSet)
        
        requestHeadlines
            .flatMap { [weak self] param in
                if param.page == 0 {
                    self?.headlines = []
                }
                return HeadlineAPI.shared.requestHeadlines(requestParams: param)
            }
            .sink { [weak self] result in
                switch result {
                case .finished:
                    print("headlines request api call is finished.")
                case .failure(let failure):
                    print(failure.localizedDescription)
                    self?.loadSavedHeadlines.send()
                }
            } receiveValue: { [weak self] result in
                guard let self else { return }
                guard result.status == "ok" else {
                    status = .error
                    return
                }
                
                Task { [weak self] in
                    guard let self else { return }
                    var headlines: [Headline] = []
                    
                    for article in result.articles ?? [] {
                        headlines.append(await convertData(article))
                        let clones = headlines
                        
                        Task { @MainActor [weak self] in
                            guard let self else { return }
                            self.headlines = clones
                        }
                    }
                }
                
                status = .finished
                completeRequestHeadlines.send(headlines)
            }
            .store(in: &cancellableSet)
        
        completeRequestHeadlines
            .sink { [weak self] headlines in
                guard let self else { return }
                StorageUtil.shared.deleteAllItems()
                    .filter { $0 == true }
                    .flatMap { _ in
                        StorageUtil.shared.saveItems(headlines)
                    }
                    .sink { isSaved in
                        print("data is saved \(isSaved ? "successfully" : "fail")")
                    }
                    .store(in: &cancellableSet)
            }
            .store(in: &cancellableSet)
    }
    
    private func convertData(_ article: Article) async -> Headline {
        let item = Headline()
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
