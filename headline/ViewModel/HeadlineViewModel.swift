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
                    let headlines = await convertData(result)
                    
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        self.status = .finished
                        self.headlines = headlines
                        completeRequestHeadlines.send(headlines)
                    }
                }
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
    
    private func convertData(_ data: HeadlineResult) async -> [Headline] {
        var result: [Headline] = []
        
        for article in data.articles ?? [] {
            let item = Headline()
            item.title = article.title
            item.imageUrl = article.urlToImage
            item.publishedAt = convertPublisedDate(article.publishedAt)
            item.url = article.url
            result.append(item)
        }
        
        return result
    }
    
    private func convertPublisedDate(_ dateString: String?) -> Date? {
        guard let dateString else {
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return formatter.date(from: dateString)
    }
    
    private func loadImage(_ imageUrl: String?) async -> Image? {
        guard let imageUrl else {
            return nil
        }
        
        guard let urlEncoeded = imageUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: urlEncoeded) else {
            return nil
        }
        
        return await withCheckedContinuation { continuation in
            URLSession.shared.downloadTask(with: url) { url, response, error in
                if let url, let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data) {
                    let image = Image(uiImage: uiImage)
                    return continuation.resume(returning: image)
                } else {
                    return continuation.resume(returning: nil)
                }
            }.resume()
        }
    }
}
