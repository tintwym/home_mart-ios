//
//  AuthInputChrome.swift
//  home_mart
//

import SwiftUI

/// Shared look for log-in / sign-up text fields (aligned with profile form fields).
struct AuthInputChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color(.separator), lineWidth: 1)
                    )
            )
    }
}

extension View {
    func authInputChrome() -> some View {
        modifier(AuthInputChrome())
    }
}
