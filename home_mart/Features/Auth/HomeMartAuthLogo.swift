//
//  HomeMartAuthLogo.swift
//  home_mart
//

import SwiftUI

/// Header logo on **log-in and sign-up** (same component). The PNG is wide (1024×558) and includes
/// extra margin inside the file; a slight zoom + clip tightens it without re-exporting the asset.
struct HomeMartAuthLogo: View {
    /// >1 crops away built-in whitespace around the mark.
    private let marginTrimScale: CGFloat = 1.28

    var body: some View {
        ZStack {
            Image("HomeMartLogo")
                .resizable()
                .scaledToFit()
                .scaleEffect(marginTrimScale)
        }
        .frame(maxHeight: 44)
        .frame(maxWidth: 220)
        .clipped()
    }
}
