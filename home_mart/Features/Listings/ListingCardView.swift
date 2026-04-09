//
//  ListingCardView.swift
//  home_mart
//

import SwiftUI

/// Marketplace-style card (image area, meta row, title, price, seller strip).
struct ListingCardView: View {
    let listing: Listing
    var onCardTap: () -> Void

    @Bindable private var wishlist = WishlistStore.shared
    @Bindable private var auth = AuthStore.shared

    private var isSignedIn: Bool {
        auth.authToken != nil
    }

    private var listingSubtitle: String {
        let cond = listing.condition?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !cond.isEmpty {
            return "\(cond) · \(listing.category)"
        }
        return listing.category
    }

    /// Red filled heart only when signed in and saved; guests always see a neutral outline.
    private var showsWishlistedStyle: Bool {
        isSignedIn && wishlist.contains(listing.id)
    }

    @ViewBuilder
    private var listingImage: some View {
        if let urlString = listing.imageURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    Color(.systemGray6)
                        .overlay(ProgressView())
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Color(.systemGray6)
                        .overlay(
                            Image(systemName: listing.systemImageName)
                                .font(.system(size: 40))
                                .foregroundStyle(.tertiary)
                        )
                @unknown default:
                    Color(.systemGray6)
                }
            }
        } else {
            Color(.systemGray6)
                .overlay(
                    Image(systemName: listing.systemImageName)
                        .font(.system(size: 40))
                        .foregroundStyle(.tertiary)
                )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .top) {
                Button(action: onCardTap) {
                    ZStack(alignment: .top) {
                        listingImage
                            .aspectRatio(1, contentMode: .fit)
                            .clipped()

                        HStack {
                            Text("Recently listed")
                                .font(.caption2)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(.black.opacity(0.45), in: Capsule())
                            Spacer(minLength: 0)
                        }
                        .padding(8)
                    }
                }
                .buttonStyle(.plain)

                VStack {
                    Spacer(minLength: 0)
                    HStack {
                        Spacer(minLength: 0)
                        Button {
                            guard isSignedIn else { return }
                            wishlist.toggle(listing.id)
                        } label: {
                            Image(systemName: showsWishlistedStyle ? "heart.fill" : "heart")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(showsWishlistedStyle ? Color.red : Color.primary)
                                .frame(width: 32, height: 32)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(
                            !isSignedIn
                                ? "Sign in to save to wishlist"
                                : (showsWishlistedStyle ? "Remove from wishlist" : "Add to wishlist")
                        )
                        .padding(8)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Button(action: onCardTap) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(listing.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 8)

                    Text(listing.formattedPrice)
                        .font(.subheadline.weight(.semibold))
                        .padding(.top, 2)

                    Text(listingSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)

                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(.systemGray4))
                            .frame(width: 22, height: 22)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            )
                        Text(listing.sellerDisplayName ?? "Seller")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .padding(.top, 6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
    }
}
