# 0045 — Ex-libris on iOS 18

Shipped on 2026-10-23 as version 1.5.0 (build 13), in two commits: « Run from iOS 18, as version
1.5.0 », then « Finish running on iOS 18 » for what the first had not caught. No PRD, no issues, no
mockup. The request was the owner's: make the iOS app compatible with iOS 18.

Two sessions did the work in parallel without seeing each other — one on `feat/ios18-support`, one
on `ios18-compat` in a worktree. The owner kept the first as the base; the second contributed the
four `ForEach`, the 18.1 symbol, the title of « Chez mes amis » and this document. `ios18-compat`
was not merged.

## What it does

**The app installs and runs from iOS 18.0**, where it asked for iOS 26.0. On iOS 26 and later
nothing changes. On iOS 18 the app wears the system's own iOS 18 look, and one feature is missing:

- **No proposal from Apple Intelligence.** « Ranger mes livres » asks the on-device model of
  `FoundationModels` for étagères, and that framework only exists from iOS 26. On iOS 18 the app
  answers as it does on a device that cannot run Apple Intelligence: the proposal's button and the
  settings entry are hidden, the bilan after a scan offers to sort by hand, and the empty shelf's
  card leads into the flow, which says « Le rangement automatique n'est pas disponible sur cet
  appareil. » Sorting by hand is untouched.
- **No Liquid Glass.** My avatar at the top left sits on a material circle instead of a pane of
  glass; the bars draw nothing behind their items, as iOS 18 bars never do; the « Fermer » of the
  full-screen cover is a bordered button.
- **« Chez mes amis » keeps the inset** of the sections around it in Recherche, instead of running
  its covers to the screen's edges, and its title lines up with theirs.
- **The buttons under a group's header** keep the list's own insets, above and below too.
- **On iOS 18.0 only**, a requested exchange is drawn with `questionmark.bubble.fill`:
  `questionmark.message.fill` arrived in 18.1.

## Technical surface

- **`project.pbxproj`** — `IPHONEOS_DEPLOYMENT_TARGET = 18.0` everywhere, `MARKETING_VERSION =
  1.5.0`, `CURRENT_PROJECT_VERSION = 13`.
- **`DesignSystem/Extensions/View+glass.swift`** — `glassButtonStyle()` (`.glass`, else
  `.bordered`) and `interactiveGlassCircle()` (glass, else `.regularMaterial` in a circle), for
  `FullScreenCoverView` and `ProfileAvatar`.
- **`DesignSystem/List/View+listMargins.swift`** — `listRowVerticalInsets(_:)` and
  `listSectionHorizontalMargins(_:)`, the iOS 26 per-edge forms, and the list's own below it; for
  `GroupDetailView` and `SearchFriendsSection`.
- **`ProfileToolbarItem`** — `sharedBackgroundVisibility(_:)` behind `#available(iOS 26.0, *)`.
- **`AutoSortModel`** — `availability` returns `.deviceNotEligible` below iOS 26; `proposePlan`
  returns a plan that proposes nothing there (unreachable: no entry point calls it); the two phases
  and their `GenerationOptions` are `@available(iOS 26.0, *)`, and the options became computed.
  **`AutoSortTaxonomyDraft`** and **`AutoSortMappingDraft`** are `@available(iOS 26.0, *)`.
- **`SearchFriendsSection`** — the title's padding is `medium` from iOS 26, where the section gives
  its margins up, and `zero` below.
- **`ListCoverFan`, `OnboardingSettlingBooksView`, `AboutInventaireLinks`, `SortShelvesGridView`**
  — `ForEach(Array(x.enumerated()), …)`.
- **`TransactionState+UI`** — the requested state's symbol behind `#available(iOS 18.1, *)`.
- **`claude.md`** — the target, the wrappers, the iOS 18 simulator's own build, and the
  enumerated-sequence rule inverted.

## Notable decisions

- **The compiler is the inventory.** With the target lowered, the app built for an iOS 18.6
  simulator with `-IDEBuildingContinueBuildingAfterErrors=YES` names everything newer than iOS 18:
  FoundationModels in three files, three glass modifiers, two list margins.
- **The warnings mattered more than they looked.** `EnumeratedSequence` is a
  `RandomAccessCollection` only from iOS 26, so `ForEach(x.enumerated())` — which `claude.md`
  recommended — leans on a conformance the iOS 18 Swift runtime does not have. The targets compile
  in the Swift 5 language mode (`SWIFT_VERSION = 5.0`), where this is a warning; in Swift 6 it is
  an error. The first commit left it; the second wraps the four sites in `Array(...)`, and the rule
  in `claude.md` now says so.
- **SF Symbols were checked separately**, since a missing symbol compiles and draws nothing. Every
  string literal of the app that names a symbol (59 of them) was looked up in the system's
  `CoreGlyphs.bundle/…/name_availability.plist`: one is newer than iOS 18.0.
- **The fallbacks are iOS 18's own look, not an imitation of glass.** A material circle and a
  bordered button are what iOS 18 puts in those places. The wrappers keep `#available` out of the
  screens.
- **No new unavailability reason for auto-sort.** Below iOS 26 the user can do nothing in the app
  to get the model, which is the ineligible device's treatment; its sentence (« pas disponible sur
  cet appareil ») is true there. A reason saying « mettez iOS à jour » would have needed copy in
  two languages and a fifth case in `AutoSortEntryPoint`.
- **`FoundationModels` is weak-linked without asking.** Every symbol the app uses from it is
  annotated iOS 26, so the linker emits `LC_LOAD_WEAK_DYLIB` (checked with `otool -l`); iOS 18
  launches without the framework.
- **An iOS 18 simulator needs its own build.** Xcode only embeds `libswiftCompatibilitySpan.dylib`
  when the build's destination lacks `Span`; a build for an iOS 26 simulator installed on an iOS 18
  one dies at launch. A generic-device or archive build embeds it.

## Owed, and known

- **The end-to-end scenario on iOS 18.6: 22 OK, 5 KO, 1 not played**, run on `ios18-compat` with
  `OlivierB_test4` before the merge — same behaviour, other wrapper names. Not yet diagnosed:
  - « Recherche 1 » opened a book's page and stayed there, so « Recherche 2 » and « 3 » never
    found the field;
  - after the étagères were deleted, a full-screen « Vos livres, sur vos étagères » covered the
    tab bar, so the books could not be deleted and the sign-out never happened. The two books it
    scanned are still on the account.
- **Seen on the iPhone 16 Pro simulator, iOS 18.6**: launch, the wall of covers, « Se connecter »,
  « Créer un compte », and through the scenario the inventory, the scanner, « Ranger mes livres »
  and the lists. On iOS 18 the navigation bar is the system's: a « Back » label and a hairline.
- **Unseen on iOS 18**: Réseau and a group's buttons, « Chez mes amis », the avatar's material
  circle, the full-screen cover's bordered « Fermer », exchanges, TipKit's cards, the donation
  sheet.
- **iOS 18.0 to 18.5 not run**: only 18.6 has an iPhone runtime on the Mac. **No real device on
  iOS 18**; the build ran on an iPhone 18 Pro on iOS 27.2.
- **Unit tests**: 848 passed, 1 skipped (the integration suite), on iOS 18.6 and on iOS 26.5.
- **Figma** draws iOS 26 only; the iOS 18 fallbacks have no frame.
- **Android** (`Recit_Android/`) is not concerned.
