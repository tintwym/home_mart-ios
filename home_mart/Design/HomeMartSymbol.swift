//
//  HomeMartSymbol.swift
//  home_mart
//

import Foundation

/// SF Symbol names for categories and listing placeholders (furniture / home marketplace).
enum HomeMartSymbol {

    /// Uses API-provided `icon` when set; otherwise maps slug + name keywords to a symbol.
    static func categoryIcon(slug: String, name: String, apiIcon: String?) -> String {
        if let raw = apiIcon?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty {
            return raw
        }
        return symbolMatching(slug: slug, name: name) ?? "house.fill"
    }

    /// Placeholder when a listing has no photo — uses category + title hints.
    static func listingPlaceholder(category: String, title: String) -> String {
        symbolMatching(slug: category, name: title) ?? "shippingbox.fill"
    }

    /// Longer / more specific phrases first so "bed frame" beats "bed".
    private static let keywordSymbols: [(String, String)] = [
        ("bookshelf", "books.vertical.fill"),
        ("bookcase", "books.vertical.fill"),
        ("bedroom set", "bed.double.fill"),
        ("bed frame", "bed.double.fill"),
        ("mattress", "bed.double.fill"),
        ("bathroom fixture", "shower.fill"),
        ("bath fixture", "shower.fill"),
        ("coffee table", "table.furniture.fill"),
        ("dining table", "table.furniture.fill"),
        ("side table", "table.furniture.fill"),
        ("nightstand", "cabinet.fill"),
        ("dresser", "cabinet.fill"),
        ("wardrobe", "cabinet.fill"),
        ("closet", "cabinet.fill"),
        ("office chair", "chair.fill"),
        ("desk chair", "chair.fill"),
        ("dining chair", "chair.fill"),
        ("accent chair", "chair.lounge.fill"),
        ("lounge chair", "chair.lounge.fill"),
        ("office desk", "desktopcomputer"),
        ("computer desk", "desktopcomputer"),
        ("standing desk", "desktopcomputer"),
        ("tv stand", "tv.fill"),
        ("entertainment", "tv.fill"),
        ("microwave", "microwave.fill"),
        ("refrigerator", "refrigerator.fill"),
        ("fridge", "refrigerator.fill"),
        ("washer", "washer.fill"),
        ("dryer", "dryer.fill"),
        ("laundry", "washer.fill"),
        ("stove", "oven.fill"),
        ("oven", "oven.fill"),
        ("range", "oven.fill"),
        ("outdoor", "leaf.fill"),
        ("patio", "umbrella.fill"),
        ("garden", "leaf.fill"),
        ("plant", "leaf.fill"),
        ("rug", "square.fill"),
        ("carpet", "square.fill"),
        ("curtain", "curtains.closed"),
        ("blind", "window.shade.closed"),
        ("mirror", "rectangle.portrait.fill"),
        ("frame", "photo.fill"),
        ("wall art", "photo.fill"),
        ("lamp", "lamp.desk.fill"),
        ("lighting", "lightbulb.fill"),
        ("chandelier", "light.ceiling.fill"),
        ("ceiling fan", "fan.fill"),
        ("fan", "fan.fill"),
        ("air conditioner", "fan.fill"),
        ("vacuum", "circle.grid.cross.fill"),
        ("storage", "archivebox.fill"),
        ("shelf", "books.vertical.fill"),
        ("cabinet", "cabinet.fill"),
        ("bathroom", "shower.fill"),
        ("toilet", "toilet.fill"),
        ("sink", "sink.fill"),
        ("bathtub", "bathtub.fill"),
        ("shower", "shower.fill"),
        ("towel", "hand.raised.fill"),
        ("sofa", "sofa.fill"),
        ("couch", "sofa.fill"),
        ("sectional", "sofa.fill"),
        ("loveseat", "sofa.fill"),
        ("ottoman", "rectangle.rounded.fill"),
        ("bench", "chair.fill"),
        ("stool", "chair.fill"),
        ("bar stool", "chair.fill"),
        ("chair", "chair.fill"),
        ("table", "table.furniture.fill"),
        ("bed", "bed.double.fill"),
        ("watch", "watch.analog"),
        ("clock", "clock.fill"),
        ("perfume", "sparkles"),
        ("fragrance", "sparkles"),
        ("scent", "sparkles"),
        ("jewelry", "diamond.fill"),
        ("kitchen", "fork.knife"),
        ("dining", "fork.knife"),
        ("baby", "figure.and.child.holdinghands"),
        ("kids", "figure.and.child.holdinghands"),
        ("toy", "gamecontroller.fill"),
        ("pet", "pawprint.fill"),
        ("dog", "dog.fill"),
        ("cat", "cat.fill"),
        ("tool", "hammer.fill"),
        ("hardware", "wrench.and.screwdriver.fill"),
        ("paint", "paintbrush.fill"),
        ("decor", "paintpalette.fill"),
        ("vase", "vase.fill"),
        ("furniture", "sofa.fill"),
        ("furnishing", "lamp.floor.fill"),
    ]

    private static func symbolMatching(slug: String, name: String) -> String? {
        let hay = (slug + " " + name).lowercased()
        for (needle, symbol) in keywordSymbols where hay.contains(needle) {
            return symbol
        }
        return nil
    }
}
