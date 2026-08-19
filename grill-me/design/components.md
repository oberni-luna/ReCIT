# Components — batch scan flow

## Figma instances and their repo counterparts

| Figma instance | Repo counterpart | Status |
|---|---|---|
| `Button / Circular Icon` (`58:2455`, 56×56) | `DesignSystem/ButtonStyles/CircularIconButtonStyle.swift`, used as `.buttonStyle(.circularIcon)` | **exists** |
| `Livre` (`57:2407`, 48×75) | `Components/CellThumbnail` (per the design-system doc's `Shadow/Thumbnail` entry) | exists, size to confirm |
| `tab bar` (`57:2419`) | `Features/MainNavigation/MainTabView.swift` | exists |
| the row as a whole | closest is `InventoryCell` | **similar but not the same** — see below |

## The row is not `InventoryCell`

The mockup's row is cover + title + authors, with the subtitle, the tag and the owner
explicitly **hidden** in Figma. `InventoryCell` carries the tag and owner. So either the row
is a new, leaner view, or `InventoryCell` grows flags to suppress them.

Given the row also needs mode-independent colours (see `tokens.md`) and a trailing 56pt
action button, a separate view is the cleaner read — `InventoryCell` is a list cell for a
light surface, this is an overlay chip for a camera feed. Worth a grilling question.

## The scanner itself

`Features/Search/ScanView.swift` already wraps `CodeScannerView` from the CodeScanner SPM
package:

- `codeTypes: [.ean13]`
- `simulatedData: "9782367935836"` — so the simulator produces a scan without a camera
- `completion:` fires once, then the view **dismisses itself** and hands the raw string up

Presented from `Features/Search/MainSearchView.swift:42`, which turns the result into
`isbn:<code>` and **pushes the book detail screen**. That single-shot, dismiss-and-navigate
behaviour is exactly what the batch flow replaces: the scanner must stay mounted, and the
result must land in the overlay rather than on a pushed screen.

Open: `CodeScannerView` will re-fire continuously on the same barcode while it stays in
frame. The batch flow needs debouncing per code, which the current single-shot usage never
had to solve.
