//
//  ContentView.swift
//  home_mart
//
//  Created by Tint Wai Yan Min on 29/3/26.
//

import Observation
import SwiftUI

struct ContentView: View {
    @AppStorage("home_mart.appearance") private var appearanceRaw: String = AppAppearance.system.rawValue
    @Environment(\.scenePhase) private var scenePhase
    @Bindable private var auth = AuthStore.shared
    @Bindable private var biometricAuth = BiometricAuthSettingsStore.shared

    private var appearance: AppAppearance {
        AppAppearance(rawValue: appearanceRaw) ?? .system
    }

    private var needsBiometricSessionUnlock: Bool {
        auth.authToken != nil
            && biometricAuth.isBiometricSecondFactorEnabled
            && !biometricAuth.isForegroundBiometricSatisfied
    }

    var body: some View {
        ZStack {
            MainTabShellView()

            if needsBiometricSessionUnlock {
                BiometricSessionLockView()
                    .transition(.opacity)
            }
        }
        .appPreferredColorScheme(appearance)
        .animation(.easeInOut(duration: 0.2), value: needsBiometricSessionUnlock)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                biometricAuth.invalidateForegroundBiometricSatisfaction()
            }
        }
    }
}

#Preview {
    ContentView()
}
