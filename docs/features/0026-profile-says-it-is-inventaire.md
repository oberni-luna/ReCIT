# The Profil says the app is inventaire.io underneath

Shipped on 2026-09-27, from the Figma section `Profil · inventaire.io` (`492:13079`), frame
`A · Étiquette sous l'en-tête` (`492:13108`) as the user reworked it. No PRD and no issues: one slice, decided in
an autopilot run whose decision log is summarised below.

## What it does

Nothing in the app said that the books it keeps live on inventaire.io, nor that adding one contributes to a
commons. The Profil now shows, under the account header (and under the invitations when there are some), a paper
tag on the empty shelf's paper:

- **Branché sur inventaire.io**, with a cross beside the title.
- « Ex-libris range vos livres sur **inventaire.io**, une bibliothèque commune, libre et sans publicité. » —
  then the link **Découvrir inventaire.io** (`https://inventaire.io`).
- « Chaque livre que vous ajoutez enrichit ses **données ouvertes** : titres, auteur·ices, éditions, que chacun
  peut réutiliser. » — then the link **Explorer les données ouvertes** (`https://data.inventaire.io`).

The links open in Safari. The cross hides the tag, with an animation, and it never comes back on that device.

## Technical surface

- **`InventaireNoticeTag`** (`Features/Profile/`) — the paper, the title row with the dismiss `Button`
  (`xmark.circle`, icon only, VoiceOver label « Masquer »), the two paragraphs and their links. `.shelfPaper(text:)`
  and `ShelfPalette.labelInk`, like `ListsExplanationTag`.
- **`InventaireNoticeLink`** — a `Link` on the paper: `action300`, underlined, `.borderless` so that inside the
  `List` row only the words take the tap.
- **`ShelfPalette.labelLink`** — new: `color/green/700` in both modes, next to `labelInk`.
- **`ProfileView`** — `@AppStorage("profile.inventaireNotice.dismissed")`; its own `Section`, clear row background,
  `spacing/small` above and below.
- Strings `profile.inventaire.{title,commons,commons.link,data,data.link,dismiss}`, fr and en; bold words are
  Markdown in the string.
- Accessibility identifiers `e2e.profile.inventaire` on the tag and `e2e.profile.inventaire.dismiss` on the cross.
  The end-to-end scenario uses neither.

## Notable decisions

- **Dismissal is per device, not per account.** The tag speaks of the app, not of whoever is signed in, so a
  sign-out (which now wipes the store, feature 0025) does not bring it back. `AppStorage` is the first use in the
  codebase; no model was worth adding for one boolean read by one view.
- **Below the invitations.** An invitation waits on an answer; the tag does not. Figma has no invitation, so the
  question did not arise there.
- **Its own link colour.** The paper is white in both modes; `foregroundTinted` is `green/200` in dark mode,
  invisible on it. Same reasoning as `labelInk`.
- **No way to show it again.** Nothing in the request asked for one; the About-style home for it would be a
  Réglages screen the app does not have.
- **No test.** There is no logic — one boolean. The tag was rendered with `ImageRenderer` in both appearances.

### Divergences from the Figma frame (the code is the source of truth)

| Point | Figma `A` | Code |
|---|---|---|
| Title glyph | `feather` (no SF Symbol) | `books.vertical` — the shared library |
| Lean | −1°, by hand | `ShelfLabelTilt`, ±1° derived from the title |
| Width | 345, narrower than the header card | the row's width, as wide as the cards |
| Chrome | 4-tab bar (cloned frame) | the app's tabs, unchanged |

## Not done / not verified

- Not seen in the running app signed in: built, unit suite green, the tag rendered alone. A pass on a device is
  still owed — in particular that tapping the paper outside the links and the cross does nothing, and the dismiss
  animation inside the `List`.
- The end-to-end scenario was not played (on request only).
- « libre et sans publicité » and « que chacun peut réutiliser » are the frame's wording; the licence of
  inventaire.io's data was not checked against data.inventaire.io.
