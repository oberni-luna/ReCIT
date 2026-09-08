//
//  MembershipMenu.swift
//  ReCIT_iOS
//
//  A "…"-menu submenu listing every container the user owns — étagères, listes — with one
//  line each: « Ajouter à X » when the entity is not in it, « Retirer de X » when it is. One
//  submenu rather than two complementary ones, so the whole set is visible at once and the
//  line itself says which way it goes.
//
//  Colours are the caller's: the menus that carry this set their contents to the label
//  colour, so glyphs and titles read alike the way the framework's own menus do.
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
            // Nothing is deleted: the entity stays in the inventory and in every other
            // container. The icon says "off the shelf", not "trash".
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
