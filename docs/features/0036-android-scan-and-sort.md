# Scanning and sorting books, on Android

Shipped on 2026-10-16, from PRD 0020 and issues 0115–0117, in an autopilot run, on the
`android-scan-sort` branch. Two flows that 0031 left out of the Android port now exist there, taken
from the iOS app:

- the batch scanner of [0007](0007-batch-scanner.md);
- « Ranger mes livres » of [0010](0010-grid-shelf-sorting.md) and [0032](0032-sorting-save-and-leave.md).

The automatic proposal of [0008](0008-ai-auto-sort.md) is not ported. The PRD and the issues were
scaffolding and were never committed.

## What it does

- **One flow, two doors** ([ADR 0007](../adr/0007-modal-sorting-flow.md)). It covers the whole
  screen, navigation bar included, and has its own back stack.
  - It opens at the camera from:
    - « Scanner » in the Inventaire toolbar;
    - the empty-shelf card's « Scanner » tag.
  - It opens at the sorting surface from:
    - « Ranger » in the toolbar, shown once the inventory has synced;
    - the card's « Ranger mes livres » tag, when there are books but no étagère.
- **Scanning.** The camera stays open and EAN-13 barcodes are read continuously.
  - A recognised book rises from the bottom with a tick: cover, title and authors. The round « + »
    files it, the row confirms with ✓ and clears, and the camera waits for the next book.
  - Other outcomes say so on the row:
    - a book already in the inventory says « Dans mon inventaire » and refuses the add;
    - a code inventaire.io does not know says « Cette édition n'existe pas sur inventaire.io »;
    - a lookup that runs past ten seconds says the same;
    - a failed add puts a snackbar above the camera and leaves the « + » to tap again.
  - With nothing recognised, the same slot says what to point the phone at.
  - Tapping the row's text opens the book's screen inside the flow; coming back finds the session as
    it was.
  - « Terminer », or the back gesture, ends the session.
- **The camera permission** is asked as the flow opens.
  - A first refusal shows the explanation and « Autoriser l'appareil photo ».
  - A refusal the system will no longer ask about shows « Ouvrir les paramètres ». Coming back from
    the settings re-reads the permission.
- **The bilan.** It replaces the camera when the session added books and the user owns no étagère.
  - It shows « N livres ajoutés », « Ils ne sont sur aucune étagère. », and the covers standing on a
    plank.
  - « Ranger mes livres » opens the surface; « Continuer sans ranger » closes.
- **Sorting.**
  - The étagères are cards on a grid of three columns, or two for two étagères or fewer. Each card
    shows:
    - a fanned pile of its first covers;
    - « nom · n »;
    - a « Nouvelle » or « Modifiée » pill.
  - The grid ends on a « + Nouvelle étagère » tile.
  - The books on no étagère sit in a panel anchored at the foot, over the grid. The panel holds:
    - « Livres à ranger · n » and a one-row carousel;
    - « Annuler » (an undo glyph) and « Enregistrer »;
    - a footer: idle, the recap in words, or a run's report.
- **Moving a book.**
  - A long press on a cover lifts it, and the finger carries it over everything. Letting go files it
    into the target underneath: a card, the panel, or the tile.
  - On the tile, the étagère's name is asked first, then the étagère is created holding the book.
  - A tap on a book in the panel opens « Ranger dans… ». It lists every étagère, drafts included, and
    « Nouvelle étagère ».
  - TalkBack gets the same choices as custom actions. On a card it gets « Retirer X de cette étagère »
    for the book on top.
  - A card opens the étagère as it will be, where a swipe takes a book back to the panel.
- **Saving.** Nothing is written before « Enregistrer ». While it writes:
  - the étagères still to land dim and breathe;
  - the one being written carries a spinner;
  - one that fails keeps a warning badge, and the snackbar names it;
  - the footer counts down, then says what landed. After a stop it gives the three-part account, and
    a second « Enregistrer » sends only the rest.
- **Leaving.**
  - « Annuler » throws the changes away, asking first when there is more than one.
  - The cross asks « Quitter sans enregistrer ? » over unsaved changes, until answered « Quitter »
    once on this device.
  - Closing keeps the draft, which is found again on return. Signing out or deleting the account
    clears it.

## Technical surface

- **Dependencies:**
  - CameraX 1.6.2: `camera-camera2`, `camera-lifecycle`, `camera-view`;
  - ML Kit `barcode-scanning` 17.3.0, the bundled model, so no Play Services download.
  - The manifest asks for `CAMERA`, with the camera feature not required.
- **`data/scan/`**, pure: `BatchScanStateMachine`, `BatchScanState`, `BatchScanEvent`, `ScannedBook`.
  - Ported from Swift with its injected clock and every case of its suite, except creation — which
    [0037](0037-android-create-a-missing-book.md) brought back.
  - `InventoryDao.countOwned(editionUri, ownerId)` is the ownership check.
- **`data/sorting/`**, pure, ported from `Model/Sorting/`: `SortSnapshot`, `SortSectionId`,
  `SortChange`, `SortProjection`, `SortWritePlan`, `SortApplyLedger`, `SortApplyLanding`,
  `SortApplyFailure`, `SortDraftNameRule`, `SortName`, `SortLeaveConfirmation`, `SortFooter`,
  `SortPile`, `SortGridMetrics` and `DeterministicTilt`.
  - `DeterministicTilt` gives iOS's exact numbers.
