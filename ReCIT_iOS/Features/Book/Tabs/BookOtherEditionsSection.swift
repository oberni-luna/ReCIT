//
//  BookOtherEditionsSection.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 22/11/2026.
//

import SwiftUI

/// A link to the other editions of each underlying work that actually has some. A work with only
/// this one edition contributes no row; when no underlying work has siblings the section is absent
/// entirely. Tapping opens the work's edition gateway (the picker). (ADR 0002)
struct BookOtherEditionsSection: View {
    private let works: [Work]

    @Binding private var entityDestination: NavigationDestination?

    init(
        works: [Work],
        entityDestination: Binding<NavigationDestination?>
    ) {
        self.works = works
        _entityDestination = entityDestination
    }

    var body: some View {
        if works.isEmpty == false {
            Section {
                ForEach(works.sorted(by: { $0.title < $1.title })) { work in
                    Button {
                        entityDestination = .work(uri: work.uri)
                    } label: {
                        NavigationLink(value: UUID()) {
                            OtherEditionsCell(work: work)
                                // The end-to-end scenario's way to the picker. Since Move 3 the
                                // search no longer passes through it, so this row is the only
                                // path left that exercises `WorkEditionPicker` at all.
                                .accessibilityIdentifier(AccessibilityID.otherEditions)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private extension BookOtherEditionsSection {
    enum AccessibilityID {
        static let otherEditions: String = "e2e.book.otherEditions"
    }
}

#Preview {
    @Previewable @State var destination: NavigationDestination?

    List {
        BookOtherEditionsSection(works: [], entityDestination: $destination)
    }
}
