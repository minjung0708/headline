//
//  StorageUtil.swift
//  headline
//
//  Created by MinJung on 10/30/24.
//

import Foundation
import RealmSwift
import Combine
import SwiftUI
import CryptoKit

class Headline: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id = UUID()
    @Persisted var country: String?
    @Persisted var title: String?
    @Persisted var imageUrl: String?
    @Persisted var publishedAt: String?
    @Persisted var url: String?
    @Persisted var createdAt = Date()
    
    var publishedAtText: String? {
        guard let publishedAt else {
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        
        guard let date = formatter.date(from: publishedAt) else {
            return nil
        }
        
        formatter.dateFormat = "yyyy-MM-dd a hh:mm"
        return formatter.string(from: date)
    }
    
    var image: Image? {
        StorageUtil.shared.loadSavedImageFromDocument(self)
    }
    
    var imageName: String? {
        guard let imageUrl,
              let data = imageUrl.data(using: .utf8) else {
            return nil
        }
        
        let output = SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
        return StorageUtil.Constants.imagePrefix + output + StorageUtil.Constants.extPng
    }
}

class StorageUtil {
    enum Constants {
        static let imagePrefix = "thumbnail_"
        static let extPng = ".png"
    }
    static let shared = StorageUtil()
    private init() { }
}

// Realm

extension StorageUtil {
    func saveItems(_ items: [Headline]) -> AnyPublisher<Bool, Never> {
        Deferred {
            Future { promise in
                Task {
                    guard let realm = try? Realm() else {
                        promise(.success(false))
                        return
                    }
                    
                    let clones = items.map { Headline(value: $0) }
                    
                    try? realm.write {
                        for item in clones {
                            realm.add(item, update: .modified)
                        }
                    }
                    
                    promise(.success(true))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func loadAllItems(_ country: HeadlineAPI.QueryParam.Country) -> AnyPublisher<[Headline]?, Never> {
        Deferred {
            Future { promise in
                Task {
                    guard let realm = try? Realm() else {
                        promise(.success(nil))
                        return
                    }
                    
                    let results = realm.objects(Headline.self).filter("country == '\(country.rawValue)'")
                    promise(.success(results.map { Headline(value: $0) }))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteAllItems() -> AnyPublisher<Bool, Never> {
        Deferred {
            Future { promise in
                Task {
                    guard let realm = try? Realm() else {
                        promise(.success(false))
                        return
                    }
                    
                    let items = realm.objects(Headline.self)
                    
                    try? realm.write {
                        for item in items {
                            realm.delete(item)
                        }
                    }
                    
                    promise(.success(true))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

// Document

extension StorageUtil {
    func saveImageInDocument(_ headline: Headline) async -> Bool {
        guard let image = await loadImage(headline.imageUrl),
              let imageName = headline.imageName else {
            return false
        }
        
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        
        let imageDirectory = documentDirectory.appendingPathComponent(imageName)
        
        if FileManager.default.fileExists(atPath: imageDirectory.path) {
            // 저장하려는 경로에 이미 이미지가 존재하는 경우 저장 과정을 거치지 않고 함수 종료
            return true
        }
        
        guard let data = image.pngData() else {
            return false
        }
        
        do {
            try data.write(to: imageDirectory)
        } catch {
            return false
        }
        
        return true
    }
    
    func loadSavedImageFromDocument(_ headline: Headline) -> Image? {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
              let imageName = headline.imageName else {
            return nil
        }
        
        let imageDirectory = documentDirectory.appendingPathComponent(imageName)
        
        if let uiImage = UIImage(contentsOfFile: imageDirectory.path) {
            return Image(uiImage: uiImage)
        } else {
            return nil
        }
    }
    
    func deleteAllSavedImageInDocument() -> Bool {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentDirectory, includingPropertiesForKeys: nil)
            for file in files where file.lastPathComponent.hasPrefix(StorageUtil.Constants.imagePrefix) {
                try FileManager.default.removeItem(at: file)
            }
        } catch {
            return false
        }
        
        return true
    }
    
    private func loadImage(_ imageUrl: String?) async -> UIImage? {
        guard let imageUrl,
              let url = URL(string: imageUrl) else {
            return nil
        }
        
        return await withCheckedContinuation { continuation in
            URLSession.shared.downloadTask(with: url) { url, response, error in
                guard error == nil else {
                    return continuation.resume(returning: nil)
                }
                
                if let url, let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data) {
                    return continuation.resume(returning: uiImage)
                } else {
                    return continuation.resume(returning: nil)
                }
            }.resume()
        }
    }
}

// UserDefaults

extension StorageUtil {
    func saveUserDefaults(_ headline: Headline) {
        guard let url = headline.url else { return }
        // UserDefaults에 [방문한 url 주소: 방문한 날짜] 저장
        UserDefaults.standard.setValue(Date.now, forKey: url)
    }
    
    func checkUserDefaults(_ headline: Headline) -> Bool {
        guard let url = headline.url else {
            return false
        }
        return (UserDefaults.standard.value(forKey: url) as? Date != nil)
    }
}
