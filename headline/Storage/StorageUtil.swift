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

class Headline: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id = UUID()
    @Persisted var title: String?
    @Persisted var imageUrl: String?
    @Persisted var publishedAt: Date?
    @Persisted var url: String?
    @Persisted var visited: Bool = false
    @Persisted var createdAt = Date()
    
    var publishedAtText: String? {
        guard let publishedAt else {
            return nil
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd a hh:mm"
        formatter.locale = .current
        return formatter.string(from: publishedAt)
    }
    
    var image: Image? {
        // TODO: 이미지 document 캐싱 로직 추가
        return nil
    }
}

class StorageUtil {
    static let shared = StorageUtil()
    private init() {
        if let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            print(documentsDirectory)
        }
    }
}

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
                            realm.add(item)
                        }
                    }
                    print("[CREATE] Items' count: \(clones.count)")
                    promise(.success(true))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func loadAllItems() -> AnyPublisher<[Headline]?, Never> {
        Deferred {
            Future { promise in
                Task {
                    guard let realm = try? Realm() else {
                        promise(.success(nil))
                        return
                    }
                    
                    let results = realm.objects(Headline.self)
                    print("[SELECT] Items' count: \(results.count)")
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
