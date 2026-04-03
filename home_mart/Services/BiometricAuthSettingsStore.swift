//
//  BiometricAuthSettingsStore.swift
//  home_mart
//

import Foundation
import LocalAuthentication

enum DeviceBiometricKind: Equatable {
    case faceID
    case touchID
    case opticID
    case unavailable(reason: String)

    static func evaluate() -> DeviceBiometricKind {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            let message = error?.localizedDescription ?? "Biometrics are not available on this device."
            return .unavailable(reason: message)
        }
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        case .opticID: return .opticID
        case .none:
            return .unavailable(reason: "Biometrics are not set up on this device.")
        @unknown default:
            return .unavailable(reason: "This biometric type is not supported.")
        }
    }

    var displayName: String {
        switch self {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        case .unavailable: return "Biometrics"
        }
    }

    var systemImageName: String {
        switch self {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        case .unavailable: return "lock.slash"
        }
    }

    var isAvailable: Bool {
        switch self {
        case .unavailable: return false
        default: return true
        }
    }
}

@MainActor
@Observable
final class BiometricAuthSettingsStore {
    static let shared = BiometricAuthSettingsStore()

    private let defaultsKey = "home_mart.biometric2FA.enabled"

    private(set) var isBiometricSecondFactorEnabled: Bool

    private init() {
        isBiometricSecondFactorEnabled = UserDefaults.standard.bool(forKey: defaultsKey)
    }

    func setBiometricSecondFactorEnabled(_ enabled: Bool) {
        isBiometricSecondFactorEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: defaultsKey)
    }

    /// Prompts the user with Face ID / Touch ID when biometric second factor is enabled. No-op if disabled.
    func requireBiometricIfEnabled(localizedReason: String) async throws {
        guard isBiometricSecondFactorEnabled else { return }
        try await Self.evaluateBiometric(localizedReason: localizedReason)
    }

    static func evaluateBiometric(localizedReason: String) async throws {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw error.map { $0 as Error } ?? LAError(.biometryNotAvailable)
        }
        let ok = try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: localizedReason
        )
        if !ok { throw LAError(.authenticationFailed) }
    }
}
