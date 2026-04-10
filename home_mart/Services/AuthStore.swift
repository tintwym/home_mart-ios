//
//  AuthStore.swift
//  home_mart
//

import Foundation
import Observation

private let legacyAuthTokenUserDefaultsKey = "home_mart.authToken"

/// POST JSON to `POST /mapi/login` with `Content-Type` + `Accept: application/json`.
@MainActor
@Observable
final class AuthStore {
    static let shared = AuthStore()

    private(set) var authToken: String?
    private(set) var lastError: String?
    /// Cached `GET /mapi/user` payload for UI (e.g. Me tab greeting). Cleared on logout.
    private(set) var currentUser: LoginUserPayload?

    private init() {
        if let keychain = AuthTokenStorage.read() {
            authToken = keychain
        } else if let legacy = UserDefaults.standard.string(forKey: legacyAuthTokenUserDefaultsKey) {
            authToken = legacy
            AuthTokenStorage.write(legacy)
            UserDefaults.standard.removeObject(forKey: legacyAuthTokenUserDefaultsKey)
        }
        if authToken != nil {
            Task { @MainActor in
                await AuthStore.shared.refreshCurrentUser()
            }
        }
    }

    func logout() {
        authToken = nil
        currentUser = nil
        AuthTokenStorage.delete()
        UserDefaults.standard.removeObject(forKey: legacyAuthTokenUserDefaultsKey)
        lastError = nil
        BiometricAuthSettingsStore.shared.invalidateForegroundBiometricSatisfaction()
    }

    /// Refreshes `currentUser` from the API. No-op when logged out.
    func refreshCurrentUser() async {
        guard authToken != nil else {
            currentUser = nil
            return
        }
        currentUser = await fetchCurrentUser()
    }

    private func persistToken(_ token: String) {
        authToken = token
        AuthTokenStorage.write(token)
    }

    /// Returns `true` when a token was stored.
    func login(email: String, password: String) async -> Bool {
        lastError = nil
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            lastError = "Enter email and password."
            return false
        }

        let payload: [String: String] = [
            "email": trimmedEmail,
            "password": password,
        ]
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else {
            lastError = "Could not build request."
            return false
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 20
        let session = URLSession(configuration: configuration)

        for url in APIConfiguration.loginCandidateURLs {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.httpBody = body

            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else { continue }

                if (200 ... 299).contains(http.statusCode) {
                    if let token = Self.decodeAuthToken(from: data), !token.isEmpty {
                        persistToken(token)
                        await refreshCurrentUser()
                        return true
                    }
                    lastError = "Server did not return a token."
                    continue
                }

                // Wrong route (404), CSRF on web stack (419), etc. — try next candidate URL.
                if Self.shouldRetryLogin(after: http.statusCode) {
                    lastError = Self.apiErrorMessage(
                        data: data,
                        statusCode: http.statusCode,
                        fallback: "Login failed (\(http.statusCode))."
                    )
                    continue
                }

                lastError = Self.apiErrorMessage(data: data, statusCode: http.statusCode, fallback: "Login failed (\(http.statusCode)).")
                return false
            } catch {
                lastError = Self.humanizedRequestError(error)
                continue
            }
        }

