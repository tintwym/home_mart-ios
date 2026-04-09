//
//  DashboardHomeView.swift
//  home_mart
//

import SwiftUI

// MARK: - Filter chips (Carousell-style chrome)

private enum FilterChip: String, CaseIterable, Identifiable {
    case topPicks = "Top picks"
    case nearby = "Nearby"
    case freeItems = "Free items"
    case certified = "Certified"
    case following = "Following"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .topPicks: return "star.fill"
        case .nearby: return "mappin.and.ellipse"
        case .freeItems: return "dollarsign.circle.fill"
        case .certified: return "checkmark.seal.fill"
        case .following: return "heart.circle.fill"
        }
    }
}

// MARK: - Dashboard

/// Carousell-style home: categories from Laravel; “For you” shows all listings.
struct DashboardHomeView: View {
    var onSelectTab: ((AppMainTab) -> Void)? = nil
    @State private var searchText: String = ""
    @State private var store: ListingsStore
    @State private var categoriesStore: CategoriesStore
    /// `nil` = For you (all categories).
    @State private var selectedCategoryId: String?
    @State private var filterChip: FilterChip = .topPicks
    @State private var listingPath = NavigationPath()
    @State private var homeAlert: HomeAlert?

    private enum HomeRoute: Hashable {
        case checkout
        case updates
    }

    init(onSelectTab: ((AppMainTab) -> Void)? = nil) {
        self.onSelectTab = onSelectTab
        _store = State(initialValue: ListingsStore())
        _categoriesStore = State(initialValue: CategoriesStore())
    }

    init(store: ListingsStore, onSelectTab: ((AppMainTab) -> Void)? = nil) {
        self.onSelectTab = onSelectTab
        _store = State(initialValue: store)
        _categoriesStore = State(initialValue: CategoriesStore())
    }

    init(store: ListingsStore, categoriesStore: CategoriesStore, onSelectTab: ((AppMainTab) -> Void)? = nil) {
        self.onSelectTab = onSelectTab
        _store = State(initialValue: store)
        _categoriesStore = State(initialValue: categoriesStore)
    }

