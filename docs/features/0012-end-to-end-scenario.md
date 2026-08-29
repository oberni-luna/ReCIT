# The end-to-end scenario, and the compte-rendu it leaves behind

Shipped on 2026-08-29.

## What it does

One command plays the whole app on a simulator, against the real `inventaire.io`, and leaves a
report you can read:

```sh
scripts/e2e.sh
```

It asks for the test account's password, boots the simulator, wipes the app, runs the scenario,
and opens `build/e2e/<timestamp>/report.html` — one row per step, with a screenshot, what the
step acted on in the app's own words (the book that was added, the shelf that was named), and
**OK / KO / non joué**. A KO row carries the reason in plain French.

The journey, in order:

1. sign in as the test account;
2. scan two books through the batch scanner — the two barcodes the feature was written from,
   « Lucioles » (`9782370493002`) and « Penss et les plis du monde » (`9782413013518`);
3. find three more by hand: a French author (Victor Hugo), an English one (Virginia Woolf), and a
   title looked up directly (Le Petit Prince), adding a copy of each to the inventory;
4. open « Ranger mes livres », create two étagères, drag a book onto each, apply;
5. create a list and put two works in it;
6. delete all of it — the list, the two étagères, every book;
7. sign out.

Every name the run creates carries a timestamp (`E2E Romans 0829-141207`), so a run that failed
halfway and left an étagère behind cannot block the next one.

## How to run it

```sh
scripts/e2e.sh                              # prompts for the password
E2E_PASSWORD=… scripts/e2e.sh               # non-interactive
E2E_SIMULATOR="iPhone 17 Pro" scripts/e2e.sh
E2E_USERNAME=someone_else scripts/e2e.sh
E2E_RESET_ACCOUNT=1 scripts/e2e.sh          # empty the account first
```

`E2E_RESET_ACCOUNT=1` runs `scripts/e2e_reset_account.py` before the scenario: it signs into
the account over the API and deletes every book, étagère and list. Off by default — it removes
real data — and only needed after a run died halfway through its own cleanup.

The account defaults to `OlivierB_test2`. **The password is never stored**: it is read into the
environment and handed to the test runner through `TEST_RUNNER_E2E_PASSWORD`, which `xcodebuild`
forwards into the runner process with the prefix stripped — so it appears in no file, and on no
command line.

It can also be run from Xcode: the shared scheme is **ReCIT_iOSE2E**. Started that way it will
fail on step 1 with "identifiants absents", which is the honest answer — set the two
`TEST_RUNNER_…` variables in the scheme's test action to run it from the IDE.

Expect eight to fifteen minutes. Every screen in the scenario is behind at least one round trip,
and a search that has to back out of a work with no edition spends a minute doing it.

## Technical surface

**Test bundle** — `ReCIT_iOS/UITests/`, target `ReCIT_iOSUITests`:

- `E2EScenarioTests` — the scenario itself, one `step` per line of the report.
- `E2EDriver` — the vocabulary it is written in: `step`, `waitFor`, `waitUntil`, `tap`, `type`,
  `drag`, `openTab`, `popBack`. **Nothing calls `XCTFail`**: a step that throws is recorded KO
  with its reason and the run carries on, because the deliverable is a compte-rendu of the whole
  journey and not a stop at the first surprise. `step(critical:)` marks the failures that make
  what follows meaningless — no session, no scanner — after which the remaining steps are
  recorded `SKIP` rather than attempted against the wrong screen.
- `E2EReport` — writes `report.json` and the PNGs into the *runner's* `Documents/e2e-report/`,
  rewritten after **every** step so a hang or a crash still leaves a readable partial report. The
  same screenshots are attached to the `.xcresult`.

**Runner** — `scripts/e2e.sh`, `scripts/e2e_report.py`, `scripts/e2e_reset_account.py`. The shell
script boots the simulator, uninstalls the app *and* the runner (a fresh install per run), runs
the scheme, pulls the report folder back out of the simulator with
`xcrun simctl get_app_container`, and renders it. The Python script turns `report.json` into
`report.html` (screenshots embedded as thumbnails, so the page reads on its own when it travels
alone; the full-size PNGs stay beside it for the click-through), `report.md`, and a summary on
stdout. It exits non-zero when anything is KO, so it can gate a pipeline later.

**App seams** — `AppModels/UITest/UITestHooks.swift`, inert unless launched with `-uitest` and
compiled out of Release entirely:

- The simulator has no camera. `CodeScannerView` draws a placard there and hands back whatever
  string it was built with — a constant in the app, which would make a scanning session one book
  repeated. Under the scenario it reads `UITestHooks.currentBarcode`, and
  `BatchScanCameraView` advances the list when a book is *finished with* (added, unknown, or
  already owned) rather than when a barcode is seen — a barcode in frame is read several times a
  second.
- The session survives an uninstall, by design: it lives in the keychain (see `Keychain`). So
  `-uitest-reset` wipes the keychain entry, the cookie jar, the onboarding answers and the
  SwiftData store, and it runs from `ReCIT.init()` **before** `AuthService` is built — building it
  is what restores the cookies.

