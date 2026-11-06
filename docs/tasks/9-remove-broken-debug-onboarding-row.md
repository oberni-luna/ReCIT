---
issue: 9
status: to-close
wiki: [[testing]]
note: migrated from docs/issues/0089 — « Ouvrir l'onboarding scan » presents nothing
created: 2026-11-06
---

## Context / Decisions

> Le bouton « Ouvrir l'onboarding scan » de la section Debug du profil met `isPresentingWelcome` à
> `true`, et le `fullScreenCover` attaché à la `Section` ne s'ouvre pas. L'écran ne bouge pas.
> Sa voisine, « Ouvrir l'onboarding auto-sort », fonctionne — même `Section`, même mécanisme.
> La ligne debug reste néanmoins le seul moyen pour un testeur de revoir l'accueil sans vider sa
> bibliothèque. (issue 0089, 2026-09-11)

- **Premise wrong:** the row is not the only way back to the accueil. « Rejouer l'accueil en situation », in the same section since 2026-08-20, resets the answer and sets `onboarding.forcesWelcome`; the real gate then presents the accueil and its scanner through the real wiring.
- **Decision (Olivier, 2026-11-06):** remove the broken row instead of diagnosing it. Debug scaffolding, duplicated by a row that works; the probe the issue asks for (XCUITest, e2e account, scheme edits) costs far more than the row is worth.
- **Remove from `Features/Profile/ProfileDebugSection.swift`:**
  - the « Ouvrir l'onboarding scan » `Button` and its `e2e.debug.scanOnboarding` identifier;
  - its `fullScreenCover(isPresented: $isPresentingWelcome, …)`;
  - `isPresentingWelcome`, `scanWasChosen`, `openScannerIfChosen()`;
  - any comment that only describes them. The file header's other claims stay true; fix wording that names the removed row.
- **Keep:** « Ouvrir l'onboarding auto-sort » and its cover, « Rejouer l'accueil en situation », « Réafficher les astuces », the state line.
- **e2e:** nothing uses `e2e.debug.scanOnboarding` any more; the historical comment in `UITests/E2EScenarioTests.swift` (~line 196) stays as is.
- **Type:** `refactor` — `#if DEBUG` only, no change in a Release build.

## Acceptance criteria

- [ ] Profil → Debug section shows no « Ouvrir l'onboarding scan » row.
- [ ] `grep -rn "e2e.debug.scanOnboarding\|isPresentingWelcome\|scanWasChosen" ReCIT_iOS --include='*.swift'` finds only the comment in `UITests/E2EScenarioTests.swift`, if anything.
- [ ] « Ouvrir l'onboarding auto-sort » still opens the bilan.
- [ ] « Rejouer l'accueil en situation » then closing the Profil → the accueil shows; « Scanner mes livres » opens the scanner.
- [ ] Debug build succeeds, SwiftLint clean.

## Implementation

- `ReCIT_iOS/Features/Profile/ProfileDebugSection.swift`: removed the « Ouvrir l'onboarding scan » button and its `e2e.debug.scanOnboarding` identifier, `isPresentingWelcome`, `scanWasChosen`, the `fullScreenCover` presenting `OnboardingWelcomeView`, `openScannerIfChosen()` and the comments describing them. « the two rows above » → « the row above » in the kept comment of « Rejouer l'accueil en situation ».
- Kept: `sortFlow` (still used by the auto-sort cover), `OnboardingWelcomeView` (still used by `OnboardingWelcomeModifier`).
- `ReCIT_iOS/.swiftlint.baseline`: stale `accessibility_id_constant` entry for the deleted identifier removed (baseline shrinks by one).
- No catalogue key to remove: debug rows are not translated.
- Acceptance grep returns nothing.
- Proof: Debug build ✅ (SwiftLint in the build).

## Review

### Round `validation` — 2026-11-06

Scope: `origin/main..wa/9-remove-broken-debug-onboarding-row`. LENSES: style ✓ · elegance ✓ · structure ✓ · correctness ✓.

- 🟡 `ProfileDebugSection.swift:102` — [style] the comment above « Rejouer l'accueil en situation » still contrasted it with a button that no longer exists → **fixed** (comment only).
- Round 2: ✅ review clean.
- Checked: baseline shrinks by exactly one entry; acceptance grep finds only the historical comment in `UITests/E2EScenarioTests.swift:196`; no dead code left.
- Wiki: nothing describes the removed row as existing; no page changed.

## Verification

PM on the simulator (iPhone 17, iOS 26.4, merged build):
- ✅ Profil → Debug shows « Ouvrir l'onboarding auto-sort », « Rejouer l'accueil en situation », « Réafficher les astuces » and the state line; no « Ouvrir l'onboarding scan ».

Still yours: « Ouvrir l'onboarding auto-sort » opens the bilan; « Rejouer l'accueil en situation » → « Scanner mes livres » opens the scanner.

## Feedback
