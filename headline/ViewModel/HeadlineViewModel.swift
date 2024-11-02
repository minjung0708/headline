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
    
    /// 기기에 저장된 데이터 불러오기
    let loadSavedHeadlines = PassthroughSubject<Void, Never>()
    /// 네트워크 통신을 통해 최신 데이터 불러오기
    let requestHeadlines = PassthroughSubject<HeadlineAPI.RequestParams, Never>()
    /// requestHeadlines 작업 종료 후, 기존 데이터 삭제 및 저장
    let completeRequestHeadlines = PassthroughSubject<[Headline], Never>()
    /// 국가 변경 후 데이터 불러오기 (최신 데이터 호출 -> api call 실패 시 기기에 저장된 데이터 호출)
    let changeCountry = PassthroughSubject<Void, Never>()
    /// 무한 스크롤 구현을 위해 다음 페이지 데이터 호출 (only api call)
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
                    totalCount = 0
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
                    ToastUtil.shared.show(msg: "실시간 데이터 조회에 실패했습니다.\n기기에 저장된 데이터를 조회합니다.")
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
                
                if requestParam.page == 1 {
                    // 첫 페이지 데이터를 불러올 땐 새로운 데이터 업데이트를 위해 기존 데이터 삭제
                    StorageUtil.shared.deleteAllItems(requestParam.country)
                        .filter { $0 == true }
                        .flatMap { _ in
                            return StorageUtil.shared.saveItems(headlines)
                        }
                        .sink  { result in
                            print("data save \(result ? "success" : "fail")")
                        }
                        .store(in: &cancellableSet)
                } else {
                    // 다음 페이지 데이터를 불러올 땐 삭제 없이 새로운 데이터 저장
                    StorageUtil.shared.saveItems(headlines)
                        .sink  { result in
                            print("data save \(result ? "success" : "fail")")
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
        _ = await StorageUtil.shared.saveImageInDocument(item)
        
        return item
    }
}
