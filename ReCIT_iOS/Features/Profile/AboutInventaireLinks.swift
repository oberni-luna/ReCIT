//
//  AboutInventaireLinks.swift
//  ReCIT_iOS
//
//  « Aller plus loin »: four pages of inventaire.io, each opened in Safari. A group outlined by a
//  hairline rather than filled — on a white screen, the grey fill of a grouped list would be the
//  one grey thing left, and read as a hole.
//
//  The source code link goes to Codeberg, where inventaire.io is developed; the GitHub mirror is
//  archived.
//

import SwiftUI

struct AboutInventaireLinks: View {

    private let links: [Destination] = [
        .init(title: "about.link.website", url: Constant.websiteURL),
        .init(title: "about.link.data", url: Constant.dataURL),
        .init(title: "about.link.source", url: Constant.sourceURL),
        .init(title: "about.link.donate", url: Constant.donateURL)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: .small) {
            Text("about.links")
                .textStyle(.caption200)
                .foregroundStyle(.foregroundSecondary)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: .zero) {
                ForEach(links.enumerated(), id: \.element.url) { index, link in
                    if index > 0 {
                        Rectangle()
                            .fill(DesignSystem.Color.borderDefault.color)
                            .frame(height: 1)
                            .padding(.leading, .medium)
                    }
                    AboutInventaireLinkRow(title: link.title, destination: link.url)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: .rounded)
                    .strokeBorder(DesignSystem.Color.borderDefault.color, lineWidth: 1)
            }
        }
    }
}

private extension AboutInventaireLinks {
    struct Destination {
        let title: LocalizedStringKey
        let url: URL
    }

    enum Constant {
        static let websiteURL: URL = .init(string: "https://inventaire.io")!
        static let dataURL: URL = .init(string: "https://data.inventaire.io")!
        static let sourceURL: URL = .init(string: "https://codeberg.org/inventaire/inventaire")!
        static let donateURL: URL = .init(string: "https://inventaire.io/donate")!
    }
}

#Preview {
    AboutInventaireLinks()
        .padding()
}
