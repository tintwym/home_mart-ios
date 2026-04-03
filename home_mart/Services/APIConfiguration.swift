//
//  APIConfiguration.swift
//  home_mart
//

import Foundation

/// Native app uses prefix **`/mapi`** on `homeMartBaseURL` (HTTPS, no trailing slash on the base).
///
/// Base URL resolution (first match wins):
/// 1. Process environment `HOME_MART_BASE_URL` — e.g. **scheme “home_mart Local API”** or `xcodebuild` `HOME_MART_BASE_URL=…`.
/// 2. Info.plist `HOME_MART_BASE_URL` — from `Config/APIBase.xcconfig` at build time unless preprocessing is off.
/// 3. Default production host `https://homemart-mm.vercel.app`.
enum APIConfiguration {
    /// `true`: Simulator uses a local JSON mock at `http://127.0.0.1:8787` (no production TLS).
    static var useLocalMockAPI = false

    /// Override with:
    /// - Info.plist: `HOME_MART_BASE_URL` (e.g. `https://api.example.com` or `http://127.0.0.1:8000`)
    /// - Environment: `HOME_MART_BASE_URL` (useful for CI)
    static var homeMartBaseURL: URL {
        if let env = ProcessInfo.processInfo.environment["HOME_MART_BASE_URL"],
           let url = URL(string: env.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return url
        }

        if let raw = Bundle.main.object(forInfoDictionaryKey: "HOME_MART_BASE_URL") as? String,
           let url = URL(string: raw.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return url
        }

        return URL(string: "https://homemart-mm.vercel.app")!
    }
    private static let localMockRoot = URL(string: "http://127.0.0.1:8787")!

    private static var apiRoot: URL {
        useLocalMockAPI ? localMockRoot : homeMartBaseURL
    }

    // MARK: - Listings (`GET /mapi/listings`, `GET /mapi/listings/{id}`)

    static var listingsURL: URL {
        apiRoot.appending(path: "mapi/listings")
    }

    static var listingCandidateURLs: [URL] {
        [listingsURL]
    }

    /// Detail: `GET /mapi/listings/{id}` (send `Authorization: Bearer` when required).
    static func listingDetailURL(id: String) -> URL {
        apiRoot.appending(path: "mapi/listings/\(id)")
    }

    // MARK: - Register (`POST /mapi/register`)

    static var registerURL: URL {
        apiRoot.appending(path: "mapi/register")
    }

    // MARK: - Session (`GET /mapi/user`)

    static var currentUserURL: URL {
        apiRoot.appending(path: "mapi/user")
    }

    /// Password change candidates — tried in order until one responds with something other than **404** / **405** (see `AuthStore.updatePassword`).
    static var passwordUpdateCandidateURLs: [URL] {
        [
            apiRoot.appending(path: "mapi/user/password"),
            apiRoot.appending(path: "api/user/password"),
            apiRoot.appending(path: "mapi/password"),
        ]
    }

    /// First password-update URL (convenience for docs / tests).
    static var userPasswordURL: URL {
        passwordUpdateCandidateURLs[0]
    }

    // MARK: - Categories (production: `GET /mapi/categories` — JSON, no CSRF)

    /// Production serves categories under `/mapi` (plain `/api/categories` may be absent).
    static var categoryCandidateURLs: [URL] {
        [apiRoot.appending(path: "mapi/categories")]
    }

    /// Convenience single URL (first candidate).
    static var categoriesURL: URL {
        categoryCandidateURLs[0]
    }

    // MARK: - Login (`POST /mapi/login`, JSON body — `/api/login` is web CSRF 419)

    static var loginCandidateURLs: [URL] {
        [apiRoot.appending(path: "mapi/login")]
    }

    static var loginURL: URL {
        loginCandidateURLs[0]
    }
}
