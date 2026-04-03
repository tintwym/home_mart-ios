//
//  ProfileAccountOptionsView.swift
//  home_mart
//

import SwiftUI

/// Account rows shown **directly on Me** (no extra Profile tap).
struct ProfileAccountOptionsView: View {
    private let primaryText = Color(red: 0.1, green: 0.11, blue: 0.12)
    private let iconTileFill = Color(red: 0.95, green: 0.96, blue: 0.97)
    private let sectionHeader = Color(red: 0.35, green: 0.38, blue: 0.42)
    private let chevronColor = Color(red: 0.78, green: 0.8, blue: 0.84)
    private let rowDivider = Color(red: 0.9, green: 0.91, blue: 0.93)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            accountRows

            Text("Orders")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(sectionHeader)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            NavigationLink {
                SettingsStubDetailView(title: "My Orders", systemImage: "shippingbox.fill")
            } label: {
                settingsRow(title: "My Orders", systemImage: "shippingbox.fill")
            }
            .buttonStyle(.plain)
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var accountRows: some View {
        let rows: [(String, String, String)] = [
            ("Password", "key.fill", "Password"),
            ("Payment method", "creditcard.fill", "Payment method"),
            ("Two-Factor Auth", "shield.fill", "Two-Factor Auth"),
        ]
        return VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                Group {
                    if row.0 == "Password" {
                        NavigationLink {
                            UpdatePasswordView()
                        } label: {
                            settingsRow(title: row.0, systemImage: row.1)
                        }
                    } else if row.0 == "Two-Factor Auth" {
                        NavigationLink {
                            TwoFactorAuthView()
                        } label: {
                            settingsRow(title: row.0, systemImage: row.1)
                        }
                    } else {
                        NavigationLink {
                            SettingsStubDetailView(title: row.2, systemImage: row.1)
                        } label: {
                            settingsRow(title: row.0, systemImage: row.1)
                        }
                    }
                }
                .buttonStyle(.plain)

                if index < rows.count - 1 {
                    Divider()
                        .background(rowDivider)
                        .padding(.leading, 70)
                }
            }
        }
        .padding(.bottom, 4)
    }

    private func settingsRow(title: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconTileFill)
                    .frame(width: 40, height: 40)
                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(primaryText.opacity(0.85))
            }
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(primaryText)
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(chevronColor)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}

private struct SettingsStubDetailView: View {
    let title: String
    /// Matches the list row (not the old generic `hammer.fill` placeholder).
    let systemImage: String

    private let primaryText = Color(red: 0.1, green: 0.11, blue: 0.12)

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImage)
                .font(.system(size: 52, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(primaryText)

            Text("This section will connect to your account soon.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            ProfileAccountOptionsView()
                .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
