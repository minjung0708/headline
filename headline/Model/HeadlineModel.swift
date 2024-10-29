//
//  HeadlineModel.swift
//  headline
//
//  Created by MinJung on 10/29/24.
//

import Foundation

struct HeadlineResult: Codable {
    var status: String?
    var totalResults: Int?
    var articles: [Article]?
}

struct Article: Codable {
    var source: Source?
    var author: String?
    var title: String?
    var description: String?
    var url: String?
    var urlToImage: String?
    var publishedAt: String?
    var content: String?
    
    struct Source: Codable {
        var id: String?
        var name: String?
    }
}
