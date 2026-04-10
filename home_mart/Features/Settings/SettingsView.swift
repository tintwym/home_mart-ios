import SwiftUI

struct SettingsView: View {
    @AppStorage("home_mart.appearance") private var appearanceRaw: String = AppAppearance.system.rawValue

    var body: some View {
        Form {
            Section {
                Picker("Theme", selection: $appearanceRaw) {
                    ForEach(AppAppearance.allCases) { option in
                        Text(option.title).tag(option.rawValue)
                    }
                }
            } header: {
                Text("Appearance")
            } footer: {
                Text(appearanceFooter)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var appearanceFooter: String {
        switch AppAppearance(rawValue: appearanceRaw) ?? .system {
        case .system:
            return "Matches iPhone Settings → Display & Brightness. Sunrise/sunset switching uses Automatic there—not the clock inside this app."
        case .lightByDay:
            return "Uses your iPhone’s date and time: light from 6:00 AM to 7:59 PM local time, dark at night—even if the phone stays in Dark Mode."
        case .light, .dark:
            return "Always uses this appearance regardless of system settings."
        }
    }
}

