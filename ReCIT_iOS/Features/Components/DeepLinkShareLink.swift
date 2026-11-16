//
//  DeepLinkShareLink.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import SwiftUI

/// « Partager », as the system says it: the share sheet with the Ex-libris link to `link`, and
/// `subject` — the name of what it opens — as its subject and its preview's title. Nothing at
/// all when `link` cannot be built, so a screen never offers a link that would not open.
struct DeepLinkShareLink: View {
    private let link: DeepLink
    private let subject: String

    init(
        _ link: DeepLink,
        subject: String
    ) {
        self.link = link
        self.subject = subject
    }

    var body: some View {
        if let url = link.url {
            ShareLink(
                item: url,
                subject: Text(subject),
                preview: SharePreview(subject)
            )
        }
    }
}

#Preview {
    NavigationStack {
        Text(verbatim: "Le Petit Prince")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    DeepLinkShareLink(.entity(uri: "isbn:9782070612758"), subject: "Le Petit Prince")
                }
            }
    }
}
