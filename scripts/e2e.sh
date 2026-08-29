#!/usr/bin/env bash
#
# Runs the end-to-end scenario on a simulator and opens the compte-rendu.
#
#   scripts/e2e.sh                     # asks for the password, runs on iPhone 17
#   E2E_PASSWORD=… scripts/e2e.sh      # non-interactive
#   E2E_SIMULATOR="iPhone 17 Pro" scripts/e2e.sh
#   E2E_USERNAME=someone scripts/e2e.sh
#   E2E_RESET_ACCOUNT=1 scripts/e2e.sh   # empty the account first, after a run died halfway
#   E2E_KEEP_RESULT_BUNDLE=1 scripts/e2e.sh  # keep run.xcresult (~130 MB) to open in Xcode
#
# What it does, in order: finds and boots the simulator, uninstalls both the app and the
# test runner so the run starts from nothing, runs `ReCIT_iOSE2E`, pulls the report the
# scenario wrote inside the runner's container back out to `build/e2e/<timestamp>/`, and
# renders it as HTML.
#
# The password is never written to disk and never appears on a command line: it is read
# into the environment and handed to the test runner through `TEST_RUNNER_E2E_PASSWORD`,
# which xcodebuild forwards into the runner process with the prefix stripped.
#
# The scenario signs into a real inventaire.io account and writes to it — books, étagères,
# a list — and deletes all of it again in its last steps. A run that fails halfway can
# leave things behind; the report says which.
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$REPO_ROOT/ReCIT_iOS/ReCIT_iOS.xcodeproj"
SCHEME="ReCIT_iOSE2E"
TEST_ID="ReCIT_iOSUITests/E2EScenarioTests/testFullJourney"

APP_BUNDLE_ID="studio.lunabee.nouveau-recit"
RUNNER_BUNDLE_ID="fr.association.ReCIT-iOSUITests.xctrunner"

SIMULATOR_NAME="${E2E_SIMULATOR:-iPhone 17}"
E2E_USERNAME="${E2E_USERNAME:-OlivierB_test2}"

STAMP="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="$REPO_ROOT/build/e2e/$STAMP"
RESULT_BUNDLE="$OUT_DIR/run.xcresult"

say() { printf '\033[1m==>\033[0m %s\n' "$*"; }

# ---------------------------------------------------------------- credentials

if [[ -z "${E2E_PASSWORD:-}" ]]; then
  printf 'Mot de passe de %s : ' "$E2E_USERNAME" >&2
  read -rs E2E_PASSWORD
  printf '\n' >&2
fi

if [[ -z "$E2E_PASSWORD" ]]; then
  echo "Mot de passe vide — abandon." >&2
  exit 2
fi

export TEST_RUNNER_E2E_USERNAME="$E2E_USERNAME"
export TEST_RUNNER_E2E_PASSWORD="$E2E_PASSWORD"

# ------------------------------------------------- optional account pre-flight

# The scenario deletes what it created as its last steps, so this is only for the runs that
# died halfway and left things behind. Off by default: it removes real data.
if [[ "${E2E_RESET_ACCOUNT:-0}" == "1" ]]; then
  say "Remise à zéro du compte $E2E_USERNAME sur inventaire.io"
  # Not fatal: inventaire.io rate-limits sign-ins, and a 429 here must not cost the run — the
  # scenario cleans up after itself anyway, and the report will say what was left behind.
  if ! E2E_USERNAME="$E2E_USERNAME" E2E_PASSWORD="$E2E_PASSWORD" \
      python3 "$REPO_ROOT/scripts/e2e_reset_account.py"; then
    say "Remise à zéro impossible — on continue, le scénario fera le ménage lui-même"
  fi
fi

# ------------------------------------------------------------------ simulator

say "Recherche du simulateur « $SIMULATOR_NAME »"
UDID="$(xcrun simctl list devices available --json \
  | SIM_NAME="$SIMULATOR_NAME" python3 -c '
import json, os, sys
name = os.environ["SIM_NAME"]
data = json.load(sys.stdin)
for runtime, devices in sorted(data["devices"].items(), reverse=True):
    for device in devices:
        if device.get("name") == name and device.get("isAvailable"):
            print(device["udid"])
            raise SystemExit
raise SystemExit("introuvable")
')"

if [[ -z "$UDID" ]]; then
  echo "Simulateur « $SIMULATOR_NAME » introuvable. \`xcrun simctl list devices available\` pour la liste." >&2
  exit 2
fi

say "Démarrage du simulateur ($UDID)"
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || true
open -a Simulator --args -CurrentDeviceUDID "$UDID" >/dev/null 2>&1 || true

say "Désinstallation de l'app et du runner (départ à zéro)"
xcrun simctl uninstall "$UDID" "$APP_BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl uninstall "$UDID" "$RUNNER_BUNDLE_ID" >/dev/null 2>&1 || true

mkdir -p "$OUT_DIR"

# ------------------------------------------------------------------- test run

say "Exécution du scénario (comptez 5 à 10 minutes)"
set +e
xcodebuild test \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,id=$UDID" \
  -only-testing:"$TEST_ID" \
  -resultBundlePath "$RESULT_BUNDLE" \
  -test-timeouts-enabled YES \
  -maximum-test-execution-time-allowance 1800 \
  > "$OUT_DIR/xcodebuild.log" 2>&1
XCODEBUILD_STATUS=$?
set -e

if [[ $XCODEBUILD_STATUS -ne 0 ]]; then
  say "xcodebuild a terminé en erreur ($XCODEBUILD_STATUS) — le compte-rendu dira où"
fi

# --------------------------------------------------------------- pull the report

say "Récupération du compte-rendu"
REPORT_SRC=""

CONTAINER="$(xcrun simctl get_app_container "$UDID" "$RUNNER_BUNDLE_ID" data 2>/dev/null || true)"
if [[ -n "$CONTAINER" && -d "$CONTAINER/Documents/e2e-report" ]]; then
  REPORT_SRC="$CONTAINER/Documents/e2e-report"
else
  # The runner is sometimes removed with the session; the folder it wrote is still on disk.
  REPORT_SRC="$(find "$HOME/Library/Developer/CoreSimulator/Devices/$UDID/data/Containers/Data/Application" \
    -maxdepth 3 -type d -name e2e-report 2>/dev/null | head -n 1 || true)"
fi

if [[ -z "$REPORT_SRC" || ! -f "$REPORT_SRC/report.json" ]]; then
  echo "Aucun compte-rendu trouvé sur le simulateur." >&2
  echo "Log de build : $OUT_DIR/xcodebuild.log" >&2
  exit 1
fi

cp -R "$REPORT_SRC/." "$OUT_DIR/"

say "Rendu HTML"
set +e
python3 "$REPO_ROOT/scripts/e2e_report.py" "$OUT_DIR"
REPORT_STATUS=$?
set -e

# The `.xcresult` is the same run again, with Xcode's own automatic screenshots on top: about
# 130 MB per run, against a report folder of 10. It is only worth keeping when the run is being
# opened in Xcode, so it goes unless asked for.
if [[ "${E2E_KEEP_RESULT_BUNDLE:-0}" != "1" ]]; then
  rm -rf "$RESULT_BUNDLE"
fi

echo
say "Compte-rendu : $OUT_DIR/report.html"
say "Log xcodebuild : $OUT_DIR/xcodebuild.log"
open "$OUT_DIR/report.html" >/dev/null 2>&1 || true

exit $REPORT_STATUS
