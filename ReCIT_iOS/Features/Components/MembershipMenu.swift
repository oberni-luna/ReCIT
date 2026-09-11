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
//  A last line may create a container instead of toggling one. This is where the rule
//  « jamais de sous-menu vide » lives, written once for both carriers: a menu offering
//  creation shows itself even with nothing to list, since that line is exactly what a user
//  who owns no container needs. It comes last and behind a separator — the existing
//  containers keep their rank, and creation is the way out when none of them fits. See
//  PRD 0014.
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
    /// Title of the creation line. Drawn only together with `create`, so it says nothing on
    /// a menu that does not offer creation.
    var creationTitleKey: LocalizedStringKey?
    /// Opens the creation form. Presenting is the carrier screen's job — the menu only asks —
    /// so this writes a request into a binding rather than showing a sheet. `nil` on a menu
    /// that does not offer creation, and the empty submenu then hides itself as before.
    var create: (() -> Void)?

    /// The creation line, or nothing at all. Derived once, so the title and the action cannot
    /// disagree: the guard below and the row itself read the same value.
    private var creation: (titleKey: LocalizedStringKey, action: () -> Void)? {
        guard let creationTitleKey, let create else { return nil }
        return (creationTitleKey, create)
    }

    var body: some View {
        if entries.isEmpty == false || creation != nil {
            Menu(titleKey, systemImage: systemImage) {
                ForEach(entries) { entry in
                    entryButton(entry)
                }

                if let creation {
                    // Its own section, so the separator comes with it: last, told apart from
                    // the containers above, and the only line when there are none.
                    Section {
                        Button(creation.titleKey, systemImage: "plus.circle") {
                            creation.action()
                        }
                        .accessibilityIdentifier("\(identifier).create")
                    }
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
