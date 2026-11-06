---
issue: 9
status: todo
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

## Review

## Verification

## Feedback
