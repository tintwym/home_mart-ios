//
//  StoreCategory.swift
//  home_mart
//

import SwiftUI

/// Category row from Laravel (e.g. `CategoryResource` / seeder). Used for tabs, circles, and listing filters.
struct StoreCategory: Identifiable, Hashable {
    let id: String
    let name: String
    let slug: String
    /// Optional SF Symbol name from API (`icon`, `icon_name`, etc.).
    let iconSystemName: String?

    /// SF Symbol for UI when API omits icon — falls back from `slug` + `name` keywords.
    func resolvedSystemImage() -> String {
        HomeMartSymbol.categoryIcon(slug: slug, name: name, apiIcon: iconSystemName)
    }

    func accentColor() -> Color {
        var hasher = Hasher()
        hasher.combine(slug)
        let h = Double(abs(hasher.finalize() % 360)) / 360.0
        return Color(hue: h, saturation: 0.42, brightness: 0.82)
    }

    /// Matches `Listing.category` to this category (name or slug from seeder/API).
    func matchesListingCategory(_ listingCategory: String) -> Bool {
        let l = listingCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        if l.caseInsensitiveCompare(name) == .orderedSame { return true }
        if l.caseInsensitiveCompare(slug) == .orderedSame { return true }
        let normalized = l.lowercased().replacingOccurrences(of: " ", with: "-")
        return normalized == slug.lowercased()
    }
}
