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
        
        let stringToDateFormatter = DateFormatter()
        stringToDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        guard let date = stringToDateFormatter.date(from: publishedAt) else {
            return nil
        }
        
        let dateToStringFormatter = DateFormatter()
        dateToStringFormatter.dateFormat = "yyyy-MM-dd a hh:mm"
        dateToStringFormatter.locale = .current
        return dateToStringFormatter.string(from: date)
    }
    
    var image: Image? {
        StorageUtil.shared.loadSavedImageFromDocument(self)
    }
    
    var imageName: String? {
        guard let imageUrl else { return nil }
        guard let data = imageUrl.data(using: .utf8) else { return nil }
        let sha256 = SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
        return StorageUtil.Constants.imagePrefix + sha256 + StorageUtil.Constants.extPng
    }
}

class StorageUtil {
    enum Constants {
        static let imagePrefix = "thumbnail_"
        static let extPng = ".png"
    }
    static let shared = StorageUtil()
    private init() {
        if let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            print(documentsDirectory)
        }
    }
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
                    print("[CREATE] Items' count: \(clones.count)")
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
                    print("[SELECT] Country \(country.rawValue) items' count: \(results.count)")
                    promise(.success(results.map { Headline(value: $0) }))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteAllItems() -> AnyPublisher<Bool, Never> {
        Deferred {
            Future<Bool, Never> { promise in
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
                    print("[DELETE] Items' count: \(items.count)")
                    promise(.success(true))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

// Document

extension StorageUtil {
    func saveImageToDocument(_ headline: Headline) async -> Bool {
        guard let image = await loadImage(headline.imageUrl) else {
            return false
        }
        
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        
        guard let imageName = headline.imageName else {
            return false
        }
        
        let imageDirectory = documentDirectory.appendingPathComponent(imageName)
        
        if FileManager.default.fileExists(atPath: imageDirectory.path) {
            print("[SAVE] image is already saved in \(imageDirectory.path)")
            return true
        }
        
        guard let data = image.pngData() else {
            return false
        }
        
        do {
            try data.write(to: imageDirectory)
            print("[SAVE] image save in \(imageDirectory.path)")
        } catch {
            return false
        }
        
        return true
    }
    
    func loadSavedImageFromDocument(_ headline: Headline) -> Image? {
        let documentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let userDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let path = NSSearchPathForDirectoriesInDomains(documentDirectory, userDomainMask, true)
        
        if let directoryPath = path.first, let imageName = headline.imageName {
            let imageURL = URL(fileURLWithPath: directoryPath).appendingPathComponent(imageName)
            if let uiImage = UIImage(contentsOfFile: imageURL.path) {
                return Image(uiImage: uiImage)
            } else {
                return nil
            }
        }
        
        return nil
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
        UserDefaults.standard.setValue(Date.now, forKey: url)
    }
    
    func checkUserDefaults(_ headline: Headline) -> Bool {
        guard let url = headline.url else {
            return false
        }
        return (UserDefaults.standard.value(forKey: url) as? Date != nil)
    }
}
