---
issue: 146
status: to-close
wiki: [[0060-list-cover-flow]], [[0007-batch-scanner]]
note: Aqua (ISBN 979-10-329-3202-5) scanned from a Liste said « Cette édition n'existe pas sur inventaire.io »; the inventory scanner then found it, and a second list scan worked.
created: 2026-11-16
---

## Context / Decisions

- **Bug.** A Liste's scanner (« Ajouter un livre › Scanner ») can say a book does not exist when the lookup only failed.
  - Both scanners call `EntityModel.refreshEdition(uri: "isbn:…", autocreate: true)` under a 10 s watchdog.
  - Only `ListScanViewModel.lookUp` also requires `edition.works` to be non-empty. Those works come from `resolveEditionWorks`, which swallows errors (`try?`).
  - Timeout, unknown edition, thrown error and edition without a work all land in `.notFound`. The row then says « Cette édition n'existe pas sur inventaire.io ».
  - `BatchScanStateMachine.isReplaceable` keeps the same barcode gated in `.notFound`: rescanning the book does not retry. The reader has to close the scanner.
  - Diagnosed on 2026-11-16: the same list scan worked once the cache was warm. Transient failure on the cold path, not a deterministic bug.
- **Fix: a « Réessayer » on the list scanner's failed row.** It runs the whole lookup again on the same code. No change to `EntityModel` or `resolveEditionWorks`: the book screen, Recherche and the duplicates screen share them.
- **Copy:** the failed row says « Introuvable pour l'instant » (en: « Not found for now ») under the ISBN, instead of `edition.no_result`.
  - The button is round like the « + », in its place, icon `arrow.clockwise`, labelled « Réessayer » / « Try again » for VoiceOver.
  - New keys under `list.add.*`. `edition.no_result` stays for the inventory scanner.
- **State machine:** a new `BatchScanEvent` moves `.notFound(code)` to `.lookingUp(code)` for that same code only. Refused from every other state. The inventory scanner never sends it.
- **Out of scope:**
  - The inventory scanner, whose failed row offers « Créer ce livre » even on a timeout: #154.
  - Android, same gap in `ListScanSession.kt`: #155.
  - Longer watchdog, parallel requests, telling causes apart: speculative, a retry is enough.

## Acceptance criteria

- List scanner, lookup fails (timeout, unknown edition, or edition whose work did not resolve) → the row shows the ISBN, « Introuvable pour l'instant », and a round « Réessayer » button. No « + ».
- Tap « Réessayer » → the row goes back to its loading look, and the same ISBN is looked up again.
- Retry resolves → the row shows the book and its « + ». Adding it works as before, including the choice between several works and the « déjà dans la liste » alert.
- Retry fails again → the same failed row, with « Réessayer » still there.
- A different barcode still replaces the failed row. The same barcode held in frame still does not relaunch the lookup by itself.
- Inventory scanner unchanged: same text, same « Créer ce livre ».
- VoiceOver reads « Réessayer » on the button. The button has the accessibility identifier `e2e.list.scan.retry`.
- Tests:
  - `BatchScanStateMachine`: the retry event moves `.notFound(code)` to `.lookingUp(code)`. It is refused for another code and from every other state.
  - `ListScanViewModel` with `MockURLProtocol`: the first work fetch fails → `.notFound`. Retry with the work answering → `.resolved` with that work offered.

## Implementation

- `BatchScanEvent.retried(code:)`: `BatchScanStateMachine.retry(code:)` moves `.notFound(code)` to `.lookingUp(code)` for that code only, refused elsewhere.
  - `apply` is pinned at complexity 17 by the SwiftLint baseline: the case delegates to a helper, and `.cleared` returns `state.showsRow` instead of a guard (same behaviour).
- `ListScanViewModel.retry(entityModel:modelContext:)`, sharing `startLookUp` with `codeSeen` (soft haptic, `works` emptied, task relaunched). `lookupTask` is `private(set)` for tests.
- `ListScanResultRow`: in `.notFound`, a round `arrow.clockwise` « Réessayer » (`e2e.list.scan.retry`) replaces the « + »; caption `list.add.not_found`. Identifiers in `AccessibilityID`.
- `ScanResultLabelView.notFoundCaption(_:)`, default `edition.no_result`: the inventory scanner is unchanged.
- Strings `list.add.not_found` (« Introuvable pour l’instant » / « Not found for now »), `list.add.retry` (« Réessayer » / « Try again »).
- Tests: 4 in `BatchScanStateMachineTests`, new `ListScanViewModelTests` (3, `MockAPIService`): failed work fetch → `.notFound`, retry → `.resolved` with the work; retry failing again; same barcode does not relaunch.
- Proof: app build green (SwiftLint included); `ReCIT_iOSTests` 1342 passed, 0 failed.
- Left: the `accessibility_id_constant` baseline entry for `ListScanResultRow.swift` is now stale (literal moved to a constant); can be deleted from `.swiftlint.baseline`.

## Review

Round `validation` (lenses: style ✓ · elegance ✓ · structure ✓ · correctness ✓)
- 🟡 [correctness] `ListScanViewModel.lookUp` applied a cancelled lookup's result: after a retry on the same code, a late `.lookupFailed` could flip the new `.lookingUp` and cancel it → fixed: `guard Task.isCancelled == false` before every result. No test: would need a fetch hold and an injectable timeout for tests only (yagni).
- 🟡 [style] `ScanResultLabelView`: blank line between access subgroups → fixed.
- 🟡 [style] stale `accessibility_id_constant` baseline entry for `ListScanResultRow.swift` → removed (4145 → 4144 entries).
- Re-verify: clean. Autofix changed code after the user's device test (the cancellation guard).

## Verification

manual validation — not run by agent

## Feedback
