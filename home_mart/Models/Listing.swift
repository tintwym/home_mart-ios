//
//  Listing.swift
//  home_mart
//

import Foundation

struct Listing: Identifiable, Hashable {
    let id: String
    var title: String
    var priceCents: Int
    var category: String
    var systemImageName: String
    var detail: String

    /// From `GET /mapi/listings` / detail — absolute URL when present.
    var imageURL: String? = nil
    var condition: String? = nil
    var meetupLocation: String? = nil
    var sellerDisplayName: String? = nil

    var formattedPrice: String {
        let amount = Decimal(priceCents) / 100
        return amount.formatted(.currency(code: "USD"))
    }

    nonisolated static let sampleListings: [Listing] = [
        Listing(
            id: "demo-1",
            title: "Oak dining table",
            priceCents: 449_00,
            category: "Furniture",
            systemImageName: "table.furniture",
            detail: "Solid oak, seats six. Light wear on one leg; otherwise excellent."
        ),
        Listing(
            id: "demo-2",
            title: "Velvet accent chair",
            priceCents: 189_00,
            category: "Furniture",
            systemImageName: "chair.lounge",
            detail: "Deep green velvet. Pet-free home. Pickup downtown."
        ),
        Listing(
            id: "demo-3",
            title: "Walnut bookshelf",
            priceCents: 265_00,
            category: "Furniture",
            systemImageName: "books.vertical.fill",
            detail: "Five shelves, wall-anchored hardware included."
        ),
        Listing(
            id: "demo-4",
            title: "Classic steel watch",
            priceCents: 320_00,
            category: "Watch",
            systemImageName: "watch.analog",
            detail: "Sapphire crystal, recent service. Box and papers."
        ),
        Listing(
            id: "demo-5",
            title: "Sport chronograph",
            priceCents: 198_00,
            category: "Watch",
            systemImageName: "applewatch",
            detail: "Water resistant, extra strap included."
        ),
        Listing(
            id: "demo-6",
            title: "Eau de parfum 100ml",
            priceCents: 89_00,
            category: "Perfumes",
            systemImageName: "sparkles",
            detail: "Unopened, sealed. Woody floral notes."
        ),
    ]
}
