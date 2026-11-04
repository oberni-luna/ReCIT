# The end-to-end scenario, on Android

Shipped on 2026-10-30. The iOS scenario ([0012](0012-end-to-end-scenario.md)) ported to `Recit_Android/`: one
command plays the whole app on an emulator, against the real `inventaire.io`, and leaves the same compte-rendu — one
row per step, a screenshot, what the step acted on, **OK / KO / non joué**.

```sh
scripts/e2e-android.sh
```

It asks for the test account's password, finds or starts an emulator, builds and installs the debug app and the
runner, plays the scenario, and opens `build/e2e-android/<timestamp>/report.html`. The HTML is rendered by the iOS
run's own `scripts/e2e_report.py`: the Android runner writes `report.json` in the same shape.

## The journey

The iOS one, step for step, wherever Android has the screen:

1. launch on wiped data and sign in;
2. **kill the process and start it again — still signed in** (non-critical; a lost session is signed in again so
   the steps behind it are still played);
3. open the scanner and scan the iOS scenario's two books, « Lucioles » (`9782370493002`) and « Penss et les plis du
   monde » (`9782413013518`), then « Terminer » — answering the bilan with « Continuer sans ranger » when it shows;
4. four searches from Recherche: « Dans la forêt », a friend's copy among the local results, opened; then one per
   suggestion under « Chercher sur inventaire.io » — « Auteur·ices contenant » for Victor Hugo (into the author's
   works), the query as typed for Virginia Woolf, « Livres contenant » for « Des souris et des hommes » — each adding
   a book through the book screen's « … » › « Ajouter à l'inventaire »;
5. « Autres éditions » from the first book of the inventory;
6. « Ranger mes livres »: two new étagères, a book **dragged** onto each, « Enregistrer », the cross;
7. a list from the Listes tab's « + », two works put in it from their book screen's « … » › « Liste », its row
   checked for « 2 œuvres »;
8. delete all of it — the list by a swipe, each étagère from « Modifier » › « Supprimer l'étagère », **every** book
   of the inventory from its « … » — and sign out from the profile.

Names carry a timestamp (`E2E Romans 1030-130831`), as on iOS. The account defaults to `OlivierB_test4`.

The iOS step for the first-launch cover has no counterpart: Android has no accueil, the empty inventory draws its
first-steps card in the page.

## How to run it

```sh
scripts/e2e-android.sh                          # prompts for the password
E2E_PASSWORD=… scripts/e2e-android.sh           # non-interactive
E2E_AVD=Pixel_8_API_35 scripts/e2e-android.sh   # which AVD to start when none is running
E2E_RESET_ACCOUNT=1 scripts/e2e-android.sh      # empty the account first (scripts/e2e_reset_account.py)
E2E_SKIP_BUILD=1 scripts/e2e-android.sh         # reuse the APKs already installed
E2E_SERIAL=emulator-5556 scripts/e2e-android.sh # which device; by default the first emulator, never a phone
```

**Working on the scenario itself** does not need the password, nor a sign-in each time — inventaire.io rate-limits
those. Once the app on the emulator is signed in (a first run, or by hand), play it on that session:

```sh
adb shell am instrument -w -r -e e2eKeepSession true \
  -e class studio.lunabee.nouveaurecit.e2e.E2EScenarioTest \
  studio.lunabee.nouveaurecit.e2e/androidx.test.runner.AndroidJUnitRunner
```

The data is not wiped, « Connexion » reports « déjà connecté·e », and « Déconnexion » is skipped. The report is then
at `/sdcard/Android/data/studio.lunabee.nouveaurecit.e2e/files/e2e-report/`, for `adb pull`.

Two more arguments play part of the journey. `-e e2eOnly <text>` plays only the steps whose title holds it (launching
and signing in are always played), and `-e e2eStamp <MMdd-HHmmss>` reuses a run's timestamp — together they finish
the cleanup of a run that died halfway: `-e e2eOnly "Suppression\ de\ l\'étagère" -e e2eStamp 1030-151056`.

