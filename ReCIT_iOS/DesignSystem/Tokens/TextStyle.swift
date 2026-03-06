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
        case content300
        case footnote200
        case footnote200Bold
        case action300
        case action200

        var customFont: CustomFont? {
            switch self {
            case .title200, .title50:
                return .OpenSansExtraBold
            case .content300:
                return .AlegreyaMedium
            case .content400Bold, .footnote200Bold:
                return .AlegreyaBold
            case .footnote200:
                return .AlegreyaRegular
            case .action200, .action300:
                return .OpenSansSemiBold
            }
        }

        var size: CGFloat {
            switch self {
            case .title200: 32
            case .title50: 18
            case .content400Bold: 18
            case .content300: 15
            case .footnote200, .footnote200Bold: 12
            case .action200: 12
            case .action300: 17
            }
        }

        var weight: UIFont.Weight {
            switch self {
            case .title200, .title50, .content400Bold, .footnote200Bold:
                return .bold
            case .content300, .footnote200:
                return .medium
            case .action300, .action200:
                return .bold
            }
        }

        var fontTextStyle: UIFont.TextStyle {
            switch self {
            case .title200:
                return .largeTitle
            case .title50:
                return .title2
            case .content300, .content400Bold:
                return .body
            case .footnote200Bold, .footnote200:
                return .footnote
            case .action200, .action300:
                return .body
            }
        }

        var uiFont: UIFont {
            if let customFont, let customUiFont = UIFont(name: customFont.fontName, size: size) {
                UIFontMetrics(forTextStyle: fontTextStyle).scaledFont(for: customUiFont)
            } else {
                UIFontMetrics(forTextStyle: fontTextStyle).scaledFont(for: .systemFont(ofSize: size, weight: weight))
            }
        }

        var font: Font {
            Font(uiFont)
        }
    }
}

extension DesignSystem.TextStyle {
    enum CustomFont: CaseIterable {
        case AlegreyaBold, AlegreyaMedium, AlegreyaRegular
        case OpenSansExtraBold, OpenSansSemiBold, OpenSansRegular

        var registrationName: String {
            switch self {
            case .AlegreyaBold: "Alegreya-Bold"
            case .AlegreyaMedium: "Alegreya-Medium"
            case .AlegreyaRegular: "Alegreya-Regular"
            case .OpenSansExtraBold: "OpenSans-ExtraBold"
            case .OpenSansSemiBold: "OpenSans-SemiBold"
            case .OpenSansRegular: "OpenSans-Regular"
            }
        }

        var fontName: String {
            switch self {
            case .AlegreyaBold: "Alegreya-Bold"
            case .AlegreyaMedium: "Alegreya-Medium"
            case .AlegreyaRegular: "Alegreya-Regular"
            case .OpenSansExtraBold: "OpenSans-ExtraBold"
            case .OpenSansSemiBold: "OpenSans-SemiBold"
            case .OpenSansRegular: "OpenSans-Regular"
            }
        }

        var fileExtension: String { "ttf" }
    }
}

public extension View {
    func textStyle(_ style: DesignSystem.TextStyle) -> some View {
        font(style.font)
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
    .foregroundStyle(.textDefault)
}
