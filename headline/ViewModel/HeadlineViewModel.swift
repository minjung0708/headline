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
    
    let requestHeadlines = PassthroughSubject<HeadlineAPI.RequestParams, Never>()
    
    private var cancellableSet: Set<AnyCancellable> = []
    
    enum ViewStatus {
        case loading
        case finished
        case error
    }
    
    struct Headline: Identifiable {
        var id = UUID()
        var title: String?
        var imageUrl: String?
        var image: Image?
        var publised: String?
        var visited: Bool = false
    }
    
    init() {
        bindEvents()
    }
}

extension HeadlineViewModel {
    private func bindEvents() {
        requestHeadlines
            .flatMap { [weak self] param in
                if param.page == 0 {
                    self?.headlines = []
                }
                return HeadlineAPI.shared.requestHeadlines(requestParams: param)
            }
            .sink { result in
                switch result {
                case .finished:
                    print("headlines request api call is finished.")
                case .failure(let failure):
                    print(failure.localizedDescription)
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
                    }
                }
            }
            .store(in: &cancellableSet)
    }
    
    private func convertData(_ data: HeadlineResult) async -> [Headline] {
        var result: [Headline] = []
        
        for article in data.articles ?? [] {
            let item = Headline(
                id: UUID(),
                title: article.title,
                imageUrl: article.urlToImage,
                image: await loadImage(article.urlToImage),
                publised: article.publishedAt
            )
            result.append(item)
        }
        
        return result
    }
    
    private func loadImage(_ imageUrl: String?) async -> Image? {
        guard let imageUrl else { return nil }
        
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
