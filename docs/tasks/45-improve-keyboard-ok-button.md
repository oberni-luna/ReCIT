---
issue: 45
status: to-test
wiki: [[lists]], [[book-and-editions]], [[platform-and-design]]
note: screenshot — Liste, Commentaire focused, OK glued to the keyboard's top edge (iOS 26 glass)
created: 2026-11-06
---

## Context / Decisions

> Dans les listes quand on edit le commentaire, le clavier apparait avec un bouton "OK" qui est collé au clavier.
> Peux-tu ajouter un padding autour de ce bouton de 8pts, et rendre ce bouton "Prominent" ?
> Dans la fiche livre, on peut aussi éditer un commentaire et une note privée, peux-tu ajouter ce bouton aussi quand le clavier apparait pour editer ces 2 champs ?

- **Today**: the Liste's comment field (`ListElementsPage`) puts an « OK » (`action.ok`) in `ToolbarItemGroup(placement: .keyboard)`. It ends editing, and leaving the field writes the comment. On iOS 26 that button sits flush against the keyboard's top edge.
- **Spacing**: 8 pt around the OK button, through `Spacing.small`. No literal `8`.
- **Style « Prominent »**: `.buttonStyle(.glassProminent)` from iOS 26, `.buttonStyle(.borderedProminent)` before.
  - New wrapper next to `glassButtonStyle()` in `DesignSystem/Extensions/View+glass.swift`, e.g. `glassProminentButtonStyle()`. Keeps `#available` out of screens (CLAUDE.md, iOS 18+).
- **One shared button**: a single keyboard OK component (e.g. `KeyboardOKButton` in `Features/Components/`) used everywhere. No copy per screen.
- **Fiche livre**: « Dans mon inventaire » (`BookMyCopySection`) has two `AutosavingTextField`s: Commentaire (`details`) and Note privée (`notes`). Both get the same OK while focused.
  - `AutosavingTextField` owns its `@FocusState`, so the OK lives there: tapping it drops focus.
  - Saving unchanged: focus loss already calls `save`. No new write path.
  - Keyboard toolbar items aggregate across the hierarchy: two fields must still show **one** OK, not two.
- **Out of scope**: the return key keeps inserting a new line. No other text field in the app gets the OK. Android untouched.

## Acceptance criteria

- [ ] Liste, my list, tap « Mon commentaire » → keyboard shows OK with an 8 pt gap to the keyboard's top edge.
- [ ] Same OK is prominent: tinted glass on iOS 26+, filled bordered-prominent capsule on iOS 18.
- [ ] Liste: tap OK → keyboard hides, comment saved as before.
- [ ] Fiche livre of a book I own, tap Commentaire → the same OK appears; tap it → keyboard hides, text saved.
- [ ] Fiche livre, tap Note privée → the same OK appears, exactly one; tap it → keyboard hides, text saved.
- [ ] Return key in all three fields still inserts a new line.

## Implementation

- New `ReCIT_iOS/Features/Components/KeyboardOKButton.swift`: a `ToolbarContent` (`ToolbarItemGroup(placement: .keyboard)`, `Spacer()` + `Button("action.ok")`), `.glassProminentButtonStyle()` then `.padding(.all, .small)` for the 8 pt gap; identifier `keyboard.ok`; `.sharedBackgroundVisibility(.hidden)` on iOS 26 so the button does not sit inside the bar's glass ring (same pattern as `ProfileToolbarItem`).
- `View+glass.swift`: `glassProminentButtonStyle()` — `.glassProminent` on iOS 26+, `.borderedProminent` before.
- `ListElementsPage`: inline keyboard `ToolbarItemGroup` replaced by `KeyboardOKButton { isCommentFocused = false }`.
- `AutosavingTextField`: `.toolbar { if isFocused { KeyboardOKButton { isFocused = false } } }` — only the focused field adds the item, so Commentaire + Note privée show one OK; focus loss still calls `save`.
- Return key untouched. No new string, no pbxproj edit, baseline untouched.
- Proof: build ✅ (SwiftLint in the build).

## Review

## Verification

manual validation — not run by agent. Unseen: the 8 pt gap above the keyboard on iOS 26 and iOS 18; the OK showing from an `AutosavingTextField` inside a `List` row of the Fiche livre.

## Feedback
