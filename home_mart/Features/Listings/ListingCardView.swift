//
//  ListingCardView.swift
//  home_mart
//

import SwiftUI

/// Marketplace-style card (image area, meta row, title, price, seller strip).
struct ListingCardView: View {
    let listing: Listing

    private var listingSubtitle: String {
        let cond = listing.condition?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !cond.isEmpty {
            return "\(cond) · \(listing.category)"
        }
        return listing.category
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .top) {
                Group {
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
                .aspectRatio(1, contentMode: .fit)
                .clipped()

                HStack {
                    Text("Recently listed")
                        .font(.caption2)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.45), in: Capsule())
                    Spacer()
                    Button { } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(.black.opacity(0.35), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(8)

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button { } label: {
                            Image(systemName: "heart")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.primary)
                                .frame(width: 32, height: 32)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text("Buyer Protection")
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color(red: 0.12, green: 0.55, blue: 0.38))
                .padding(.top, 8)

            Text(listing.title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .padding(.top, 4)

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
    }
}
