---
issue: 89
status: todo
wiki: [[features/0075-lens-tabs-and-a-lists-pager]], [[features/0086-a-friends-transactions-tab]], [[features/0045-running-on-ios-18]]
note: "sur iOS 18, notre tab bar ne marche pas bien. Il faut enlever le \"liquid glass\" et les effets de zoom sur iOS 18." Screen recording on an iPhone 16 Pro (iOS 18), 2026-11-07, kept locally (~/Desktop/Screen Recording iPhone 16 Pro 07-11-2026 at 17.26.57.mp4).
created: 2026-11-07
---

## Context / Decisions

> sur iOS 18, notre tab bar ne marche pas bien. Il faut enlever le "liquid glass" et les effets de zoom sur iOS 18.

- **"Tab bar" = the row of tabs at the top**, `LensTabPicker` (`Features/Components/LensTabPicker.swift`), not the system `TabView`. Seen in the recording on a friend's profile (Inventaire • 2 | Listes • 2 | Échanges • 0 | Présentation). The same component draws a Liste's (`ListDetailTabPicker`) and an étagère's (`ShelfDetailTabPicker`) tabs: the fix covers all three.
- **What the recording shows on iOS 18:**
  - the lifted capsule's magnified word is drawn off the capsule: « Lists • 2 » rises above it, cut in half;
  - the `.regularMaterial` capsule, `glassCapsule()`'s fallback, is barely visible on the dark profile ground (`gray/800`);
  - the ×1.2 magnification doubles letters while the capsule moves between two words.
- **iOS 26+ unchanged.** Glass, lift and magnification stay as they are. Everything below is behind `#available(iOS 26.0, *)` failing.
- **No zoom below iOS 26.** The capsule is not lifted (`liftScale` 1) and the words under it are not magnified (`magnification` 1).
- **The drag stays.** The capsule is still picked up, follows the finger, rubber-bands and settles; only the zoom goes. Tap, haptic ticks and following the pager are unchanged.
- **Capsule fill below iOS 26 = `backgroundDisable`** (white at 10 % in dark, `gray/200` in light), instead of `.regularMaterial`. A veil, so it reads on the profile's, the Liste's and the étagère's grounds alike. `glassCapsule()` (`DesignSystem/Extensions/View+glass.swift`) has no other caller: its fallback changes there.
- Out of scope: the system tab bar, the two-colour word while the capsule sits between two words (intended, as on iOS 26).

## Acceptance criteria

- iOS 18 simulator, friend's profile, dark: the selected tab's capsule is visible, a light grey capsule behind the word.
- iOS 18, light: the capsule is visible, `gray/200` behind the word.
- iOS 18: pressing and dragging the capsule moves it under the finger with no growth of the capsule and no enlarged words; released, it settles on a word and the page turns.
- iOS 18: at no point is the selected word drawn outside the capsule or cut (the « Lists • 2 » lifted above the capsule in the recording).
- iOS 18: same on a Liste's Livres | Présentation and an étagère's tabs.
- iOS 26+: glass capsule, lift ×1.15 and magnification ×1.2 exactly as before.

## Implementation

## Review

## Verification

## Feedback
