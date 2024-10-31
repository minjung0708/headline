//
//  HeadlineAPI.swift
//  headline
//
//  Created by MinJung on 10/29/24.
//

import Foundation
import Alamofire
import Combine

class HeadlineAPI {
    static let shared = HeadlineAPI()
    private init() { }
    private let headlineUrl = "https://newsapi.org/v2/top-headlines"
    
    enum QueryParam {
        enum Key: String {
            case country
            case apiKey
            case pageSize
            case page
        }
        enum Country: String {
            case us
            case kr
        }
    }
    
    struct RequestParams {
        var country: HeadlineAPI.QueryParam.Country
        var pageSize: Int = 20
        var page: Int = 1
    }
    
    enum NetworkError: Error {
        case incorrectUrl
        case noApiKey
    }
}

extension HeadlineAPI {
    func requestHeadlines(requestParams: RequestParams) -> AnyPublisher<HeadlineResult, AFError> {
        guard let plistUrl = Bundle.main.url(forResource: "Info", withExtension: "plist"),
              let plistData = try? Data(contentsOf: plistUrl),
              let dict = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? NSDictionary,
              let apiKey = dict["Api Key"] as? String else {
            return Fail(error: .createURLRequestFailed(error: NetworkError.noApiKey)).eraseToAnyPublisher()
        }
        
        guard var components = URLComponents(string: headlineUrl) else {
            return Fail(error: .createURLRequestFailed(error: NetworkError.incorrectUrl)).eraseToAnyPublisher()
        }
        
        components.queryItems = [
            URLQueryItem(name: QueryParam.Key.apiKey.rawValue, value: apiKey),
            URLQueryItem(name: QueryParam.Key.country.rawValue, value: requestParams.country.rawValue),
            URLQueryItem(name: QueryParam.Key.pageSize.rawValue, value: "\(requestParams.pageSize)"),
            URLQueryItem(name: QueryParam.Key.page.rawValue, value: "\(requestParams.page)"),
        ]
        
        guard let url = components.url else {
            return Fail(error: .createURLRequestFailed(error: NetworkError.incorrectUrl)).eraseToAnyPublisher()
        }
        
        return AF.request(
            url,
            method: .get
        ) { (request: inout URLRequest) in
            request.timeoutInterval = 10
        }
        .validate()
        .publishDecodable(type: HeadlineResult.self)
        .value()
    }
}
