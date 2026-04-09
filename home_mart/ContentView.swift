//
//  ContentView.swift
//  home_mart
//
//  Created by Tint Wai Yan Min on 29/3/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("home_mart.appearance") private var appearanceRaw: String = AppAppearance.system.rawValue

    private var appearance: AppAppearance {
        AppAppearance(rawValue: appearanceRaw) ?? .system
    }

    var body: some View {
        MainTabShellView()
            .preferredColorScheme(appearance.preferredColorScheme)
    }
}

#Preview {
    ContentView()
}
