//
//  ProfileAccountOptionsView.swift
//  home_mart
//

import SwiftUI

/// Account rows shown **directly on Me** (no extra Profile tap).
struct ProfileAccountOptionsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            accountRows

            Text("Orders")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
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
            ("Settings", "gearshape.fill", "Settings"),
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
                    } else if row.0 == "Settings" {
                        NavigationLink {
                            SettingsView()
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
                        .background(Color(.separator))
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
                    .fill(Color(.secondarySystemGroupedBackground))
                    .frame(width: 40, height: 40)
                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
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

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImage)
                .font(.system(size: 52, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)

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
