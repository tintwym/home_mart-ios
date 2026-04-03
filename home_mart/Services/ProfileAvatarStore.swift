//
//  ProfileAvatarStore.swift
//  home_mart
//

import Foundation
import Observation
import UIKit

/// Local profile photo (JPEG in `UserDefaults`). Upload to your API when you add an endpoint.
@MainActor
@Observable
final class ProfileAvatarStore {
    static let shared = ProfileAvatarStore()

    private let defaultsKey = "home_mart.profileAvatar.jpeg"
    private(set) var imageData: Data?

    private init() {
        imageData = UserDefaults.standard.data(forKey: defaultsKey)
    }

    var uiImage: UIImage? {
        guard let imageData, let img = UIImage(data: imageData) else { return nil }
        return img
    }

    func setPhotoJPEGData(_ data: Data?) {
        imageData = data
        if let data {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        } else {
            UserDefaults.standard.removeObject(forKey: defaultsKey)
        }
    }

    /// Downscale and re-encode to keep `UserDefaults` small.
    static func compressImageData(_ data: Data, maxDimension: CGFloat = 512) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let maxSide = max(image.size.width, image.size.height)
        guard maxSide > 0 else { return nil }
        let scale = min(1, maxDimension / maxSide)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: 0.82)
    }
}
