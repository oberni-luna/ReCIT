//
//  EditionDuplicatesBanner.swift
//  ReCIT_iOS
//
//  « N doublons probables », at the head of the editions of « Éditions »: how many pairs the
//  screen sees, a sentence per reason, « Les comparer », and a cross. Closed, it stays closed
//  for this work until the pairs change — the work remembers what it showed. `bandeau · doublons
//  probables` (`770:4973`) in the Figma file, built on `Form / Notice`.
//
//  A whole section, so the picker places it in one line and it takes its own row's insets and
//  background off. PRD 0028.
//

import SwiftUI

struct EditionDuplicatesBanner: View {
    let work: Work
    let duplicates: EditionDuplicates
    /// « Les comparer ». `nil` hides the link.
    var onCompare: (() -> Void)?

    var body: some View {
        if duplicates.pairs.isEmpty == false, work.dismissedDuplicatesSignature != duplicates.signature {
            Section {
                card
                    .listRowInsets(.init())
                    .listRowBackground(Color.clear)
            }
        }
    }

    private var card: some View {
        HStack(alignment: .top, spacing: .sMedium) {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(.foregroundTinted)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: .xSmall) {
                Text("duplicates.banner.title \(duplicates.pairs.count)")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)

                Group {
                    let sameIsbn: Int = duplicates.count(of: .sameIsbn)
                    let probable: Int = duplicates.count(of: .probable)
                    if sameIsbn > 0 {
                        Text("duplicates.banner.same_isbn \(sameIsbn)")
                    }
                    if probable > 0 {
                        Text("duplicates.banner.probable \(probable)")
                    }
                }
                .textStyle(.footnote200)
                .foregroundStyle(.foregroundDefault)

                if let onCompare {
                    Button("duplicates.banner.compare", action: onCompare)
                        .buttonStyle(.plain)
                        .textStyle(.footnote200Bold)
                        .foregroundStyle(.foregroundTinted)
                        .accessibilityIdentifier("e2e.duplicates.compare")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button("action.close", systemImage: "xmark") {
                work.dismissedDuplicatesSignature = duplicates.signature
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.plain)
            .textStyle(.footnote200Bold)
            .foregroundStyle(.foregroundSecondary)
        }
        .padding(.vertical, .sMedium)
        .padding(.leading, .medium)
        .padding(.trailing, .sMedium)
        .background(.backgroundTinted)
        .clipShape(.rect(cornerRadius: DesignSystem.CornerRadius.medium))
    }
}
