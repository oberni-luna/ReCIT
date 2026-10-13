# À propos d'inventaire.io, la version, et un café pour Ex-libris

Shipped on 2026-10-13, from the Figma section `Profil` (`588:17841`): `P1 · Profil · Soutenir & À propos`
(`588:17842`), `P2 · À propos d'inventaire.io · Fond blanc` (`588:17876`) and `PA · Paywall · L'étagère`
(`588:17950`), the paywall the user chose among three. Built in an autopilot run from PRD 0018 and issues 0101
and 0102, all three deleted with this write-up; the decision log is summarised below.

## What it does

**The Profil** opens on a night-green card, above the account:

- « Un café pour Ex-libris ? », « Gratuit et sans pub, grâce à vous. », a chip with inventaire.io's logo saying
  « 50 % pour inventaire.io », and « Faire un don ». The app icon's books on their shelf spill off its right edge.
- The cross in its corner puts it away for good on this device. A donation that goes through does the same.

Between the transactions and « Se déconnecter », a row **À propos d'inventaire.io**. The last line of the screen,
small and centred, reads « Ex-libris · Version 1.3.0 (10) ».

**À propos d'inventaire.io** is a white screen:

- an étagère painted as the inventory paints one, carrying **my three latest books** (fewer if I own fewer, a bare
  plank if none), with a paper tag under the plank: inventaire.io's logo and its name. Nothing on it answers a
  press;
- « La bibliothèque derrière Ex-libris », and « inventaire.io est une bibliothèque commune, libre et sans
  publicité. Ex-libris y range vos livres. »;
- four rows, each glyph in a pale green disc: a shared library, your account is an inventaire.io account, open
  data linked to Wikidata, free software without ads;
- « Aller plus loin », four links outlined by a hairline: inventaire.io, data.inventaire.io, the source code on
  Codeberg, inventaire.io's donation page — all in Safari;
- the app's icon and « Ex-libris est une app indépendante : elle s'appuie sur l'API publique d'inventaire.io. »

**Faire un don** opens a white sheet:

- the icon's books on the watercolour wash, « Soutenir Ex-libris », and a sentence saying every donation is
  shared equally with inventaire.io;
- the 50 / 50 in two equal halves: the app's icon, « 50 % », « Ex-libris » and what it pays for (development,
  hosting, the Apple account); inventaire.io's logo, « 50 % », and what it pays for (the association hosting the
  books and the shared database);
- « Choisir un montant »: three tiles, **un café**, **un poche**, **un grand format** — 3, 5 and 10 € in the
  design — the middle one chosen;
- the small print: a one-off, no subscription, the app whole either way, the App Store's commission;
- « Donner 5 € » pinned under it all, with the chosen tier's price.

After the press: « Merci ! » in place of the form, or « Presque ! » when an Ask to Buy holds the payment, or a red
line over the button if it failed. Backing out of the App Store's own sheet says nothing.

## Technical surface

