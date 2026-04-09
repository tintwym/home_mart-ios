//
//  CategoriesStore.swift
//  home_mart
//

import Foundation
import Observation

/// Loads categories from Laravel (`GET /mapi/categories`). Shapes supported:
/// `{ "data": [ { "id", "name", "slug", "category_id"? } ] }`, etc.
/// Rows with a non-null **`category_id`** are treated as **subcategories** and omitted from the navbar (only top-level categories are shown).
@MainActor
@Observable
final class CategoriesStore {
    private(set) var categories: [StoreCategory]
    private(set) var isRefreshing = false
    private var hasCompletedInitialFetch = false

    init(categories: [StoreCategory] = []) {
        self.categories = categories
    }

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

        for url in APIConfiguration.categoryCandidateURLs {
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else { continue }
                let parsed = CategoriesPayloadDecoder.categories(from: data)
                categories = parsed
                return
            } catch {
                continue
            }
        }
    }
}

// MARK: - JSON

private extension Optional where Wrapped == String {
    var nilIfEmptyTrimmed: String? {
        guard let s = self?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        return s
    }
}

private enum CategoriesPayloadDecoder {
    static func categories(from data: Data) -> [StoreCategory] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        if let envelope = try? decoder.decode(CategoriesEnvelope.self, from: data) {
            let rows = envelope.data ?? envelope.categories ?? []
            return rows.compactMap { $0.toStoreCategory() }
        }
        if let rows = try? decoder.decode([CategoryDTO].self, from: data) {
            return rows.compactMap { $0.toStoreCategory() }
        }
        return []
    }
}

private struct CategoriesEnvelope: Decodable {
    var data: [CategoryDTO]?
    var categories: [CategoryDTO]?
}

private struct CategoryDTO: Decodable {
    var id: FlexibleCategoryID
    var name: String?
    var title: String?
    var slug: String?
    /// Parent category id when this row is a **subcategory**; `null` / absent = top-level (show in navbar).
    var categoryId: String?
    var icon: String?
    var iconName: String?
    var systemImage: String?

    func toStoreCategory() -> StoreCategory? {
        if let parent = categoryId?.trimmingCharacters(in: .whitespacesAndNewlines), !parent.isEmpty {
            return nil
        }
        let label = (name ?? title)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !label.isEmpty else { return nil }
        let slugValue = slug.nilIfEmptyTrimmed
            ?? label.lowercased().replacingOccurrences(of: " ", with: "-")
        let apiIcon = icon.nilIfEmptyTrimmed ?? iconName.nilIfEmptyTrimmed ?? systemImage.nilIfEmptyTrimmed
        return StoreCategory(id: id.value, name: label, slug: slugValue, iconSystemName: apiIcon)
    }

    struct FlexibleCategoryID: Decodable {
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
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Expected id")
        }
    }
}