- **`SortSession`** and **`SortSessionState`**: app-scoped, built in `AppContainer`, a `StateFlow` of
  one immutable state.
  - `SessionCoordinator` resets it on sign-out and on account deletion.
  - `ShelfRepository` gained `createShelfNow`, `addItemsNow` and `removeItemsNow`. They wait for the
    server and reconcile membership from its answer.
- **`ui/flow/`**:
  - `SortFlowPresentation`: one flag, `presentScanning()` and `presentSorting()`, provided as
    `LocalSortFlow`.
  - `SortFlowHost`: a `NavDisplay` over its own `NavBackStack`, which takes `FlowDestination` keys
    (camera, bilan, surface, étagère) and the app's destinations.
  - `MainScaffold` draws the host above its `Scaffold` and moves the snackbar onto it.
- **`ui/scan/`**: `ScanViewModel`, `ScanCameraScreen`, `BarcodeCameraPreview` (CameraX with an ML Kit
  analyzer), `ScanResultRow`, `CameraAccess` and the permission screen.
- **`ui/sort/`**:
  - `SortSurfaceScreen`, `SortShelfCard` (pile and tile), `SortUnshelvedPanel` (panel, book card,
    action bar, footer), `SortShelfScreen`, `SortNewShelfDialog`, `ScanTallyScreen`;
  - the drag: `SortDragState`, `sortDragSource`, `sortDropTarget`, and `SortDropZones` (pure).
- **Shared code changed:**
  - `RecitTopBar` takes a `navigationIcon` for a screen whose way out is not « Retour »;
  - `EmptyShelfCard` and its paper tag take an icon, a scan and a sort action;
  - the error snackbar words a `SortApplyFailure` with the étagère's name.
- **Strings:** `strings_scan.xml` and `strings_sort.xml`, French values of `Localizable.xcstrings`.
- **Tests:** 252 JVM tests, all green:
  - the scan machine;
  - the ten sorting suites ported from iOS;
  - the footer's order;
  - the drop zones.

## Decisions worth knowing

- **The dependencies came with the request.** 0031 had left the scanner out for want of a barcode
  reader. Google's Code Scanner was ruled out: it is a single-shot activity, and the batch is the
  feature.
- **The flow is drawn by `MainScaffold`, not by an `AppContainer` object.** The PRD put the flag in
  the container; a `CompositionLocal` provided by the shell does the same with less reach, and only
  composables ever raise it.
  - Its back stack is not saved. After a rotation, the flow reopens at its start route.
  - The sorting draft survives a rotation, because it lives in `SortSession`, not in the flow.
- **The snackbar draws above the flow**, unlike iOS, where it stays underneath (ADR 0007, a
  consequence). A failed add and a failed étagère are read where they happen.
- **The tabs stay composed under the flow**, as on iOS. A full-screen pointer catcher keeps touches
  off them, and their semantics are cleared, so TalkBack cannot wander behind the flow.
- **The drag is the app's own, not Android's drag-and-drop.**
  - A long press starts it, so a carousel still pans and a card still taps.
  - The book is carried as an id; its origin is read from the projection at the drop, as on iOS.
  - Targets report their visible bounds. The panel's layer wins where it overlaps a card, so a book
    let go over a card seen through the panel goes back to « à ranger ».
- **A tap on a book opens « Ranger dans… »**, where iOS does nothing and offers the list to
  VoiceOver only. With a drag that starts on a long press, a visible menu is the obvious second way.
- **Two refusals of the camera, not « denied » and « restricted ».** Android has no device
  restriction to explain, but it does stop asking after a second refusal. Only that one gets the
  route to the settings, the counterpart of iOS's rule.
- **The scan surface's sentences were adapted.** The permission screen speaks of « paramètres », and
  the sort tag's detail says « en les glissant sur des étagères ». iOS's « avec un peu d'aide » points
  at a proposal that does not exist here.
- **The bilan has no automatic-sorting paragraph.** It uses iOS's « unavailable » body and its two
  actions.
- **One departure from iOS in the model.** A run that landed whole gives way to the recap at the next
  change. On iOS the finished report outranks the recap until the screen is left, so a second round
  of changes is never summed up.
- **`moveBook` and `createShelf` do nothing until the snapshot is frozen.** iOS has no such guard.
- **`reset()` bumps a generation.** A sync still running at sign-out cannot write the previous user's
  library back.

## Not done, or not verified

- **Never run.** The three commits build and their 252 unit tests pass. Lint shows no new issue in
  the touched files. But no screen of either flow has been seen on a device or an emulator.
  - Like the rest of the Android app (0031), nothing has run signed in.
  - The camera, ML Kit's reading speed, the haptics and the permission screens need a phone.
  - The drag, the panel's gradient and the grid's layout at 360 and 411 dp need eyes.
- **Not ported:**
  - creating a book from an unknown scan (0020) — ported later, in
    [0037](0037-android-create-a-missing-book.md);
  - the automatic proposal (0008);
  - the tips (0015);
  - the variable blur under the panel;
  - the landing bounce of covers;
  - targeting an étagère for a scanning session.
- **Autoscroll while dragging** does not exist. A book can only be dropped on a card already on
  screen, or filed through « Ranger dans… ».
- **No test covers `SortSession`, `ScanViewModel` or any screen.** They need Room, the network or
  Compose UI tests, none of which the Android project has.
- **The membership gate is not ported.** iOS stops concurrent syncs while a write is in flight. Here
  every write reconciles from the server's answer, and a sync landing in between could briefly show an
  older membership.
