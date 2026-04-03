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
        VStack(spacing: 0) {
            Group {
                switch selectedTab {
                case .home:
                    DashboardHomeView()
                case .wishlist:
                    WishlistTabView()
                case .sell:
                    SellTabView(selectedTab: $selectedTab)
                case .notifications:
                    NotificationsTabView()
                case .profile:
                    ProfileTabView(selectedTab: $selectedTab)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if showsBottomTabBar {
                MainTabBar(selection: $selectedTab)
            }
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Custom tab bar (reference: gray bar, blue selection, red Sell)

private struct MainTabBar: View {
    @Binding var selection: AppMainTab

    private let barBackground = Color(red: 0.96, green: 0.96, blue: 0.97)
    /// Same height for every tab’s icon row so captions line up (Sell’s red tile is 40×40; SF Symbols sit centered in the same slot).
    private let tabIconSlotHeight: CGFloat = 40

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.45)

            HStack(spacing: 0) {
                tabButton(.home, title: "Explore", systemImage: "magnifyingglass")
                tabButton(.wishlist, title: "Wishlist", systemImage: "heart")
                sellButton
                tabButton(.notifications, title: "Updates", systemImage: "bell")
                tabButton(.profile, title: "Me", systemImage: "person")
            }
            .padding(.top, 8)
            .padding(.bottom, 6)
            .padding(.bottom, 4)
            .background(
                barBackground
                    .ignoresSafeArea(edges: .bottom)
            )
        }
    }

    private func tabButton(_ tab: AppMainTab, title: String, systemImage: String) -> some View {
        Button {
            selection = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .regular))
                    .symbolVariant(selection == tab ? .fill : .none)
                    .frame(height: tabIconSlotHeight)
                    .frame(maxWidth: .infinity)
                Text(title)
                    .font(.caption2)
                    .fontWeight(selection == tab ? .semibold : .regular)
            }
            .foregroundStyle(selection == tab ? Color.blue : Color.secondary)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var sellButton: some View {
        Button {
            selection = .sell
        } label: {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.red)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .frame(height: tabIconSlotHeight)
                    .frame(maxWidth: .infinity)
                Text("Sell")
                    .font(.caption2)
                    .fontWeight(selection == .sell ? .semibold : .medium)
                    .foregroundStyle(selection == .sell ? Color.blue : Color.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Sell, add item")
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

    /// Keep token check in one place so login/sign-up children are not rebuilt around unrelated `AuthStore` updates.
    private var needsAuthGate: Bool {
        auth.authToken == nil
    }

    /// Shown under the avatar: **name** from `/mapi/user` only (hidden until loaded or if absent).
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

/// Guest UI only — does not observe `AuthStore`, so text field state isn’t fighting observation redraws.
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
