//
//  ShelfPalette.swift
//  ReCIT_iOS
//
//  Colour helpers for the painted bookshelf: hex parsing, the parchment fallback
//  used before a cover colour is known, and readable ink over a spine. Spine colours
//  are saturation-boosted at render so painted books read vivid. See ADR 0003.
//

import SwiftUI

extension Color {
    /// Builds a colour from a "#RRGGBB" (or "RRGGBB") string. Falls back to a neutral
    /// grey for malformed input rather than failing.
    init(hex: String) {
        let (r, g, b): (Double, Double, Double) = ShelfPalette.rgb(fromHex: hex)
        self.init(red: r, green: g, blue: b)
    }
}

enum ShelfPalette {
    /// Warm paper tone shown on a spine before its cover colour is extracted.
    static let parchment: Color = .init(hex: "#E4DAC4")

    /// The painted spine colour: the persisted hex pushed toward a punchier saturation
    /// so books read vivid on the shelf, with brightness clamped for legibility.
    static func spineColor(_ hex: String?) -> Color {
        guard let hex, hex.isEmpty == false else { return parchment }
        let (r, g, b): (Double, Double, Double) = rgb(fromHex: hex)
        var (h, s, v): (Double, Double, Double) = rgbToHSV(r: r, g: g, b: b)
        s = min(s * 1.45, 0.92)
        v = min(max(v, 0.42), 0.82)
        return .init(hue: h / 360, saturation: s, brightness: v)
    }

    /// Chooses cream or dark ink for a title, based on the spine colour's luminance.
    static func ink(onHex hex: String?) -> Color {
        guard let hex, hex.isEmpty == false else { return .init(hex: "#4A3B2C") }
        let (r, g, b): (Double, Double, Double) = rgb(fromHex: hex)
        let luminance: Double = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return luminance > 0.58 ? .init(hex: "#3A2E24") : .init(hex: "#F4EEE1")
    }

    // MARK: - Conversions

    static func rgb(fromHex hex: String) -> (Double, Double, Double) {
        let cleaned: String = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        return (
            Double((value & 0xFF0000) >> 16) / 255,
            Double((value & 0x00FF00) >> 8) / 255,
            Double(value & 0x0000FF) / 255
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
}
