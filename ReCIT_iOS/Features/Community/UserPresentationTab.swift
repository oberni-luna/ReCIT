//
//  UserPresentationTab.swift
//  ReCIT_iOS
//
//  A reader's bio, under the Présentation tab of their profile — « Bio » in English. It used to
//  open the page above the étagères, centred, whatever the tab; it is now a page of its own, the
//  text in one card, left-aligned like any paragraph. See the « Détail d'un amis » section of the
//  Figma file (`865:17783`, F6).
//

import SwiftUI

struct UserPresentationTab: View {
    let user: User

    var body: some View {
        if let bio = user.bio, bio.isEmpty == false {
            Section {
                // The page's content, so in the text's own colour rather than a caption's; an
                // address written in it opens.
                Text(Self.linked(bio))
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .listRowBackground(DesignSystem.Color.backgroundFormCell.color)
        } else {
            Section {
                EmptyStateView(
                    glyph: "text.quote",
                    title: "user.presentation.empty \(user.username)"
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, .large)
            }
            .listRowBackground(Color.clear)
        }
    }

    /// The bio with every web address in it made a link — « www.utopithèque.com » as well as
    /// a full `https://` one, which the detector completes.
    static func linked(_ text: String) -> AttributedString {
        var attributed: AttributedString = .init(text)
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return attributed
        }

        let matches: [NSTextCheckingResult] = detector.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for match in matches {
            guard let url = match.url,
                  let range = Range(match.range, in: text),
                  let lower = AttributedString.Index(range.lowerBound, within: attributed),
                  let upper = AttributedString.Index(range.upperBound, within: attributed)
            else { continue }
            attributed[lower..<upper].link = url
        }
        return attributed
    }
}