## Technical surface

**Runner** — `Recit_Android/e2e/`, a `com.android.test` module, **self-instrumenting**: it runs in its own process
and drives the app from outside with UI Automator, the way XCUITest drives the iOS app. A test in
`app/src/androidTest` would live in the app's process and die with it, and step 2 kills the app.

- `E2EScenarioTest` — the journey, one `driver.step` per line of the report.
- `E2EDriver` — `step` (a throw is a KO with its reason; `critical` turns the rest into SKIP), `waitFor`,
  `waitForAny`, `waitUntil`, `tap`, `tapUntil`, `type`, `scrollTo`, `longPressDrag`, `launch`,
  `restartKeepingSession`. Nothing fails the JUnit test, as on iOS. After a KO with the app no longer on screen the
  message says it probably crashed, and the app is started again on its session.
- `E2EReport` — `report.json` and one PNG per step, rewritten after every step.

**Script** — `scripts/e2e-android.sh`. The password reaches the runner as an instrumentation argument, in an
`am instrument` line written to `adb shell`'s standard input: it is on no command line of the Mac, but it is in the
emulator's process list while the run lasts. The APKs go in with `adb install`, which streams them: Gradle's
`installDebug` pushes a copy to `/data/local/tmp` first, and a nearly full emulator refuses a 110 MB debug APK.

**App seams** — `app/…/e2e/E2EHooks.kt` and `E2EBarcodeFeed.kt`, inert unless the activity is started with the
`e2e.barcodes` extra, and in a release build whatever it is started with:

- The emulator's camera films a virtual room. Under the scenario the scanner draws a black feed
  (`e2e.scan.feed`) instead of CameraX, and **a tap on it holds the next barcode in front of the camera** — reported
  over and over, as a barcode in frame is, until the next tap. The runner decides when, after it has read the row:
  a first version moved on by itself once a book was finished with, and on a slow emulator « Dans mon inventaire »
  (three seconds) came and went during the previous step's screenshot.
- The runner launches the app with `am start`, not `startActivity`: an app in the background may not start another
  app's activity. It wipes the data with `pm clear` and grants the camera with `pm grant`, since the scanner asks
  for it on entry even when it reads the seam.

**Test tags** — `MainActivity` sets `testTagsAsResourceId`, so a `testTag` reaches UI Automator as a resource id:
`e2e.inventory.item`, `e2e.searchSuggestion.<works|humans|everything>`, `e2e.searchResult.<works|humans>`,
`e2e.authorWork`, `e2e.workEdition`, `e2e.book.otherEditions`, `e2e.sortBook`, `e2e.sortShelf.<name>`,
`e2e.sortNewShelf`, `e2e.scan.feed`. Everything else is found by the French on screen — the app has no other locale —
or by a `contentDescription` (« Plus », « Retour », « Fermer », « Ajouter », « Profil »). Dialogs, menus and sheets
are windows of their own, where `testTagsAsResourceId` does not reach: those are found by their words.

## What Compose and UI Automator cost

- **A button is found by its label, not by the clickable node holding it.** `By.clickable(true).hasDescendant(…)`
  also matches a sheet that holds the label, and the tap lands in the sheet's middle: « Créer » in « Créer une
  liste » was tapped that way three times without effect. The label's centre is on the button.
- **The selected tab is not clickable.** A `NavigationBarItem` reports `clickable = false` while selected, though a tap
  on it pops the stack to its root. Tabs are tapped by their label, the lowest of the words on screen with that text.
  The tab bar is recognised by « Réseau », the one tab no screen repeats.
- **A back press at the root of a tab leaves the app**, and back presses were behind most of the early runs' « l'app
  n'est plus à l'écran ». Navigation 3 keeps the screen being left in the tree while its exit animates, so « while
  there is a Retour, press back » pressed once too often. A tab's root is reached by tapping the selected tab, which
  pops its stack; back is only pressed to close something that covers the screen — the keyboard, a sheet (« Close
  sheet »), or a menu or dialog, recognised as a window smaller than the screen — and settles for a second after.
