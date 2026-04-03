//
//  CreateListingView.swift
//  home_mart
//

import SwiftUI

/// POST JSON to `mapi/listings` with Bearer token. Backend must allow `POST` on that route.
struct CreateListingView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var titleText = ""
    @State private var descriptionText = ""
    @State private var priceText = ""
    @State private var categoryIdText = ""
    @State private var isSubmitting = false
    @State private var errorAlert: String?
    @State private var showSuccessAlert = false

    var body: some View {
        Form {
            Section {
                TextField("Title", text: $titleText)
                TextField("Price (USD)", text: $priceText)
                    .keyboardType(.decimalPad)
                TextField("Category ID (optional)", text: $categoryIdText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            Section("Description") {
                TextField("Describe your item", text: $descriptionText, axis: .vertical)
                    .lineLimit(3 ... 8)
            }
            Section {
                Button {
                    Task { await submit() }
                } label: {
                    if isSubmitting {
                        HStack {
                            ProgressView()
                            Text("Publishing…")
                        }
                    } else {
                        Text("Publish listing")
                    }
                }
                .disabled(isSubmitting || titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle("Add item")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Could not publish", isPresented: Binding(
            get: { errorAlert != nil },
            set: { if !$0 { errorAlert = nil } }
        )) {
            Button("OK", role: .cancel) { errorAlert = nil }
        } message: {
            Text(errorAlert ?? "")
        }
        .alert("Listed", isPresented: $showSuccessAlert) {
            Button("OK") {
                showSuccessAlert = false
                dismiss()
            }
        } message: {
            Text("Your item was published. Pull to refresh on Explore to see it in the feed.")
        }
    }

    @MainActor
    private func submit() async {
        let title = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        guard let token = AuthStore.shared.authToken, !token.isEmpty else {
            errorAlert = "You are not signed in."
            return
        }

        let priceTrim = priceText.trimmingCharacters(in: .whitespacesAndNewlines)
        let priceValue: Double? = priceTrim.isEmpty ? nil : Double(priceTrim)

        var payload: [String: Any] = [
            "title": title,
            "description": descriptionText.trimmingCharacters(in: .whitespacesAndNewlines),
        ]
        if let p = priceValue {
            payload["price"] = p
        }
        let cat = categoryIdText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cat.isEmpty {
            payload["category_id"] = cat
        }

        guard let body = try? JSONSerialization.data(withJSONObject: payload) else {
            errorAlert = "Could not build request."
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        var request = URLRequest(url: APIConfiguration.listingsURL)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 30
        let session = URLSession(configuration: configuration)

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                errorAlert = "Invalid response."
                return
            }
            if (200 ... 299).contains(http.statusCode) {
                showSuccessAlert = true
                return
            }
            if http.statusCode == 405 {
                errorAlert =
                    "The server does not allow creating listings on this URL yet (method not allowed). Your Laravel API needs a POST route for /mapi/listings."
                return
            }
            errorAlert = Self.messageFromAPI(data: data, status: http.statusCode, fallback: "Request failed (\(http.statusCode)).")
        } catch {
            errorAlert = error.localizedDescription
        }
    }

    private static func messageFromAPI(data: Data, status: Int, fallback: String) -> String {
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let errors = obj["errors"] as? [String: Any] {
                for (_, v) in errors {
                    if let arr = v as? [String], let first = arr.first { return first }
                    if let s = v as? String { return s }
                }
            }
            if let m = obj["message"] as? String, !m.isEmpty { return m }
        }
        if let raw = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty, raw.count < 400 {
            return "\(fallback) \(raw)"
        }
        return fallback
    }
}

#Preview {
    NavigationStack {
        CreateListingView()
    }
}
