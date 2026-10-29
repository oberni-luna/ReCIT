# A list as a cover flow, and adding a book from it

Shipped on 2026-10-29. PRD 0029 and issues 0141 → 0143, deleted once this write-up existed; an autopilot run whose
decision log is summarised below. Mockup: the `Liste détails` section of the Figma file (`843:12721`), its
`Spec · Liste · Cover flow` panel (`848:500`).

## What it does

A list of works or of authors no longer opens on a `List` of rows. It opens in two halves.

- **On top, a cover flow.** The covers sit in a horizontal strip that snaps; the one facing the reader is the
  selection. The others are turned in perspective, their inner edge receding towards the cover in front, pushed aside
  and shaded more with each rank. A list of authors shows portraits in discs. Tapping a turned cover brings it to the
  front; tapping the one in front opens its page. No reflection, no counter.
- **Below, the element facing the reader**: its title and authors (or what inventaire.io says an author is),
  « Mon commentaire » — editable —, « Voir la fiche du livre » / « de l'auteur·ice », « Retirer de la liste », and
  « Ajouté le … » at the foot. Moving to another book **cross-fades** that block while the covers follow the finger.
- **In place of the tab bar**, a bar pinned like a form's: « Ajouter un livre » over « Scanner » and « Rechercher »;
  « Ajouter un·e auteur·ice » over « Rechercher » alone for a list of authors.

**The comment** is written when it is left — the field losing focus, « OK » above the keyboard, or the book swiped
away — optimistically. With the keyboard up the whole screen scrolls under the navigation bar and the add bar steps
aside.

**One book at a time.** Both ways in close on the book added, and the list lands on it.

- **Scanner**: the camera full screen, the recognised book rising with its cover and the round « + » of the inventory
  scanner. « + » adds the edition's work. A collection asks which of its works, with « Toutes les œuvres » last. A book
  the list already holds raises « Ce livre est déjà dans « … » » — « Le voir » lands on it, « Continuer » scans
  another. An edition inventaire.io does not have, or one without a work, is said on the row and nothing more.
- **Rechercher**: a sheet. From three characters, « Dans mes livres et chez mes amis » (five at most), then « Œuvres
  sur inventaire.io » — or « Auteur·ices sur inventaire.io » alone for a list of authors. A small « + » at the right of
  each result adds it; what the list already holds carries a check instead. A copy is added as its work.

## Technical surface

- **`EntityListDetail`** keeps its toolbar, its edit sheet and its pop-when-gone; works and authors lists go to
  **`ListCoverFlowScreen`**, publishers lists keep the old « Cette liste est vide ». The old row views are gone.
- **`ListCoverFlowScreen`** (`Features/Lists/`) — one `ScrollView`: **`ListCoverFlowView`** on top,
  **`ListSelectedItemView`** keyed on the selected uri under `.transition(.opacity)` and a 0.25 s ease, the add bar
  through `formActionBar(isPresented:)`, `.toolbar(.hidden, for: .tabBar)`. The selection is a **uri**, kept across
  changes of the list: the uri an add asked for, else the same one, else the one that took the removed element's place.
- **`ListCoverFlowView`** — a horizontal `ScrollView` with `scrollTargetBehavior(.viewAligned)` and
  `scrollPosition(id:anchor: .center)`; every item laid out `CoverFlowGeometry.pitch` (38 pt) wide, content margins
  centring the ends, `zIndex` following the distance to the selection, a selection haptic.
- **`ListCoverFlowItem`** — the cover or the portrait, posed in `visualEffect` from its frame in the scroll view:
  `scaleEffect`, `rotation3DEffect` (perspective 0.5), `offset`, `brightness`. Keeps `e2e.listItemRow`.
- **`CoverFlowGeometry`** (`Model/CoverFlow/`, pure, tested) — angle up to 55°, push clearing the front cover by
  14 pt, scale down to 0.9, shade 4 % per rank up to four; all but the shade saturate after one pitch.
- **`ListModel.updateComment`** — optimistic through `optimistic(...)`, `/api/lists/update-element`; nothing sent
  for an unchanged text or an element still on its optimistic id (the field is disabled meanwhile). Tested.
- **`ListAddSearchView`**, **`ListAddResultRow`** — the sheet; `InventorySearchRanking` for the local section,
  `SearchModel.searchEntity` with `[.works]` or `[.humans]` after a 300 ms wait, `refreshEdition` when a copy's
  edition does not know its works yet.
- **`ListScanView`**, **`ListScanViewModel`**, **`ListScanResultRow`** — `CodeScannerView`, `CameraAccess`,
  `ScanHintView`, `ScanOverlayPalette`, `ScanResultCoverView`, `ScanResultLabelView` and `BatchScanStateMachine`'s
  lookup half, reused from the batch scanner; `refreshEdition(isbn:, autocreate: true)`.
- **`ListAdditionPlan`**, **`ListWorkOption`**, **`ListWorkChoice`** (`Model/Lists/`) — which uris to send, or which
  to show; tested.
- 34 strings (`list.detail.*`, `list.add.*`), fr and en.

## Notable decisions

- **A real scroll view, not a gesture of our own**: inertia, VoiceOver and the screen's vertical scroll come for free.
  The perspective is SwiftUI's `rotation3DEffect`, truer than the mockup's trapezoids.
- **The selection is a uri**: an element added optimistically changes `_id` when the server answers.
- **No « ajouter en double ».** The user asked for a confirmation offering to add a duplicate, but inventaire.io's
  `PUT /api/lists/add-elements` answers an uri already in the list with `alreadyInList` and creates nothing
  (`listings/add_elements.ts`). The alert says the book is there and offers to land on it; `ListAdditionPlan` never
  sends what the list holds.
- **« Retirer de la liste » is red**, like every removal in the app since the swipes were tinted — the mockup drew it
  green.
- **No « Créer ce livre » from this scanner**: `NewBookFlowView` files the created book into the inventory as well.
- **The comment field has `fixedSize(vertical:)`**: laid out while the block faded in under a title on two lines, it
  kept a clipped height.

## Not done, not verified

- Built; unit suite green (1179 passed, the integration scenario skipped). Seen on the iPhone 17 simulator in light: the
  cover flow, swiping, the cross-fade, a cover without art, the keyboard hiding the add bar, the empty authors list, the
  search sheet, an add from it, a removal, the scanner's preview, an add from it and the « déjà dans » alert. Every
  book added was removed again.
- Not seen: the collection dialog (no collection's ISBN at hand), a comment actually saved, an authors list with
  portraits, dark mode, iOS 18, the iPhone Duo.
- The end-to-end scenario was not run. Its step 22 counts `e2e.listItemRow`, which now marks the covers, of which a
  lazy strip only draws those near the screen.
- The order of a list is still `ordinal`, a string: an element added lands where the server's ordinal puts it.
