import Foundation
import SwiftUI

extension View {
    /// For **System**, does not apply `preferredColorScheme` so iOS Settings → Display truly drives light/dark.
    /// Using `.preferredColorScheme(nil)` after forcing light/dark can leave the hierarchy stuck and ignore system changes.
    @ViewBuilder
    func appPreferredColorScheme(_ appearance: AppAppearance) -> some View {
        switch appearance {
        case .system:
            self
        case .light:
            self.preferredColorScheme(.light)
        case .dark:
            self.preferredColorScheme(.dark)
        case .lightByDay:
            TimelineView(.periodic(from: .now, by: 30)) { context in
                self.preferredColorScheme(AppAppearance.preferredColorSchemeForLocalDaylight(at: context.date))
            }
        }
    }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    /// Follows iPhone **Settings → Display & Brightness** (Light / Dark / Automatic).
    case system
    /// Light during local daytime hours on the device clock, dark overnight (independent of system Dark Mode).
    case lightByDay
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .lightByDay: return "Light by day"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    /// Uses `Calendar.current` (device timezone). Light from 6:00 through 19:59 local; dark otherwise.
    static func preferredColorSchemeForLocalDaylight(at date: Date) -> ColorScheme {
        let hour = Calendar.current.component(.hour, from: date)
        return (hour >= 6 && hour < 20) ? .light : .dark
    }
}

