//
//  EditionLanguageMenu.swift
//  ReCIT_iOS
//
//  The language « Éditions » shows, at the right of its « Éditions de … » header, and the menu
//  that changes it: every edition, then each language with its count, the most editions first,
//  then those without a language. The language shown carries the check.
//  `L1` / `L2` of `Éditions · Filtre par langue` (`831:7654`) in the Figma file.
//

import SwiftUI

struct EditionLanguageMenu: View {
    let options: [EditionLanguageFilterOption]
    @Binding var selection: EditionLanguageFilter

    var body: some View {
        // Toggles rather than a Picker: a Picker's row keeps only its first Text, and the count is
        // the menu's subtitle. A toggle in a menu carries the same check.
        Menu {
            ForEach(sections, id: \.self) { section in
                Section {
                    ForEach(section, id: \.language) { option in
                        Toggle(isOn: isSelected(option.language)) {
                            Text(Self.name(of: option.language))
                            Text("editions.language.count \(option.count)")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: .xSmall) {
                Text(Self.name(of: selection))
                Image(systemName: "chevron.up.chevron.down")
                    .imageScale(.small)
            }
            .foregroundStyle(.foregroundTinted)
            .fixedSize()
        }
        .accessibilityLabel(Text("editions.language.menu \(Self.name(of: selection))"))
        .accessibilityIdentifier("e2e.editions.language")
    }

    /// On for the language shown; turning one on shows it. Turning the shown one off does nothing:
    /// a language is always shown.
    private func isSelected(_ language: EditionLanguageFilter) -> Binding<Bool> {
        .init(
            get: { selection == language },
            set: { isOn in
                if isOn {
                    selection = language
                }
            }
        )
    }

    /// Every edition, the languages, the editions without one: three sections, so the menu draws
    /// its separators between them.
    private var sections: [[EditionLanguageFilterOption]] {
        [
            options.filter { $0.language == .all },
            options.filter { if case .code = $0.language { true } else { false } },
            options.filter { $0.language == .unspecified }
        ]
        .filter { $0.isEmpty == false }
    }

    static func name(of language: EditionLanguageFilter) -> String {
        switch language {
        case .all:
            String(localized: "editions.language.all")
        case .code(let code):
            EditionLanguageFilter.name(of: code, in: .current)
        case .unspecified:
            String(localized: "editions.language.unspecified")
        }
    }
}
