//
//  ListingDetailView.swift
//  home_mart
//

import SwiftUI

struct ListingDetailView: View {
    let listing: Listing
    @State private var resolved: Listing?
    @State private var loadFailed = false

    private var display: Listing { resolved ?? listing }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                listingHero

                Text(display.title)
                    .font(.title2.bold())

                HStack {
                    Text(display.formattedPrice)
                        .font(.title3.weight(.semibold))
                    Spacer()
                    Text(display.category)
                        .font(.subheadline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.secondary.opacity(0.12)))
                }

                if let cond = display.condition, !cond.isEmpty {
                    Text(cond)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let meet = display.meetupLocation, !meet.isEmpty {
                    Label(meet, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(display.detail)
                    .font(.body)
                    .foregroundStyle(.secondary)

                if let seller = display.sellerDisplayName, !seller.isEmpty {
                    Label(seller, systemImage: "person.circle")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }

                if loadFailed, resolved == nil {
                    Text("Could not load full details.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 12) {
                    Button { /* contact */ } label: {
                        Text("Contact seller").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button { /* save */ } label: {
                        Label("Save to favorites", systemImage: "heart")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Listing")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard resolved == nil else { return }
            if listing.id.hasPrefix("demo-") { return }
            if let full = await ListingsStore.fetchListingDetail(id: listing.id) {
                resolved = full
            } else {
                loadFailed = true
            }
        }
    }

    @ViewBuilder
    private var listingHero: some View {
        let height: CGFloat = 220
        if let urlString = display.imageURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .frame(height: height)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: height)
                        .clipped()
                case .failure:
                    placeholderHero(height: height)
                @unknown default:
                    placeholderHero(height: height)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            placeholderHero(height: height)
        }
    }

    private func placeholderHero(height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.gray.opacity(0.1))
            .frame(height: height)
            .overlay(
                Image(systemName: display.systemImageName)
                    .font(.system(size: 72))
                    .foregroundStyle(.tertiary)
            )
    }
}
