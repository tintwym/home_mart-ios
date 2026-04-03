//
//  TwoFactorAuthView.swift
//  home_mart
//

import LocalAuthentication
import SwiftUI

struct TwoFactorAuthView: View {
    private let store = BiometricAuthSettingsStore.shared

    private let primaryText = Color(red: 0.1, green: 0.11, blue: 0.12)
    private let muted = Color(red: 0.35, green: 0.38, blue: 0.42)

    @State private var biometricKind = DeviceBiometricKind.evaluate()
    @State private var authInProgress = false
    @State private var alertMessage: String?

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add an extra step when you sign in or take sensitive actions on this device.")
                        .font(.subheadline)
                        .foregroundStyle(muted)
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            }

            Section {
                HStack(spacing: 14) {
                    Image(systemName: biometricKind.systemImageName)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(biometricKind.isAvailable ? .primary : .secondary)
                        .frame(width: 40, alignment: .center)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(biometricKind.displayName)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(primaryText)
                        if case let .unavailable(reason) = biometricKind {
                            Text(reason)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Confirm it’s you with \(biometricKind.displayName) on this iPhone.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)

                if biometricKind.isAvailable {
                    Toggle(
                        isOn: Binding(
                            get: { store.isBiometricSecondFactorEnabled },
                            set: { newValue in
                                if newValue {
                                    Task { await enableBiometric() }
                                } else {
                                    store.setBiometricSecondFactorEnabled(false)
                                }
                            }
                        )
                    ) {
                        Text("Use \(biometricKind.displayName) as second factor")
                            .font(.body)
                    }
                    .disabled(authInProgress)
                }
            } header: {
                Text("On this device")
            } footer: {
                Text("When enabled, the app can ask for \(biometricKind.displayName) before certain actions. This stays on your device until you turn it off.")
            }

            Section {
                Text("Authenticator apps and SMS codes can be added here when your account backend supports them.")
                    .font(.subheadline)
                    .foregroundStyle(muted)
            } header: {
                Text("Other methods")
            }
        }
        .navigationTitle("Two-Factor Auth")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { biometricKind = DeviceBiometricKind.evaluate() }
        .alert("Couldn’t verify", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private func enableBiometric() async {
        authInProgress = true
        defer { authInProgress = false }
        do {
            try await BiometricAuthSettingsStore.evaluateBiometric(
                localizedReason: "Enable \(biometricKind.displayName) as a second factor for Home Mart on this device."
            )
            store.setBiometricSecondFactorEnabled(true)
        } catch {
            let laError = error as? LAError
            if laError?.code == .userCancel || laError?.code == .userFallback || laError?.code == .systemCancel {
                return
            }
            alertMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        TwoFactorAuthView()
    }
}
