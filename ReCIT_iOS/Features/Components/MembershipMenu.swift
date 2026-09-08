//
//  MembershipMenu.swift
//  ReCIT_iOS
//
//  A "…"-menu submenu listing every container the user owns — étagères, listes — with one
//  line each: « Ajouter à X » when the entity is not in it, « Retirer de X » when it is. One
//  submenu rather than two complementary ones, so the whole set is visible at once and the
//  line itself says which way it goes.
//
//  Nothing is tinted here: a menu belongs to iOS, and the framework already colours a
//  destructive role red on its own.
//

import SwiftUI

struct MembershipMenu: View {

    let titleKey: LocalizedStringKey
    let systemImage: String
    /// Accessibility identifier of the submenu; each line gets it suffixed with the entry name,
    /// which is what the end-to-end scenario taps.
    let identifier: String
    let entries: [MembershipMenuEntry]
    let toggle: (MembershipMenuEntry) -> Void

    var body: some View {
        if entries.isEmpty == false {
            Menu(titleKey, systemImage: systemImage) {
                ForEach(entries) { entry in
                    entryButton(entry)
                }
            }
            .accessibilityIdentifier(identifier)
        }
    }

    @ViewBuilder
    private func entryButton(_ entry: MembershipMenuEntry) -> some View {
        if entry.isMember {
            // Not destructive and not red: nothing is deleted, the entity stays in the
            // inventory and in every other container.
            Button("action.remove_from_named \(entry.name)", systemImage: "minus.circle") {
                toggle(entry)
            }
            .accessibilityIdentifier("\(identifier).\(entry.name)")
        } else {
            Button("action.add_to_named \(entry.name)", systemImage: "plus") {
                toggle(entry)
            }
            .accessibilityIdentifier("\(identifier).\(entry.name)")
        }
    }
}