        lastError = lastError ?? "Could not reach the server."
        return false
    }

    /// `POST /mapi/register` — Laravel-style body; stores token on success like login.
    func register(name: String, email: String, password: String, passwordConfirmation: String) async -> Bool {
        lastError = nil
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedEmail.isEmpty, !password.isEmpty else {
            lastError = "Fill in all fields."
            return false
        }
        guard password == passwordConfirmation else {
            lastError = "Passwords do not match."
            return false
        }
        guard password.count >= 8 else {
            lastError = "Password must be at least 8 characters."
            return false
        }

        let payload: [String: String] = [
            "name": trimmedName,
            "email": trimmedEmail,
            "password": password,
            "password_confirmation": passwordConfirmation,
        ]
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else {
            lastError = "Could not build request."
            return false
        }

        var request = URLRequest(url: APIConfiguration.registerURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = body

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 20
        let session = URLSession(configuration: configuration)

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                lastError = "Invalid response."
                return false
            }
            guard (200 ... 299).contains(http.statusCode) else {
                lastError = Self.apiErrorMessage(data: data, statusCode: http.statusCode, fallback: "Registration failed (\(http.statusCode)).")
                return false
            }
            if let token = Self.decodeAuthToken(from: data), !token.isEmpty {
                persistToken(token)
                await refreshCurrentUser()
                return true
            }
            lastError = "Account created but no token was returned. Try logging in."
            return false
        } catch {
            lastError = Self.humanizedRequestError(error)
            return false
        }
    }

    /// Updates password via Laravel-style JSON (`current_password`, `password`, `password_confirmation`) and Bearer token.
    /// Tries each URL in `APIConfiguration.passwordUpdateCandidateURLs` and, per URL, `PUT` then `POST` then `PATCH` until one succeeds.
    func updatePassword(currentPassword: String, newPassword: String, passwordConfirmation: String) async -> Bool {
        lastError = nil
        guard !currentPassword.isEmpty else {
            lastError = "Enter your current password."
            return false
        }
        guard !newPassword.isEmpty else {
            lastError = "Enter a new password."
            return false
        }
        guard newPassword == passwordConfirmation else {
            lastError = "New password and confirmation do not match."
            return false
        }
        guard newPassword.count >= 8 else {
            lastError = "New password must be at least 8 characters."
            return false
        }
        guard newPassword != currentPassword else {
            lastError = "Choose a password that’s different from your current one."
            return false
        }
        guard let token = authToken, !token.isEmpty else {
            lastError = "You’re not signed in."
            return false
        }

        let payload: [String: String] = [
            "current_password": currentPassword,
            "password": newPassword,
            "password_confirmation": passwordConfirmation,
        ]
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else {
            lastError = "Could not build request."
            return false
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 25
        let session = URLSession(configuration: configuration)

        let urls = APIConfiguration.passwordUpdateCandidateURLs
        let methods = ["PUT", "POST", "PATCH"]
        var last404Message: String?

        urlLoop: for url in urls {
            for method in methods {
                var request = URLRequest(url: url)
                request.httpMethod = method
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.httpBody = body

                do {
                    let (data, response) = try await session.data(for: request)
                    guard let http = response as? HTTPURLResponse else {
                        lastError = "Invalid response."
                        return false
                    }

                    if (200 ... 299).contains(http.statusCode) {
                        lastError = nil
                        return true
                    }
                    if http.statusCode == 405 {
                        continue
                    }
                    if http.statusCode == 404 {
                        last404Message = Self.apiErrorMessage(
                            data: data,
                            statusCode: 404,
                            fallback: "Not found."
                        )
                        continue urlLoop
                    }
                    lastError = Self.apiErrorMessage(
                        data: data,
                        statusCode: http.statusCode,
                        fallback: "Could not update password (\(http.statusCode))."
                    )
                    return false
                } catch {
                    lastError = Self.humanizedRequestError(error)
                    return false
                }
            }
        }

        if let msg = last404Message {
            lastError = msg + " The server may not expose password update yet — add a Sanctum/API route (e.g. PUT mapi/user/password) that accepts JSON and Bearer auth."
        } else {
            lastError = lastError ?? "Could not update password."
        }
        return false
    }

    /// `GET /mapi/user` — requires `Authorization: Bearer` (same token as login).
    func fetchCurrentUser() async -> LoginUserPayload? {
        guard let token = authToken, !token.isEmpty else { return nil }
        var request = URLRequest(url: APIConfiguration.currentUserURL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        let session = URLSession(configuration: configuration)

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else { return nil }
            return Self.decodeCurrentUser(from: data)
        } catch {
            return nil
        }
    }

    /// Supports bare `{ "id", "name", "email" }` or `{ "user": { ... } }` / `{ "data": { ... } }`.
    private static func decodeCurrentUser(from data: Data) -> LoginUserPayload? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        if let u = try? decoder.decode(LoginUserPayload.self, from: data) { return u }
        struct Wrap: Decodable {
            var user: LoginUserPayload?
            var data: LoginUserPayload?
        }
        if let w = try? decoder.decode(Wrap.self, from: data) {
            return w.user ?? w.data
        }
        return nil
    }

    /// Extracts Sanctum token without decoding `user` (avoids ULID / nested user decode failures).
    private static func decodeAuthToken(from data: Data) -> String? {
        guard !data.isEmpty else { return nil }
        guard let any = try? JSONSerialization.jsonObject(with: data) else { return nil }
        if let s = any as? String, !s.isEmpty { return s }
        return extractToken(from: any, depth: 0)
    }

    private static func extractToken(from any: Any, depth: Int) -> String? {
        guard depth < 8 else { return nil }

        if let dict = any as? [String: Any] {
            let keyCandidates = [
                "token", "access_token", "auth_token", "plain_text_token", "plainTextToken", "accessToken",
            ]
            for key in keyCandidates {
                if let s = dict[key] as? String, !s.isEmpty { return s }
            }
            for key in keyCandidates {
                if let n = dict[key] as? Int { return String(n) }
            }
            for wrap in ["data", "attributes", "result"] {
                if let inner = dict[wrap] {
                    if let t = extractToken(from: inner, depth: depth + 1) { return t }
                }
            }
        }

        if let arr = any as? [Any] {
            for item in arr {
                if let t = extractToken(from: item, depth: depth + 1) { return t }
            }
        }

        return nil
    }

    private static func apiErrorMessage(data: Data, statusCode: Int, fallback: String) -> String {
        if let msg = laravelMessageFromJSONData(data) { return msg }
        if let v = try? JSONDecoder().decode(LaravelValidationBody.self, from: data) {
            if let first = v.errors?.values.flatMap(\.self).first { return first }
            if let m = v.message, !m.isEmpty { return m }
        }
        if let err = try? JSONDecoder().decode(LaravelErrorBody.self, from: data) {
            return err.message ?? err.error ?? fallback
        }
        if let raw = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty {
            if raw.hasPrefix("<") {
                return "\(fallback) The server returned HTML instead of JSON (status \(statusCode)) — check `/mapi/login` or the API base URL."
            }
            let snippet = raw.count > 280 ? String(raw.prefix(280)) + "…" : raw
            if statusCode >= 500 {
                return "Server error (\(statusCode)): \(snippet)"
            }
            return "\(fallback) \(snippet)"
        }
        return fallback
    }

    /// Reads Laravel `message` / `errors` without strict Codable (mixed error value types).
    private static func laravelMessageFromJSONData(_ data: Data) -> String? {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        if let m = obj["message"] as? String, !m.isEmpty { return m }
        if let errors = obj["errors"] as? [String: Any] {
            for (_, v) in errors {
                if let arr = v as? [String], let first = arr.first { return first }
                if let s = v as? String { return s }
            }
        }
        return nil
    }

    private static func humanizedRequestError(_ error: Error) -> String {
        if error is DecodingError {
            return "Could not read the server response. If login still fails after updating the app, contact support."
        }
        return error.localizedDescription
    }

    /// Transient / alternate-route failures — retry next candidate URL. Do **not** include 5xx here:
    /// with a single URL, retry would hide the real server error behind “Could not reach the server.”
    private static func shouldRetryLogin(after statusCode: Int) -> Bool {
        switch statusCode {
        case 404, 405, 408, 409, 419, 425, 429:
            return true
        default:
            return false
        }
    }
}

struct LoginUserPayload: Decodable {
    let id: String?
    let name: String?
    let email: String?
    let phone: String?
    let address: String?
    let region: String?

    enum CodingKeys: String, CodingKey {
        case id, name, email, phone, address, region
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        email = try c.decodeIfPresent(String.self, forKey: .email)
        phone = try c.decodeIfPresent(String.self, forKey: .phone)
        address = try c.decodeIfPresent(String.self, forKey: .address)
        region = try c.decodeIfPresent(String.self, forKey: .region)
        if let i = try? c.decode(Int.self, forKey: .id) {
            id = String(i)
        } else if let s = try? c.decode(String.self, forKey: .id) {
            id = s
        } else {
            id = nil
        }
    }
}

private struct LaravelErrorBody: Decodable {
    let message: String?
    let error: String?
}

private struct LaravelValidationBody: Decodable {
    let message: String?
    let errors: [String: [String]]?
}
