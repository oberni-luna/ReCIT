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
        case title100
        case title80
        case title50
        case content400
        case content400Bold
        case title30
        case content300
        case content300Bold
        case content200
        case content200Bold
        case footnote200
        case footnote100
        case footnote200Bold

        var customFont: CustomFont? {
            switch self {
            case .title200, .title100, .title80, .title50, .title30:
                return .poppinsBold
            case .content200, .content300, .content400, .footnote200, .footnote100:
                return .exo2Medium
            case .content200Bold, .content300Bold, .content400Bold, .footnote200Bold:
                return .exo2Bold
            }
        }

        var size: CGFloat {
            switch self {
            case .title200: 40
            case .title100: 30
            case .title80: 22
            case .title50: 18
            case .title30: 15
            case .content400, .content400Bold: 17
            case .content300, .content300Bold: 15
            case .content200, .content200Bold: 14
            case .footnote200, .footnote200Bold: 12
            case .footnote100: 10
            }
        }

        var weight: UIFont.Weight {
            switch self {
            case .title200, .title100, .title80, .title50, .title30, .content200Bold, .content300Bold, .content400Bold, .footnote200Bold:
                return .bold
            case .content200, .content300, .content400, .footnote200, .footnote100:
                return .medium
            }
        }

        var fontTextStyle: UIFont.TextStyle {
            switch self {
            case .title200:
                return .largeTitle
            case .title100:
                return .title1
            case .title80, .title50, .title30:
                return .title2
            case .content200, .content300, .content400, .content400Bold, .content200Bold, .content300Bold:
                return .body
            case .footnote200Bold, .footnote200, .footnote100:
                return .footnote
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
        case poppinsBold
        case exo2Medium
        case exo2Bold

        var registrationName: String {
            switch self {
            case .poppinsBold: "Poppins-Bold"
            case .exo2Medium: "Exo2-Medium"
            case .exo2Bold: "Exo2-Bold"
            }
        }

        var fontName: String {
            switch self {
            case .poppinsBold: "Poppins-Bold"
            case .exo2Medium: "Exo2-Medium"
            case .exo2Bold: "Exo2-Bold"
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
