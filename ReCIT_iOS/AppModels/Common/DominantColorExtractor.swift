//
//  DominantColorExtractor.swift
//  ReCIT_iOS
//
//  Extracts a pleasant "paint" colour from a book cover for the shelf spines.
//  Averages the cover (CIAreaAverage) then normalises saturation/lightness so the
//  tint reads as watercolour rather than a muddy mean. Result is persisted on
//  `Edition.dominantColorHex`, so this runs at most once per edition. See ADR 0003.
//

import Foundation
import UIKit
import CoreImage

actor DominantColorExtractor {
    static let shared: DominantColorExtractor = .init()

    private let context: CIContext = .init(options: [.cacheIntermediates: false])

    /// Downloads the cover and returns a normalised dominant-colour hex ("#RRGGBB"),
    /// or `nil` if the image can't be fetched/decoded.
    func hex(forImageAt url: URL) async -> String? {
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let uiImage: UIImage = .init(data: data),
              let ciImage: CIImage = .init(image: uiImage) else {
            return nil
        }

        let extent: CGRect = ciImage.extent
        guard extent.width > 0, extent.height > 0 else { return nil }

        guard let filter: CIFilter = .init(
            name: "CIAreaAverage",
            parameters: [
                kCIInputImageKey: ciImage,
                kCIInputExtentKey: CIVector(cgRect: extent)
            ]
        ), let output: CIImage = filter.outputImage else {
            return nil
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

        return Self.normalizedHex(
            r: Double(bitmap[0]) / 255,
            g: Double(bitmap[1]) / 255,
            b: Double(bitmap[2]) / 255
        )
    }

    /// Pushes an average colour toward a legible painted tint: floors saturation so
    /// greys gain a hue, and clamps brightness away from pure black/white.
    static func normalizedHex(r: Double, g: Double, b: Double) -> String {
        var (h, s, v): (Double, Double, Double) = rgbToHSV(r: r, g: g, b: b)
        s = min(max(s * 1.3, 0.5), 0.9)
        v = min(max(v, 0.42), 0.8)
        let (nr, ng, nb): (Double, Double, Double) = hsvToRGB(h: h, s: s, v: v)
        return String(
            format: "#%02X%02X%02X",
            Int((nr * 255).rounded()),
            Int((ng * 255).rounded()),
            Int((nb * 255).rounded())
        )
    }

    private static func rgbToHSV(r: Double, g: Double, b: Double) -> (Double, Double, Double) {
        let mx: Double = max(r, g, b)
        let mn: Double = min(r, g, b)
        let delta: Double = mx - mn
        var h: Double = 0
        if delta != 0 {
            if mx == r {
                h = ((g - b) / delta).truncatingRemainder(dividingBy: 6)
            } else if mx == g {
                h = (b - r) / delta + 2
            } else {
                h = (r - g) / delta + 4
            }
            h *= 60
            if h < 0 { h += 360 }
        }
        let s: Double = mx == 0 ? 0 : delta / mx
        return (h, s, mx)
    }

    private static func hsvToRGB(h: Double, s: Double, v: Double) -> (Double, Double, Double) {
        let c: Double = v * s
        let x: Double = c * (1 - abs((h / 60).truncatingRemainder(dividingBy: 2) - 1))
        let m: Double = v - c
        let (r1, g1, b1): (Double, Double, Double)
        switch h {
        case ..<60: (r1, g1, b1) = (c, x, 0)
        case ..<120: (r1, g1, b1) = (x, c, 0)
        case ..<180: (r1, g1, b1) = (0, c, x)
        case ..<240: (r1, g1, b1) = (0, x, c)
        case ..<300: (r1, g1, b1) = (x, 0, c)
        default: (r1, g1, b1) = (c, 0, x)
        }
        return (r1 + m, g1 + m, b1 + m)
    }
}
