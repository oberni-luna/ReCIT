//
//  SpineStripLoader.swift
//  ReCIT_iOS
//
//  Builds a book's painted spine from its own cover: crops the leftmost sliver of the
//  cover and returns it as a small image (stretched to the spine by the view), plus the
//  same sliver turned a quarter turn for books lying flat, plus a title colour
//  (dark/light) chosen from the strip's average luminance. Results are held in an
//  in-memory cache keyed by edition. Read-only, unauthenticated. See PRD 0002.
//

import Foundation
import UIKit
import CoreImage

actor SpineStripLoader {
    static let shared: SpineStripLoader = .init()

    struct Strip {
        /// The sliver upright: the cover's height runs along the spine's height.
        let image: UIImage
        /// The same sliver turned a quarter turn, so on a book lying flat the cover's
        /// height runs along the book's length and the sliver stretches vertically.
        let lyingImage: UIImage
        /// True when the strip is bright enough that a dark title reads best.
        let titleIsDark: Bool
    }

    /// Width (px) of the cover sliver used for the spine.
    static let stripWidth: Int = 10
    /// Luminance above which a dark title is preferred over a white one.
    static let darkTitleThreshold: Double = 0.6

    /// Mirror of `cache` readable straight from the main actor, so a view swapping from one
    /// book to another paints the new strip in the same frame. Without it the view has to
    /// await the actor and shows a parchment placeholder in between.
    @MainActor private static var mainCache: [String: Strip] = [:]

    @MainActor static func cachedStrip(forEditionUri uri: String) -> Strip? {
        mainCache[uri]
    }

    @MainActor static func remember(_ strip: Strip, forEditionUri uri: String) {
        mainCache[uri] = strip
    }

    private var cache: [String: Strip] = [:]
    private let context: CIContext = .init(options: [.cacheIntermediates: false])

    func strip(forEditionUri uri: String, url: URL) async -> Strip? {
        if let cached = cache[uri] { return cached }

        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let uiImage: UIImage = .init(data: data),
              let cgImage = uiImage.cgImage else {
            return nil
        }

        let rect: CGRect = Self.cropRect(imageWidth: cgImage.width, imageHeight: cgImage.height)
        guard let cropped = cgImage.cropping(to: rect) else { return nil }

        let luminance: Double = averageLuminance(of: cropped)
        let strip: Strip = .init(
            image: UIImage(cgImage: cropped),
            lyingImage: UIImage(cgImage: Self.turnedQuarter(cropped) ?? cropped),
            titleIsDark: Self.titleIsDark(luminance: luminance)
        )
        cache[uri] = strip
        return strip
    }

    // MARK: - Pure

    /// The leftmost `stripWidth` px of the cover, at full height.
    static func cropRect(imageWidth: Int, imageHeight: Int) -> CGRect {
        let width: Int = min(stripWidth, max(imageWidth, 1))
        return .init(x: 0, y: 0, width: CGFloat(width), height: CGFloat(max(imageHeight, 1)))
    }

    static func titleIsDark(luminance: Double) -> Bool {
        luminance > darkTitleThreshold
    }

    /// The strip rotated a quarter turn (width and height swapped), so a book lying flat
    /// shows the cover along its length instead of banded across its thickness. Pixels
    /// are redrawn rather than flagged with an orientation so the result is unambiguous.
    static func turnedQuarter(_ image: CGImage) -> CGImage? {
        let width: Int = max(image.height, 1)
        let height: Int = max(image.width, 1)
        guard let context: CGContext = .init(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        // Rotate a quarter turn about the origin, then slide the result back into frame.
        context.translateBy(x: CGFloat(width), y: 0)
        context.rotate(by: .pi / 2)
        context.draw(
            image,
            in: CGRect(x: 0, y: 0, width: CGFloat(image.width), height: CGFloat(image.height))
        )
        return context.makeImage()
    }

    // MARK: - CoreImage

    private func averageLuminance(of cgImage: CGImage) -> Double {
        let ciImage: CIImage = .init(cgImage: cgImage)
        guard let filter: CIFilter = .init(
            name: "CIAreaAverage",
            parameters: [kCIInputImageKey: ciImage, kCIInputExtentKey: CIVector(cgRect: ciImage.extent)]
        ), let output: CIImage = filter.outputImage else {
            return 0.5
        }
        var bitmap: [UInt8] = .init(repeating: 0, count: 4)
        context.render(
            output,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )
        let r: Double = Double(bitmap[0]) / 255
        let g: Double = Double(bitmap[1]) / 255
        let b: Double = Double(bitmap[2]) / 255
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }
}
