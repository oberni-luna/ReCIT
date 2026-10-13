//
//  TextStyle.swift
// DansMaPoche
//
//  Created by Olivier Berni on 29/10/2024.
//

import SwiftUI

public extension DesignSystem {

    enum TextStyle {

        case title200
        case title50
        case content400Bold
        case content400
        case content300
        case footnote200
        case footnote200Bold
        case action300
        case action200
        case caption200

        var customFont: CustomFont? {
            switch self {
            case .title200, .title50:
                return .OpenSansExtraBold
            case .content300, .content400:
                return .AlegreyaMedium
            case .content400Bold, .footnote200Bold:
                return .AlegreyaBold
            case .footnote200:
                return .AlegreyaRegular
            case .action200, .action300:
                return .OpenSansSemiBold
            case .caption200:
                return .OpenSansRegular
            }
        }

        var size: CGFloat {
            switch self {
            case .title200: 32
            case .title50: 18
            case .content400Bold, .content400: 19
            case .content300: 17
            case .footnote200, .footnote200Bold: 12
            case .action200, .caption200: 12
            case .action300: 17
            }
        }

        var weight: UIFont.Weight {
            switch self {
            case .title200, .title50:
                return .black
            case .content300, .content400, .footnote200:
                return .medium
            case .action300, .action200, .content400Bold, .footnote200Bold:
                return .bold
            case .caption200:
                return .regular
            }
        }

        var fontTextStyle: UIFont.TextStyle {
            switch self {
            case .title200:
                return .largeTitle
            case .title50:
                return .title2
            case .content300, .content400Bold, .content400:
                return .body
            case .footnote200Bold, .footnote200:
                return .footnote
            case .action200, .action300:
                return .body
            case .caption200:
                return .caption1
            }
        }

        /// The font at the text size the app runs at — for UIKit, which has no SwiftUI
        /// environment to read it from (the navigation bar's titles).
        var uiFont: UIFont {
            if let customFont, let customUiFont = UIFont(name: customFont.fontName, size: size) {
                UIFontMetrics(forTextStyle: fontTextStyle).scaledFont(for: customUiFont)
            } else {
                UIFontMetrics(forTextStyle: fontTextStyle).scaledFont(for: .systemFont(ofSize: size, weight: weight))
            }
        }

        /// The font at `dynamicTypeSize` — what `textStyle(_:)` draws with, so that a view whose
        /// environment caps the text size (`.dynamicTypeSize(...)`, the Réseau graph at
        /// `.xxxLarge`) gets the capped size. `uiFont` scales to the app's own size, which a
        /// SwiftUI cap never reaches: the cap used to be silently ignored by every design-system
        /// style (PRD 0019, Q43).
        func uiFont(for dynamicTypeSize: DynamicTypeSize) -> UIFont {
            let traits: UITraitCollection = .init(preferredContentSizeCategory: .init(dynamicTypeSize))
            let metrics: UIFontMetrics = .init(forTextStyle: fontTextStyle)
            if let customFont, let customUiFont = UIFont(name: customFont.fontName, size: size) {
                return metrics.scaledFont(for: customUiFont, compatibleWith: traits)
            } else {
                return metrics.scaledFont(for: .systemFont(ofSize: size, weight: weight), compatibleWith: traits)
            }
        }

        var font: Font {
            Font(uiFont)
        }

        func font(for dynamicTypeSize: DynamicTypeSize) -> Font {
            Font(uiFont(for: dynamicTypeSize))
        }
    }
}

/// Draws a design-system style at the text size of the view's environment, cap included.
struct TextStyleModifier: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let style: DesignSystem.TextStyle

    func body(content: Content) -> some View {
        content.font(style.font(for: dynamicTypeSize))
    }
}

extension DesignSystem.TextStyle {
    enum CustomFont: CaseIterable {
        case AlegreyaBold, AlegreyaMedium, AlegreyaRegular
        case OpenSansExtraBold, OpenSansSemiBold, OpenSansRegular

        /// The name of the `.ttf` in the bundle. `Bundle.url(forResource:)` is
        /// case-sensitive, so this has to match the file on disk exactly — including
        /// `Semibold`, which Open Sans ships with a lowercase `b`.
        var registrationName: String {
            switch self {
            case .AlegreyaBold: "Alegreya-Bold"
            case .AlegreyaMedium: "Alegreya-Medium"
            case .AlegreyaRegular: "Alegreya-Regular"
            case .OpenSansExtraBold: "OpenSans-ExtraBold"
            case .OpenSansSemiBold: "OpenSans-Semibold"
            case .OpenSansRegular: "OpenSans-Regular"
            }
        }

        /// The **PostScript** name, which is what `UIFont(name:)` resolves — not the file
        /// name, and not always the same string. Open Sans capitalises differently
        /// (`Extrabold`, `Semibold`) and its regular face is plain `OpenSans`. Getting any
        /// of these wrong is silent: `UIFont(name:)` returns nil and the style falls back
        /// to the system font, which is what left every OpenSans style looking like San
        /// Francisco on device.
        var fontName: String {
            switch self {
            case .AlegreyaBold: "Alegreya-Bold"
            case .AlegreyaMedium: "Alegreya-Medium"
            case .AlegreyaRegular: "Alegreya-Regular"
            case .OpenSansExtraBold: "OpenSans-Extrabold"
            case .OpenSansSemiBold: "OpenSans-Semibold"
            case .OpenSansRegular: "OpenSans"
            }
        }

        var fileExtension: String { "ttf" }
    }
}

public extension View {
    func textStyle(_ style: DesignSystem.TextStyle) -> some View {
        modifier(TextStyleModifier(style: style))
    }
}

extension DesignSystem.TextStyle: CaseIterable {}

#Preview {
    VStack(spacing: 16) {
        ForEach(DesignSystem.TextStyle.allCases, id: \.font) {
            Text(String(describing: $0))
                .textStyle($0)
        }
    }
    .foregroundStyle(.foregroundDefault)
}
