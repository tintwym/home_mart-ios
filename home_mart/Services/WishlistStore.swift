//
//  WishlistStore.swift
//  home_mart
//

import Foundation
import Observation

private let wishlistUserDefaultsKey = "home_mart.wishlistListingIds"

/// Saved listing IDs for the wishlist heart on cards (persisted).
@MainActor
@Observable
final class WishlistStore {
    static let shared = WishlistStore()

    private(set) var ids: Set<String> = []

    private init() {
        if let arr = UserDefaults.standard.array(forKey: wishlistUserDefaultsKey) as? [String] {
            ids = Set(arr)
        }
    }

    func contains(_ listingId: String) -> Bool {
        ids.contains(listingId)
    }

    func toggle(_ listingId: String) {
        if ids.contains(listingId) {
            ids.remove(listingId)
        } else {
            ids.insert(listingId)
        }
        UserDefaults.standard.set(Array(ids), forKey: wishlistUserDefaultsKey)
    }
}
