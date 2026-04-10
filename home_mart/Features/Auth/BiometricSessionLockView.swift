//
//  BiometricSessionLockView.swift
//  home_mart
//

import LocalAuthentication
import Observation
import SwiftUI

/// Full-screen gate when the user is signed in, device two-factor (Face ID / Touch ID) is on, and the app needs a fresh biometric unlock.
struct BiometricSessionLockView: View {
    @Bindable private var auth = AuthStore.shared
    @Bindable private var biometricAuth = BiometricAuthSettingsStore.shared

    @State private var biometricKind = DeviceBiometricKind.evaluate()
    @State private var errorMessage: String?
    @State private var isPrompting = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: biometricKind.systemImageName)
                    .font(.system(size: 52, weight: .medium))
                    .foregroundStyle(.white)

                Text("Unlock Home Mart")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                Text(unlockSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                if let errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red.opacity(0.95))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Button {
                    Task { await runBiometricUnlock() }
                } label: {
                    Text(isPrompting ? "Checking…" : "Try again")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isPrompting)
                .padding(.horizontal, 32)
                .padding(.top, 8)

                Button("Sign out", role: .destructive) {
                    auth.logout()
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.top, 4)
            }
        }
        .onAppear { biometricKind = DeviceBiometricKind.evaluate() }
        .task {
            await runBiometricUnlock()
        }
    }

    private var unlockSubtitle: String {
        switch biometricKind {
        case .faceID:
            return "Use Face ID to finish signing in and use your account on this device."
        case .touchID:
            return "Use Touch ID to finish signing in and use your account on this device."
        case .opticID:
            return "Use Optic ID to finish signing in and use your account on this device."
        case let .unavailable(reason):
            return "Biometrics aren’t available (\(reason)). Sign out and turn off device two-factor in Settings, or try again."
        }
    }

    @MainActor
    private func runBiometricUnlock() async {
        guard biometricAuth.isBiometricSecondFactorEnabled, auth.authToken != nil else { return }
        isPrompting = true
        errorMessage = nil
        defer { isPrompting = false }

        do {
            let kind = DeviceBiometricKind.evaluate()
            biometricKind = kind
            let label = kind.displayName
            try await BiometricAuthSettingsStore.evaluateBiometric(
                localizedReason: "Unlock Home Mart with \(label)."
            )
            biometricAuth.markForegroundBiometricSatisfied()
        } catch {
            let la = error as? LAError
            if la?.code == .userCancel || la?.code == .userFallback || la?.code == .systemCancel {
                errorMessage = "Biometric check was canceled. Tap Try again or sign out."
                return
            }
            errorMessage = error.localizedDescription
        }
    }
}