- **`NavigationDestination.aboutInventaire`** → **`AboutInventaireView`** (`Features/Profile/`), a `ScrollView` on
  `backgroundDefault`. Its parts: `AboutInventaireShelf` (reads the signed-in user, optional),
  `AboutInventaireShelfBooks` (a `@Query` on my `InventoryItem`s, `created` descending, `fetchLimit` 3, drawn by
  **`ShelfBooksView`** at a measured width inside **`OnboardingPlankView`**'s wash and plank),
  `AboutInventaireShelfTag` (`.shelfPaper`), `AboutInventaireValueRow`, `AboutInventaireLinks`,
  `AboutInventaireLinkRow`.
- **`AppIconTile`** (`Features/Components/`) — the icon drawn as a tile: `icon.json`'s cream gradient and the
  `BooksOnShelf` illustration, now also an image asset (600 px, `Assets.xcassets/images/BooksOnShelf`).
- **`AppVersion`** (`Model/Utils/`) — `CFBundleShortVersionString` and `CFBundleVersion` from an Info.plist
  dictionary; **`ProfileVersionFooter`** writes them.
- **`DonationModel`** (`AppModels/Donation/`) — `@Observable @MainActor`, built in `RootView` and injected like the
  others. `loadProducts()`, `priceLabel(for:)`, `donate(_:with:)` (taking SwiftUI's `PurchaseAction`), and a
  `StoreKit.Transaction.updates` listener started at init. `hasDonated` in `UserDefaults`
  (`donation.hasDonated`).
- **`DonationTier`**, **`DonationPrice`**, **`DonationOutcome`** (`Model/Donation/`). Product identifiers
  `studio.lunabee.nouveaurecit.donation.{coffee,paperback,hardcover}`, consumables.
- **`Features/Support/`** — `SupportExLibrisCard`, `SupportSheet`, `SupportIllustration`, `SupportSplitCard`,
  `SupportSplitHalf`, `SupportAmountPicker`, `SupportAmountTile`, `SupportClosingView`, `DonationTier+Caption`.
- **`ProfileView`** — `@AppStorage("profile.supportCard.dismissed")`; the card shows while it is not dismissed and
  `hasDonated` is false. The sheet is `.sheet(isPresented:)` on the tab's stack.
- **`Donations.storekit`** (`ReCIT_iOS/`, outside the synchronised folders so it is not bundled), referenced by the
  `ReCIT_iOS` scheme's run action: the three products at 3, 5 and 10 €, storefront France.
- Strings `about.*`, `support.*`, `profile.about_inventaire`, `profile.version %@ %@`, fr and en.
- Accessibility identifiers `e2e.profile.support`, `e2e.profile.support.donate`, `e2e.profile.support.dismiss`,
  `e2e.profile.about`, `e2e.profile.version`, `e2e.about`, `e2e.support.donate`, `e2e.support.close`,
  `e2e.support.closing`. The end-to-end scenario uses none of them.
- Tests: `AppVersionTests`, `DonationTierTests`, `DonationPriceTests`.

## Notable decisions

- **The paper tag of feature 0026 is gone.** P1 does not have it, and À propos says its two things — the commons,
  the open data — with its two links among four. Its views and its six strings were removed. Two dismissable
  cards stacked over the account would have been one too many.
- **The étagère is the inventory's renderer, bare.** `ShelfBooksView` stands, leans and lays the books exactly as
  an étagère of the same width would — one face-on, two or three as spines with the last leaning. The press
  gestures live in `ShelfRowView`, around it, and do not come along. Its spines fetch a missing page count, as on
  the inventory.
- **Three latest, strictly by date added**, not covers first as `ShelfDrawnBooks` orders an étagère: the request
  was the latest three.
- **Prices come from StoreKit**, never written in the code. `DonationPrice` drops the cents of a whole amount, so
  a 5,00 € product reads « 5 € » as in the design, while 4,99 € keeps them.
- **All three products or none.** If the App Store answers with fewer than three, the sheet says donations are
  unavailable rather than offering a choice the design does not make.
- **Verified or not, a transaction is finished and thanked.** A donation unlocks nothing, so verification guards
  nothing; refusing thanks for money the App Store took would be the one wrong answer.
- **Listening from launch.** `Transaction.updates` only reaches whoever listens, and an Ask to Buy can be approved
  hours later: hence a model built in `RootView` rather than one owned by the sheet.
- **The card goes after a donation.** The app stops asking once someone has given — on this device.
- **SwiftUI's `PurchaseAction`**, not `Product.purchase()`: it knows which scene to show the App Store's sheet over.
- **Equal halves.** Neither half of the 50 / 50 is tinted; the Figma frame tinted the left one at first, and was
  corrected before this was built.

### Divergences from the Figma frames (the code is the source of truth)

| Point | Figma | Code |
|---|---|---|
| P2 shelf | seven hand-painted spines and a pile | my three latest books, painted by the app |
| P2 « données ouvertes » glyph | `feather` (no SF Symbol) | `point.3.connected.trianglepath.dotted` |
| P2 value spacing | 20 pt (off scale) | `spacing/large` |
| PA amounts | « 3 € », « 5 € », « 10 € » written | StoreKit's prices, cents dropped when whole |
| PA small print | reassurance only | reassurance, or « Les dons ne sont pas disponibles » when the store does not answer |
| PA selected tile ink | `foreground/inverse` | `foreground/tinted-inverse`, the primary button's couple |

## Not done / not verified

- **The three products do not exist on App Store Connect.** Until they are created as consumables under the
  identifiers above, a release build shows « Les dons ne sont pas disponibles pour le moment. » and nothing can
  be bought. The simulator, run from Xcode with the `ReCIT_iOS` scheme, uses `Donations.storekit` instead.
- **App Review risk.** Guideline 3.2.2 forbids collecting charitable donations through in-app purchase outside
  3.2.1(vi). Tipping a developer is ordinary; promising that half of it goes to an association may be read as
  fundraising for it. To weigh before submitting — the wording of the card, the tagline and the 50 / 50 is where
  it would bite.
- **Never seen in the running app.** The simulator's session had expired and no sign-in was attempted. The card,
  the À propos content and the sheet were rendered with `ImageRenderer` in both appearances; the shelf with real
  books, the `List` row insets, the sheet's pinned button, a purchase against `Donations.storekit` and the
  thank-you were not seen.
- **No way back to the sheet** once the card is put away. P1 shows none; a permanent row would be the place.
- **Android**: not ported.
- The end-to-end scenario was not played (on request only), nor extended.
- `docs/design-system/figma-library.md` was not updated with this implementation: the file was being edited in
  another session.

### Built with Xcode 27

The run started on an Xcode that could not build the app: `swift-async-algorithms` 1.1.1 fails Xcode 27's region
isolation check, and two files reached `ModelContext` without importing SwiftData under member import visibility.
The pin moved to 1.1.7 (same major), and `ShelfFormView` and `UserDetailView` import SwiftData — a commit of its
own, before this feature's.
