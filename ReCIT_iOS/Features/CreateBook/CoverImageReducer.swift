//
//  CoverImageReducer.swift
//  ReCIT_iOS
//
//  What leaves the device as a cover: JPEG bytes, already reduced, whichever way the picture
//  came in — the camera, Photos, a file. A nine-megapixel photograph of a paperback is a slow
//  upload and a cover nobody will ever look at full size.
//
//  `UIGraphicsImageRenderer` and not `ImageRenderer`: the house rule prefers the latter for
//  turning a *SwiftUI view* into an image, which is not what this is. Here a picture is being
//  resampled.
//
//  See PRD 0015 and PRD 0021.
//

import UIKit

enum CoverImageReducer {

    /// The longest edge the uploaded image keeps. A cover is displayed at a few hundred points
    /// at most, and inventaire.io resizes on its side too.
    static let maximumDimension: CGFloat = 1600

    /// JPEG quality. High enough that a title stays readable, low enough that a phone on a
    /// bookshop's Wi-Fi is not held up by it.
    static let compressionQuality: CGFloat = 0.8

    /// The bytes of any image the system can decode — HEIC from Photos, PNG from Files — as a
    /// reduced JPEG, or `nil` when they are not an image.
    static func jpegData(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        return jpegData(for: image)
    }

    /// Reduces the picture to something worth sending, and answers its JPEG bytes.
    static func jpegData(for image: UIImage) -> Data? {
        let longestEdge: CGFloat = max(image.size.width, image.size.height)
        guard longestEdge > 0 else { return nil }

        let scale: CGFloat = min(1, maximumDimension / longestEdge)
        let size: CGSize = .init(width: image.size.width * scale, height: image.size.height * scale)

        let format: UIGraphicsImageRendererFormat = .default()
        format.scale = 1
        let reduced: UIImage = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: .init(origin: .zero, size: size))
        }

        return reduced.jpegData(compressionQuality: compressionQuality)
    }
}