- **A swipe from the screen's edge is the system's back.** The list's swipe-to-delete started 20 px from the right
  edge, left the app, and was reported OK: the row was gone because the app was. It starts at four fifths of the
  row now, and `waitGone` fails when the app has left the screen.
- **Text goes in through accessibility, not the keyboard** (`UiObject2.setText`, no tap on the field), so the
  keyboard never hides the next target. Recherche still focuses its field as the tab opens, and Gboard's
  autocorrection then turned « Virginia Woolf » into « Virginia Wolf »: the query is typed again until the field
  holds it, and the suggestion is picked by the query in its description.
- **The étagères carousel only scrolls from its cards**, not from the paper labels under them, and only one card's
  label is exposed, the one snapped in the middle. A slow swipe over two thirds of the screen moves it by exactly one
  card; a short one does nothing, a fast one flings past several.
- **A menu left open hides everything else.** A `DropdownMenu` is a window of its own and UI Automator then reads
  only it; a step that failed with its « … » open took every later step down. Each tab change first closes what
  covers the tab bar.
- **An ANR is said as such.** When Android shows « Ex-libris isn't responding », the KO says so, and the app is
  force-stopped and started again on its session.
- **The welcome wall of covers never settles**, so UI Automator's default ten seconds of waiting for the screen to
  go idle would precede every lookup there. The runner sets `waitForIdleTimeout` to 500 ms. `uiautomator dump` fails
  on that screen for the same reason.
- **The drag is a real drag**: down, 1.2 s still (`detectDragGesturesAfterLongPress`), a slow move, 1 s over the
  card, up — injected as `MotionEvent`s. The tap-free « Ranger dans … » menu is not used: what is tested is the
  gesture.

## Known limits

- **Not yet seen whole.** On 2026-10-30 the steps were played on the app's session (`e2eKeepSession`): 25 of 27 OK
  in the best full run, and « Suppression de l'étagère » OK on its own (`e2eOnly`) once its carousel swipes were
  fixed — never yet inside a full run. The run through `scripts/e2e-android.sh` with signing in and out
  (`build/e2e-android/20261030-170619/`) ended 21 OK / 7 KO: sign-in, restart, scan, sorting, the list and sign-out
  passed; the four cleanup steps fell while an iOS 27.1 simulator booted beside it and the Mac's load average reached
  464 (the app, then Settings, Calendar and the clock raised ANRs at 17:20); the friend's book, Victor Hugo and
  « Autres éditions » timed out earlier in the same run. The emulator kept going down all afternoon for the same
  reason: run it on a Mac that is not also running simulators.
- The scanner is exercised through the seam: the lookup, the already-owned gate, the add and the bilan are tested,
  not CameraX nor ML Kit.
- « Suppression des livres » removes **every** book of the account, as on iOS: the account is a test account.
- The searches depend on inventaire.io's ranking, and « Dans la forêt » on OlivierB's shelves and friendship with the
  test account. inventaire.io ranks Adèle and Georges Victor-Hugo above Victor Hugo: for a person, a result titled
  exactly as typed is tried first, looked for further down the list. His works open « Éditions de … », and the first
  with an edition leads to a book.
- **The emulator can buckle.** A Pixel 8 API 35 AVD with 4 cores ran the app at 158 % CPU during a drag, raised an
  ANR, and its `system_server` died a minute later (`INSTRUMENTATION_ABORTED: System has crashed`). A cold boot
  (`-no-snapshot-load`) brought it back. It went down twice more on 2026-10-30 while iOS simulators ran beside it and
  the Mac's load average stood above 200: run it on a machine that is not also running Xcode.
- Runs that die halfway leave « E2E … » étagères and lists behind, which the next runs have to swipe past in the
  carousel. `E2E_RESET_ONLY_PREFIX='E2E ' scripts/e2e_reset_account.py` removes only those, and keeps the books.
- inventaire.io rate-limits sign-ins: run with `e2eKeepSession` when iterating.