**Accessibility identifiers** — some forty `e2e.*` identifiers across the shipped screens
(`e2e.login.submit`, `e2e.sortShelf.<name>`, `e2e.book.menu`, …). Identifiers rather than labels
wherever one exists: a label is a translation, and a test that breaks when a word is reworded is a
test nobody keeps. The app is launched with `-AppleLanguages (fr)` all the same, because a handful
of system-drawn controls can only be found by their French title.

## Decisions worth knowing

**It writes to a real account, and cleans up after itself.** There is no fixture server and no
staging inventaire (`Env` points both cases at production — see CLAUDE.md), so the only honest
end-to-end test is one that really signs in and really writes. The cleanup is therefore *part of
the scenario*, reported step by step: a run that leaves books behind says so in its own report
instead of failing silently and poisoning the next run.

**The drag is a real drag.** Filing a book on the sorting surface is a `draggable`/`dropDestination`
pair, and the screen's only tap-free alternative is a VoiceOver custom action, which XCUITest
cannot invoke. So the step presses for 1.2 s, drags slowly, and holds for 1.2 s before releasing —
a plain swipe is read as a scroll and the book never leaves the carousel. It is the flakiest step
in the run by some distance, and it is marked non-critical for that reason: a drag that does not
take is one KO row, not a dead report.

**The report lands inside the simulator.** A UI test runs *in* the simulator and has no writable
path the host can see, so the report is written to the runner's container and pulled out
afterwards. `xcresulttool` would have been the other route; it changes shape between Xcode
versions, and a folder of PNGs beside a JSON does not.

## What iOS 26 cost

Four of the platform's own behaviours shaped the driver more than the app did, and they are
worth knowing before touching a step that looks over-defensive:

- **The floating tab bar, and the buttons at the foot of a full-screen cover, report
  `isHittable == false`** while sitting plainly on screen and answering a finger. So `tap` gives
  an element 1.5 s to become hittable and then taps the centre of its frame by coordinate.
- **Such a tap is sometimes swallowed** — the accueil's « Plus tard » needs two about half the
  time. Every tap that changes screen therefore goes through `tap(_:until:)`: tap, look, tap
  again, up to three times, and say so if the screen never changed.
- **`Tab(role: .search)` dissolves the tab bar into a search field at the foot of the screen and
  withdraws the navigation bar entirely** — toolbar included. The scan action `MainSearchView`
  declares in its toolbar is therefore not reachable from that tab at all, which is why the
  scenario opens the scanner from the accueil (and from the debug section as a fallback) rather
  than from there. The search tab is recognised by its field *plus* the absence of a navigation
  bar.
- **Asking `isHittable` about an element that is off screen fails the whole test** rather than
  answering `false`: "Activation point invalid and no suggested hit points based on element
  frame". The étagères carousel is where this bites — the second card sits three quarters past
  the right edge. `E2EDriver.isReachable(_:)` guards every hittability read, and the shelves are
  deleted in alphabetical order so the one being reached for is always the card on screen.

A fifth is not iOS's fault but is just as easy to trip over: **a cover does not remove the
screen behind it from the accessibility tree**. The étagères toolbar still `exists` while the
scanner runs on top of it, so `E2EDriver.isShowingRoot(of:)` tests for the flow's own markers
first — without that, the scenario walks on from inside the scanner, tapping at a tab bar
nobody can reach.

And one that belongs to the app's own view code: **an identifier put on a field *after* a
modifier that wraps it lands on the wrapper**, and resolves to the label rather than to the box.
Typing into a `StaticText` raises inside XCTest and kills the run, so `E2EDriver.type` refuses
anything that is not a field and `driver.textField(_:)` asks by type.

## What the first runs found

The scenario's first complete run reproduced
[issue 0065](../issues/0065-crash-deleting-an-item-from-the-book-screen.md) — a crash reported
from a device on 2026-08-28 and never reproduced since — and left the stack that names the
culprit: not `BookDetailView`, which had been probed and cleared, but `InventoryCell` in the
list *behind* it, reading `InventoryItem.transaction` on a model that has just been deleted.

**So « Suppression des livres de l'inventaire » is KO on every run until that issue is fixed**,
and the row says so: "L'application ne tournait plus : elle a planté pendant cette étape." The
driver notices a dead app, relaunches it **without** the signed-out wipe — the session lives in
the keychain, so it comes back where it was — and the steps after it are attempted for real. A
run that ends 25 OK / 1 KO on that row is the expected result today.

A consequence worth knowing: because the delete loop stops at the crash, a run leaves its books
behind on the account. `E2E_RESET_ACCOUNT=1` is the broom.

## Known limits

- The scanner is exercised through the package's simulator placard, so the run proves the lookup,
  the already-owned gate, the add and the tally — but not the camera or the barcode decoding.
- The three searches depend on inventaire.io's own ranking. Plenty of works in that database have
  no edition behind them, and their gateway sits on a spinner for ever — so `reachBookScreen`
  backtracks, trying the next work in the list when a branch leads nowhere. It gives up after
  150 s, and that row is then a report about the data, not about the app.
- **inventaire.io rate-limits sign-ins.** Several runs in quick succession (or a run after a
  session of manual API calls) can meet a `429`, which surfaces as a KO on step 2. Wait a few
  minutes rather than retrying at once.
- The whole run is one test. Steps are not independently runnable; the state each one needs is
  built by the ones before it.
