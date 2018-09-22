//
//  HashStorage.swift
//  ImageLoader
//
//  Created by Hirohisa Kawasaki on 11/7/16.
//  Copyright © 2016 Hirohisa Kawasaki. All rights reserved.
//

import Foundation

class HashStorage<K: Hashable, V: Equatable> {
    private var items = [K: V]()
    public init() {}
    public subscript(key: K) -> V? {
        get {
            objc_sync_enter(HashStorage.self)
            defer { objc_sync_exit(HashStorage.self) }
            return items[key]
        }
        set(value) {
            objc_sync_enter(HashStorage.self)
            defer { objc_sync_exit(HashStorage.self) }
            items[key] = value
        }
    }

    func getKey(_ value: V) -> K? {
        var key: K?
        items.forEach { k, v in
            if v == value {
                key = k
            }
        }

        return key
    }

}