    private var searchFilteredListings: [Listing] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return store.listings }
        return store.listings.filter {
            $0.title.localizedCaseInsensitiveContains(q)
                || $0.category.localizedCaseInsensitiveContains(q)
        }
    }

    private var displayedListings: [Listing] {
        let base = searchFilteredListings
        guard let id = selectedCategoryId,
              let cat = categoriesStore.categories.first(where: { $0.id == id }) else { return base }
        return base.filter { cat.matchesListingCategory($0.category) }
    }

    private let forYouAccent = Color(red: 0.48, green: 0.35, blue: 0.89)

    var body: some View {
        NavigationStack(path: $listingPath) {
            VStack(spacing: 0) {
                carousellHeader

                Divider()
                    .opacity(0.35)

                sectionTabsRow
                    .padding(.vertical, 10)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        promoBanner
                            .padding(.horizontal, 12)

                        if !categoriesStore.categories.isEmpty {
                            categoryCirclesRow
                        }

                        filterChipsRow
                            .padding(.horizontal, 4)

                        if store.listings.isEmpty {
                            Text("No items yet.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                        } else if displayedListings.isEmpty {
                            Text("No matches.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                        } else {
                            LazyVGrid(
                                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                                spacing: 14
                            ) {
                                ForEach(displayedListings) { listing in
                                    ListingCardView(listing: listing) {
                                        listingPath.append(listing)
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.bottom, 8)
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
            .background(Color(.systemBackground))
            .refreshable {
                await store.refreshFromNetworkIfAvailable(force: true)
                await categoriesStore.refreshFromNetworkIfAvailable(force: true)
            }
            .task {
                await store.refreshFromNetworkIfAvailable()
                await categoriesStore.refreshFromNetworkIfAvailable()
            }
            .onChange(of: categoriesStore.categories) { _, newValue in
                if let id = selectedCategoryId, !newValue.contains(where: { $0.id == id }) {
                    selectedCategoryId = nil
                }
            }
            .navigationDestination(for: Listing.self) { listing in
                ListingDetailView(listing: listing)
            }
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .checkout:
                    CheckoutView()
                case .updates:
                    UpdatesView()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .alert(item: $homeAlert) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("OK")))
        }
    }

    // MARK: Header (search + camera, cart, chat)

    private var carousellHeader: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.tertiary)

                TextField("Search Home Mart", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.body)

                Button {
                    homeAlert = HomeAlert(title: "Camera", message: "Not wired up yet.")
                } label: {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(.systemGray6).opacity(0.65))
            )

            HStack(spacing: 6) {
                Button {
                    listingPath.append(HomeRoute.checkout)
                } label: {
                    Image(systemName: "cart")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(.primary)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)

                Button {
                    listingPath.append(HomeRoute.updates)
                } label: {
                    Image(systemName: "bell")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(.primary)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
    }

    private struct HomeAlert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    // MARK: Section tabs (For you + Laravel categories)

    private var sectionTabsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Button {
                    selectedCategoryId = nil
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bag.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("For you")
                            .font(.subheadline.weight(selectedCategoryId == nil ? .semibold : .regular))
                    }
                    .foregroundStyle(selectedCategoryId == nil ? forYouAccent : .secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(selectedCategoryId == nil ? Color(.systemBackground) : Color.clear)
                            .shadow(color: selectedCategoryId == nil ? .black.opacity(0.06) : .clear, radius: 4, y: 2)
                    )
                }
                .buttonStyle(.plain)

                ForEach(categoriesStore.categories) { cat in
                    Button {
                        selectedCategoryId = cat.id
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: cat.resolvedSystemImage())
                                .font(.system(size: 14, weight: .semibold))
                            Text(cat.name)
                                .font(.subheadline.weight(selectedCategoryId == cat.id ? .semibold : .regular))
                        }
                        .foregroundStyle(selectedCategoryId == cat.id ? cat.accentColor() : .secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedCategoryId == cat.id ? Color(.systemBackground) : Color.clear)
                                .shadow(color: selectedCategoryId == cat.id ? .black.opacity(0.06) : .clear, radius: 4, y: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
        }
        .background(Color(.systemGray6).opacity(0.35))
    }

    // MARK: Promo banner

    private var promoBanner: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.12, blue: 0.16),
                    Color(red: 0.22, green: 0.2, blue: 0.28),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                Text("Deals you’ll like")
                    .font(.headline)
                    .foregroundStyle(.white)
                Button {
                    homeAlert = HomeAlert(title: "Deals", message: "Not wired up yet.")
                } label: {
                    Text("Browse now!")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(Color.white, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
    }

    // MARK: Category circles

    private var categoryCirclesRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 18) {
                ForEach(categoriesStore.categories) { cat in
                    Button {
                        selectedCategoryId = cat.id
                    } label: {
                        Color.clear
                            .frame(width: Self.categoryCircleColumnWidth, height: Self.categoryCircleCellHeight)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(CategoryCircleNavButtonStyle(cat: cat))
                }
            }
            .padding(.horizontal, 16)
        }
    }

    /// Fixed column so icon circles sit on one horizontal line; labels sit below with stable height.
    private static let categoryCircleColumnWidth: CGFloat = 90
    private static let categoryCircleCellHeight: CGFloat = 118

    /// While the finger is down on the category cell, the label **slides** side-to-side (no 3D roll). Tap still selects on release.
    private struct ShiftingCategoryTitle: View {
        let title: String
        let isPressed: Bool

        private let wiggleHz: Double = 2.0
        private let wigglePoints: CGFloat = 6

        private var labelWidth: CGFloat { DashboardHomeView.categoryCircleColumnWidth - 8 }

        var body: some View {
            Group {
                if isPressed {
                    TimelineView(.periodic(from: .now, by: 1.0 / 60.0)) { context in
                        let t = context.date.timeIntervalSinceReferenceDate
                        let x = sin(t * 2 * .pi * wiggleHz) * wigglePoints
                        titleCore
                            .offset(x: x)
                            .frame(width: labelWidth, height: 36, alignment: .center)
                            .clipped()
                    }
                } else {
                    titleCore
                        .frame(width: labelWidth, height: 36, alignment: .center)
                }
            }
        }

        private var titleCore: some View {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }

    private struct CategoryCircleNavButtonStyle: ButtonStyle {
        let cat: StoreCategory

        func makeBody(configuration: Configuration) -> some View {
            let accent = cat.accentColor()
            return ZStack {
                VStack(alignment: .center, spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(accent.opacity(0.15))
                            .frame(width: 64, height: 64)
                        Image(systemName: cat.resolvedSystemImage())
                            .font(.system(size: 26))
                            .foregroundStyle(accent)
                    }
                    .frame(width: 64, height: 64, alignment: .center)

                    ShiftingCategoryTitle(title: cat.name, isPressed: configuration.isPressed)
                }
                .frame(width: DashboardHomeView.categoryCircleColumnWidth, alignment: .top)
                .allowsHitTesting(false)

                configuration.label
            }
            .frame(width: DashboardHomeView.categoryCircleColumnWidth, height: DashboardHomeView.categoryCircleCellHeight, alignment: .top)
            .contentShape(Rectangle())
        }
    }

    // MARK: Filter chips

    private var filterChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(FilterChip.allCases) { chip in
                    Button {
                        filterChip = chip
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: chip.systemImage)
                                .font(.system(size: 20, weight: .medium))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(filterChip == chip ? Color(red: 0.15, green: 0.62, blue: 0.38) : .secondary)
                            Text(chip.rawValue)
                                .font(.caption.weight(filterChip == chip ? .semibold : .regular))
                                .foregroundStyle(filterChip == chip ? Color(red: 0.15, green: 0.62, blue: 0.38) : .secondary)
                            Rectangle()
                                .fill(filterChip == chip ? Color(red: 0.15, green: 0.62, blue: 0.38) : .clear)
                                .frame(height: 2)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
        }
    }
}

#Preview("Empty") {
    DashboardHomeView()
}

#Preview("With items + seeded categories") {
    DashboardHomeView(
        store: ListingsStore(listings: Listing.sampleListings),
        categoriesStore: CategoriesStore(categories: [
            StoreCategory(id: "1", name: "Furniture", slug: "furniture", iconSystemName: nil),
            StoreCategory(id: "2", name: "Watch", slug: "watch", iconSystemName: nil),
            StoreCategory(id: "3", name: "Perfumes", slug: "perfumes", iconSystemName: nil),
        ])
    )
}
