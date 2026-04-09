//
//  MainTabShellView.swift
//  home_mart
//

import Observation
import SwiftUI

enum AppMainTab: Int, CaseIterable, Hashable {
    case home
    case wishlist
    case sell
    case notifications
    case profile
}

struct MainTabShellView: View {
    @State private var selectedTab: AppMainTab = .home
    @Bindable private var auth = AuthStore.shared

    /// Hide the bottom tab bar on Me while logged out (full-screen login / register).
    private var showsBottomTabBar: Bool {
        !(selectedTab == .profile && auth.authToken == nil)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    DashboardHomeView(onSelectTab: { selectedTab = $0 })
                case .wishlist:
                    WishlistTabView()
                case .sell:
                    SellTabView(selectedTab: $selectedTab)
                case .notifications:
                    NavigationStack {
                        MessagesListView()
                    }
                case .profile:
                    ProfileTabView(selectedTab: $selectedTab)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Reserve space so content never hides behind the floating bar.
            .safeAreaInset(edge: .bottom) {
                if showsBottomTabBar { Color.clear.frame(height: 90) }
            }

            if showsBottomTabBar {
                MainTabBar(selection: $selectedTab)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 24)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .background(Color(.systemBackground))
    }
}

// MARK: - Floating pill tab bar (iOS 26 liquid-glass style)

private struct MainTabBar: View {
    @Binding var selection: AppMainTab
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            tabButton(.home,          title: "Explore",  systemImage: "magnifyingglass")
            tabButton(.wishlist,      title: "Wishlist", systemImage: "heart")
            sellButton
            tabButton(.notifications, title: "Messages", systemImage: "bubble.left")
            tabButton(.profile,       title: "Me",       systemImage: "person")
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .background(pillBackground)
    }

    // MARK: Glass pill shell

    private var pillBackground: some View {
        let shape = Capsule(style: .continuous)
        return ZStack {
            GlassBlur(style: colorScheme == .dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight)
                .clipShape(shape)

            // Milk layer: lighter in light mode, darker in dark mode.
            shape.fill(colorScheme == .dark ? Color.black.opacity(0.35) : Color.white.opacity(0.60))

            // Specular highlight along the top edge.
            LinearGradient(
                colors: [Color.white.opacity(colorScheme == .dark ? 0.18 : 0.55), Color.clear],
                startPoint: .top,
                endPoint: .center
            )
            .clipShape(shape)

            shape.strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.22 : 0.72), lineWidth: 1)
            shape.strokeBorder(Color(.separator).opacity(colorScheme == .dark ? 0.18 : 0.12), lineWidth: 0.5)
        }
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.12), radius: 24, x: 0, y: 10)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.18 : 0.06), radius: 6,  x: 0, y: 2)
    }

    // MARK: Regular tab item

    private func tabButton(_ tab: AppMainTab, title: String, systemImage: String) -> some View {
        let isSelected = selection == tab
        return Button {
            selection = tab
        } label: {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .symbolVariant(isSelected ? .fill : .none)
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
            }
            .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.82))
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.18 : 0.08), radius: 6, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 3)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isSelected)
    }

    // MARK: Sell tab (red rounded-rect icon)

    private var sellButton: some View {
        let isSelected = selection == .sell
        return Button {
            selection = .sell
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.red)
                        .frame(width: 36, height: 36)
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }
                Text("Sell")
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.82))
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.18 : 0.08), radius: 6, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Sell, add item")
        .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isSelected)
    }
}

// MARK: - Tab roots

struct WishlistTabView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Wishlist",
                systemImage: "heart",
                description: Text("Items you save will show up here.")
            )
            .navigationTitle("Wishlist")
        }
    }
}

struct SellTabView: View {
    @Binding var selectedTab: AppMainTab
    @Bindable private var auth = AuthStore.shared

    var body: some View {
        NavigationStack {
            Group {
                if auth.authToken == nil {
                    sellGuestContent
                } else {
                    sellSignedInContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .navigationTitle("Sell")
        }
    }

    private var sellGuestContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "plus.square.dashed")
                .font(.system(size: 52))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
            Text("Sign in to sell")
                .font(.title2.weight(.semibold))
            Text("Add furniture and more. The red plus in the middle of the tab bar opens this screen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button {
                selectedTab = .profile
            } label: {
                Text("Sign in")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)
            .padding(.top, 8)
            Spacer()
        }
        .padding(.top, 40)
    }

    private var sellSignedInContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "tag.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(.red.opacity(0.85))
                .accessibilityHidden(true)
            Text("List something for sale")
                .font(.title2.weight(.semibold))
            Text("Create a listing with title, price, and description.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            NavigationLink {
                CreateListingView()
            } label: {
                Label("Add item", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .padding(.horizontal, 32)
            .padding(.top, 4)
            Spacer()
        }
        .padding(.top, 40)
    }
}

struct NotificationsTabView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No notifications",
                systemImage: "bell",
                description: Text("Alerts about orders and messages will appear here.")
            )
            .navigationTitle("Updates")
        }
    }
}

struct ProfileTabView: View {
    @Binding var selectedTab: AppMainTab
    @Bindable private var auth = AuthStore.shared
    @Bindable private var profileAvatar = ProfileAvatarStore.shared
    @State private var isShowingSignUp = false

    var body: some View {
        NavigationStack {
            Group {
                if needsAuthGate {
                    ProfileGuestShell(selectedTab: $selectedTab, isShowingSignUp: $isShowingSignUp)
                } else {
                    loggedInContent
                }
            }
            .navigationTitle(auth.authToken != nil ? "Me" : "")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task(id: auth.authToken) {
            await auth.refreshCurrentUser()
        }
    }

    private var needsAuthGate: Bool {
        auth.authToken == nil
    }

    private var meDisplayName: String {
        auth.currentUser?.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    @MainActor
    private var loggedInContent: some View {
        let avatarImage = profileAvatar.uiImage
        return ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    NavigationLink {
                        PersonalDetailsFormView()
                    } label: {
                        ZStack(alignment: .bottomTrailing) {
                            Group {
                                if let img = avatarImage {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 72, height: 72)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.crop.circle.fill")
                                        .font(.system(size: 72))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 28))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, Color(red: 0.23, green: 0.51, blue: 0.96))
                                .background(
                                    Circle()
                                        .fill(Color(.systemGroupedBackground))
                                        .frame(width: 26, height: 26)
                                )
                                .offset(x: 4, y: 4)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Edit profile photo and personal details")

                    if !meDisplayName.isEmpty {
                        Text(meDisplayName)
                            .font(.title2.weight(.semibold))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 20)

                ProfileAccountOptionsView()
                    .padding(.horizontal, 20)

                Button("Log out", role: .destructive) {
                    auth.logout()
                }
                .buttonStyle(.bordered)
                .padding(.top, 28)
                .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
    }
}

/// Guest UI only — does not observe `AuthStore`, so text field state isn't fighting observation redraws.
private struct ProfileGuestShell: View {
    @Binding var selectedTab: AppMainTab
    @Binding var isShowingSignUp: Bool

    var body: some View {
        Group {
            if isShowingSignUp {
                SignUpView(isShowingSignUp: $isShowingSignUp)
            } else {
                LogInView(isShowingSignUp: $isShowingSignUp)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    selectedTab = .home
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                }
                .accessibilityLabel("Close")
            }
        }
    }
}

#Preview {
    MainTabShellView()
}
