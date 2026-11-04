# Tests et scénario end-to-end

Swift Testing suites (pure or `MockURLProtocol`), one integration suite against production inventaire.io (gated), and the end-to-end scenario on iOS and Android with its compte-rendu.

## Code

- `scripts/e2e.sh`, `scripts/e2e-android.sh`, `scripts/e2e_report.py`
- `ReCIT_iOS/UITests/E2EScenarioTests.swift`
- `AppModels/UITest/UITestHooks.swift`

## Features

- [0012 The end-to-end scenario, and the compte-rendu it leaves behind](features/0012-end-to-end-scenario.md) — `scripts/e2e.sh` plays the whole app on a simulator and reports every step with a screenshot and an OK / KO
- [0065 The end-to-end scenario, on Android](features/0065-android-end-to-end-scenario.md) — `scripts/e2e-android.sh`: the iOS journey played by UI Automator from a self-instrumenting `:e2e` module, the same `report.json` and HTML; the scanner reads its barcodes through `E2EHooks`, the drag is injected; `e2eKeepSession` to iterate without signing in
