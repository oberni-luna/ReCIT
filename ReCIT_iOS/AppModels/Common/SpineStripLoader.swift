//
//  SpineStripLoader.swift
//  ReCIT_iOS
//
//  Builds a book's painted spine from its own cover: crops the leftmost sliver of the
//  cover and returns it as a small image (stretched to the spine by the view), plus a
//  title colour (dark/light) chosen from the strip's average luminance. Results are held
//  in an in-memory cache keyed by edition. Read-only, unauthenticated. See PRD 0002.
//

import Foundation
import UIKit
import CoreImage

actor SpineStripLoader {
    static let shared: SpineStripLoader = .init()

    struct Strip {
        let image: UIImage
        /// True when the strip is bright enough that a dark title reads best.
        let titleIsDark: Bool
    }

    /// Width (px) of the cover sliver used for the spine.
    static let stripWidth: Int = 10
    /// Luminance above which a dark title is preferred over a white one.
    static let darkTitleThreshold: Double = 0.6

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
