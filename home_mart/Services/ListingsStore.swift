//
//  ListingsStore.swift
//  home_mart
//

import Foundation
import Observation

@MainActor
@Observable
final class ListingsStore {
    private(set) var listings: [Listing]
    private(set) var isRefreshing = false
    private var hasCompletedInitialFetch = false

    init(listings: [Listing]? = nil) {
        self.listings = listings ?? []
    }

    /// Shows `listings` immediately; replaces them only if the server returns valid JSON.
    func refreshFromNetworkIfAvailable(force: Bool = false) async {
        if !force, hasCompletedInitialFetch { return }
        guard !isRefreshing else { return }
        isRefreshing = true
        defer {
            isRefreshing = false
            hasCompletedInitialFetch = true
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = APIConfiguration.feedRequestTimeout
        configuration.timeoutIntervalForResource = APIConfiguration.feedResourceTimeout
        configuration.waitsForConnectivity = true
        let session = URLSession(configuration: configuration)

        for url in APIConfiguration.listingCandidateURLs {
            for request in Self.listingFeedRequests(for: url) {
                do {
                    let (data, response) = try await session.data(for: request)
                    guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else { continue }
                    if let parsed = ListingsPayloadDecoder.listingsFeed(from: data) {
                        listings = parsed
                        return
                    }
                } catch {
                    continue
                }
            }
        }
    }

    /// `GET /mapi/listings/{id}` — body `{ "data": { ... } }`. Public; no Bearer required.
    static func fetchListingDetail(id: String) async -> Listing? {
        let url = APIConfiguration.listingDetailURL(id: id)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = APIConfiguration.feedRequestTimeout
        configuration.timeoutIntervalForResource = APIConfiguration.feedResourceTimeout
        configuration.waitsForConnectivity = true
        let session = URLSession(configuration: configuration)

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else { return nil }
            return ListingsPayloadDecoder.listingDetail(from: data)
        } catch {
            return nil
        }
    }

    /// Feed: `GET` then `POST` fallback. Categories/listings are public — no `Authorization`.
    private static func listingFeedRequests(for url: URL) -> [URLRequest] {
        var get = URLRequest(url: url)
        get.httpMethod = "GET"
        get.setValue("application/json", forHTTPHeaderField: "Accept")

        var post = URLRequest(url: url)
        post.httpMethod = "POST"
        post.setValue("application/json", forHTTPHeaderField: "Accept")
        post.setValue("application/json", forHTTPHeaderField: "Content-Type")
        post.httpBody = Data("{}".utf8)

        return [get, post]
    }
}

// MARK: - JSON

private enum ListingsPayloadDecoder {
    /// Decodes a recognized listings feed (including **empty** `data` from Laravel pagination). Returns `nil` if the JSON is not a feed shape.
    static func listingsFeed(from data: Data) -> [Listing]? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        if let feed = try? decoder.decode(ListingsFeedEnvelope.self, from: data) {
            guard feed.meta != nil || feed.data != nil else { return nil }
            let rows = feed.data ?? []
            return rows.compactMap { $0.toListing() }
        }
        if let envelope = try? decoder.decode(ListingsEnvelope.self, from: data) {
            guard envelope.data != nil || envelope.listings != nil else { return nil }
            let rows = envelope.data ?? envelope.listings ?? []
            return rows.compactMap { $0.toListing() }
        }
        if let rows = try? decoder.decode([ListingDTO].self, from: data) {
            return rows.compactMap { $0.toListing() }
        }
        return nil
    }

    static func listingDetail(from data: Data) -> Listing? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        if let env = try? decoder.decode(ListingDetailEnvelope.self, from: data) {
            return env.data.toListing()
        }
        if let dto = try? decoder.decode(ListingDTO.self, from: data) {
            return dto.toListing()
        }
        return nil
    }
}

private struct ListingsFeedEnvelope: Decodable {
    var data: [ListingDTO]?
    var meta: ListingsFeedMeta?
}

private struct ListingsFeedMeta: Decodable {
    var currentPage: Int?
    var lastPage: Int?
    var perPage: Int?
    var total: Int?
}

private struct ListingsEnvelope: Decodable {
    var data: [ListingDTO]?
    var listings: [ListingDTO]?
}

private struct ListingDetailEnvelope: Decodable {
    var data: ListingDTO
}

private struct CategoryNested: Decodable {
    var name: String?
    var slug: String?
}

private struct SellerNested: Decodable {
    var name: String?
}

/// Decodes either a plain string or `{ "name", "slug", ... }`.
private struct CategoryOrString: Decodable {
    let string: String?
    let nested: CategoryNested?

    init(from decoder: Decoder) throws {
        if let c = try? decoder.singleValueContainer(), let s = try? c.decode(String.self) {
            string = s
            nested = nil
            return
        }
        string = nil
        nested = try CategoryNested(from: decoder)
    }
}

private struct ListingDTO: Decodable {
    var id: FlexibleID
    var title: String?
    var name: String?
    var description: String?
    var detail: String?
    var condition: String?
    var meetupLocation: String?
    var imageUrl: String?
    var priceCents: Int?
    var price: PriceField?
    var category: CategoryOrString?
    var seller: SellerNested?

    enum PriceField: Decodable {
        case double(Double)
        case string(String)

        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if let d = try? c.decode(Double.self) {
                self = .double(d)
                return
            }
            if let s = try? c.decode(String.self) {
                self = .string(s)
                return
            }
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "price")
        }

        var cents: Int {
            switch self {
            case .double(let d):
                return Int((d * 100).rounded())
            case .string(let s):
                let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
                return Int(((Double(t) ?? 0) * 100).rounded())
            }
        }
    }

    func toListing() -> Listing? {
        let rawTitle = (title ?? name)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !rawTitle.isEmpty else { return nil }

        let cents: Int
        if let pc = priceCents {
            cents = pc
        } else if let p = price {
            cents = p.cents
        } else {
            cents = 0
        }

        let categoryLabel: String
        if let c = category {
            if let s = c.string {
                categoryLabel = s.trimmingCharacters(in: .whitespacesAndNewlines)
            } else if let n = c.nested {
                categoryLabel = (n.name ?? n.slug ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                categoryLabel = ""
            }
        } else {
            categoryLabel = ""
        }
        let cat = categoryLabel.isEmpty ? "General" : categoryLabel

        let body = [description, detail].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }.first { !$0.isEmpty }
        let det = body ?? "—"

        let trimmedImage = imageUrl?.trimmingCharacters(in: .whitespacesAndNewlines)
        let imageURL = (trimmedImage?.isEmpty == false) ? trimmedImage : nil

        return Listing(
            id: id.value,
            title: rawTitle,
            priceCents: cents,
            category: cat,
            systemImageName: imageURL != nil
                ? "photo.fill"
                : HomeMartSymbol.listingPlaceholder(category: cat, title: rawTitle),
            detail: det,
            imageURL: imageURL,
            condition: condition?.trimmingCharacters(in: .whitespacesAndNewlines),
            meetupLocation: meetupLocation?.trimmingCharacters(in: .whitespacesAndNewlines),
            sellerDisplayName: seller?.name?.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    struct FlexibleID: Decodable {
        let value: String

        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if let i = try? c.decode(Int.self) {
                value = String(i)
                return
            }
            if let s = try? c.decode(String.self) {
                value = s
                return
            }
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Expected string or int id")
        }
    }
}
