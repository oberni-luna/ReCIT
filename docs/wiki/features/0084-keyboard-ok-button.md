# One prominent « OK » over the keyboard, on the Liste and the Fiche livre

Shipped on 2026-11-06, iOS only (issue #45). On the Liste, « Mon commentaire » spans lines, so its return key starts
a new line, and an « OK » above the keyboard ends the editing ([0060](0060-list-cover-flow.md)). On iOS 26 that
button was plain and sat flush against the keyboard's top edge. On the Fiche livre, the Commentaire and the Note
privée of « Dans mon inventaire » ([0080](0080-a-private-note-on-my-copy.md)) had no « OK » at all. Now all three
fields show the same prominent « OK ».

## What it does

- Liste, my list, tap « Mon commentaire » → the keyboard shows « OK » at its trailing edge. Tap it → the keyboard
  hides and the comment is written, as before.
- Fiche livre of a book I own, tap « Ce que j'en pense » (Commentaire) or « Ce que je garde pour moi » (Note privée)
  → the same « OK ». Exactly one shows, even with two fields in the section. Tap it → the keyboard hides and the text
  is saved, through the save that focus loss already ran.
- The button is prominent: tinted glass on iOS 26 and later, a filled bordered-prominent capsule on iOS 18. On
  iOS 26 the glass item floats about 8 pt above the keyboard's top edge.
- The return key still inserts a new line in all three fields. No other text field in the app has this « OK ».

## Technical surface

- `Features/Components/KeyboardOKButton.swift`: a `ToolbarContent`, one `ToolbarItemGroup(placement: .keyboard)`
  with a `Spacer()` and `Button("action.ok")`, identifier `keyboard.ok`. Each screen passes the action that drops its
  focus. The Liste's inline keyboard group in `ListElementsPage` is replaced by it.
- `DesignSystem/Extensions/View+glass.swift`: `glassProminentButtonStyle()`, `.glassProminent` from iOS 26 and
  `.borderedProminent` before, next to `glassButtonStyle()`. It keeps the `#available` out of the screens.
- **The Fiche livre's toolbar sits on its `List`, not in the field.** The first version put the `.toolbar` inside
  `AutosavingTextField`, shown only while that field was focused. The field is a cell of `BookDetailView`'s `List`,
  and a toolbar declared inside a `List` cell never reached the keyboard. `BookDetailView` now owns
  `@FocusState focusedText: InventoryItemTextAttribute?` and puts `KeyboardOKButton { focusedText = nil }` on the
  `List`. `BookMyCopySection(item:focus:)` hands the binding to each `AutosavingTextField(focus:field:)`, now generic
  over its field type, with `.details` and `.notes` as fields. The field no longer owns a `@FocusState`. One toolbar
  for the screen means one « OK » for both fields. The field still saves when its focus goes, so « OK » adds no write
  path.
- `ListElementsPage` keeps its toolbar where it was: on the `FormList`, not in a cell, so it already reached the
  keyboard.
- No new string, no Xcode project change, SwiftLint baseline untouched.

## Not done / owed

- **No `Spacing.small` padding.** The task asked for 8 pt around the button through `Spacing.small`. On iOS 26,
  `.padding` or `.sharedBackgroundVisibility(.hidden)` inside the keyboard's `ToolbarItemGroup` made the system drop
  the whole item, and the « OK » disappeared. Both were removed. The gap of about 8 pt now comes from the system's
  glass item. To confirm on a device.
- Seen on the simulator (iPhone 17, iOS 26.4, light): the Fiche livre's Note privée and Commentaire show one
  prominent « OK » and hide the keyboard. Not seen: the Liste's comment (the test account has no list of its own),
  the text saved after « OK », the iOS 18 look, the gap on iOS 18.
- Android untouched. e2e not run.
