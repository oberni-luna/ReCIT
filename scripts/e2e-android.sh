#!/usr/bin/env bash
#
# Runs the Android end-to-end scenario on an emulator and opens the compte-rendu.
#
#   scripts/e2e-android.sh                       # asks for the password, runs on the running emulator
#   E2E_PASSWORD=… scripts/e2e-android.sh        # non-interactive
#   E2E_AVD=Pixel_8_API_35 scripts/e2e-android.sh  # starts this AVD if no emulator is running
#   E2E_USERNAME=someone scripts/e2e-android.sh
#   E2E_RESET_ACCOUNT=1 scripts/e2e-android.sh   # empty the account first, after a run died halfway
#   E2E_SKIP_BUILD=1 scripts/e2e-android.sh      # reuse the APKs already installed
#   E2E_SERIAL=emulator-5556 scripts/e2e-android.sh  # which device, when several are connected
#   E2E_BUILD=release scripts/e2e-android.sh     # plays the R8-minified `e2eRelease` build instead of debug
#
# What it does, in order: finds (or starts) an emulator, builds and installs the app — debug by
# default, or with E2E_BUILD=release the `e2eRelease` build type: release's R8 shrinking and
# obfuscation, signed with the debug key, same `.dev` package — and the `:e2e` runner, runs
# `E2EScenarioTest` through `am instrument`, pulls the report the scenario wrote into the runner's
# external files back to `build/e2e-android/<timestamp>/`, and renders it with the same
# `scripts/e2e_report.py` as the iOS run.
#
# The password is never written to disk and never appears on this machine's command lines: the
# `am instrument` line that carries it is fed to `adb shell` on its standard input. It does show in
# the emulator's own process list for as long as the run lasts.
#
# The scenario signs into a real inventaire.io account and writes to it — books, étagères, a list —
# and deletes all of it again in its last steps. A run that fails halfway can leave things behind;
# the report says which. See docs/wiki/features/0065-android-end-to-end-scenario.md.
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_ROOT="$REPO_ROOT/Recit_Android"
SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
ADB="$SDK/platform-tools/adb"
EMULATOR="$SDK/emulator/emulator"

APP_PACKAGE="studio.lunabee.exlibris.android.dev"
RUNNER_PACKAGE="studio.lunabee.nouveaurecit.e2e"
TEST_CLASS="studio.lunabee.nouveaurecit.e2e.E2EScenarioTest"
REMOTE_REPORT="/sdcard/Android/data/$RUNNER_PACKAGE/files/e2e-report"

E2E_USERNAME="${E2E_USERNAME:-OlivierB_test4}"

# Which build of the app is played: debug (default) or release, the R8-minified `e2eRelease` variant.
E2E_BUILD="${E2E_BUILD:-debug}"
case "$E2E_BUILD" in
  debug)   VARIANT="debug";      GRADLE_VARIANT="Debug" ;;
  release) VARIANT="e2eRelease"; GRADLE_VARIANT="E2eRelease" ;;
  *) echo "E2E_BUILD doit valoir debug ou release, pas « $E2E_BUILD »." >&2; exit 2 ;;
esac
APP_APK="$ANDROID_ROOT/app/build/outputs/apk/$VARIANT/app-$VARIANT.apk"
RUNNER_APK="$ANDROID_ROOT/e2e/build/outputs/apk/$VARIANT/e2e-$VARIANT.apk"

STAMP="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="$REPO_ROOT/build/e2e-android/$STAMP"

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

# ------------------------------------------------- optional account pre-flight

if [[ "${E2E_RESET_ACCOUNT:-0}" == "1" ]]; then
  say "Remise à zéro du compte $E2E_USERNAME sur inventaire.io"
  if ! E2E_USERNAME="$E2E_USERNAME" E2E_PASSWORD="$E2E_PASSWORD" \
      python3 "$REPO_ROOT/scripts/e2e_reset_account.py"; then
    say "Remise à zéro impossible — on continue, le scénario fera le ménage lui-même"
  fi
fi

# ------------------------------------------------------------------- emulator

# A phone plugged in beside the emulator makes every bare `adb` call refuse to choose: name one.
pick_emulator() { "$ADB" devices | awk '$1 ~ /^emulator-/ && $2 == "device" { print $1; exit }'; }

if [[ -z "${E2E_SERIAL:-}" && -z "$(pick_emulator)" ]]; then
  AVD="${E2E_AVD:-$("$EMULATOR" -list-avds | head -n 1)}"
  if [[ -z "$AVD" ]]; then
    echo "Aucun émulateur lancé et aucun AVD trouvé." >&2
    exit 2
  fi
  say "Démarrage de l'émulateur « $AVD »"
  "$EMULATOR" -avd "$AVD" -no-snapshot-save -no-audio >/dev/null 2>&1 &
fi

say "Attente de l'émulateur"
until [[ -n "${E2E_SERIAL:-}" || -n "$(pick_emulator)" ]]; do sleep 2; done
export ANDROID_SERIAL="${E2E_SERIAL:-$(pick_emulator)}"
"$ADB" wait-for-device
until [[ "$("$ADB" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]]; do sleep 2; done

# ------------------------------------------------------------------ installation

if [[ "${E2E_SKIP_BUILD:-0}" != "1" ]]; then
  say "Compilation et installation de l'app ($E2E_BUILD) et du runner"
  (cd "$ANDROID_ROOT" && ./gradlew -q ":app:assemble$GRADLE_VARIANT" ":e2e:assemble$GRADLE_VARIANT")
  # `adb install` streams the APK; Gradle's install pushes a copy to /data/local/tmp first, which a
  # nearly full emulator refuses for a 110 MB debug APK. The app goes first, too: replacing it needs
  # room for both copies, and the scenario wipes its data anyway.
  "$ADB" uninstall "$APP_PACKAGE" >/dev/null 2>&1 || true
  "$ADB" install -t "$APP_APK" >/dev/null
  "$ADB" install -r -t "$RUNNER_APK" >/dev/null
fi

mkdir -p "$OUT_DIR"

# --------------------------------------------------------------------- test run

say "Exécution du scénario (comptez 10 à 15 minutes)"
quote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"; }
set +e
printf 'am instrument -w -r -e e2eUsername %s -e e2ePassword %s -e e2eBuild %s -e class %s %s/androidx.test.runner.AndroidJUnitRunner\nexit\n' \
    "$(quote "$E2E_USERNAME")" "$(quote "$E2E_PASSWORD")" "$E2E_BUILD" "$TEST_CLASS" "$RUNNER_PACKAGE" \
  | "$ADB" shell > "$OUT_DIR/instrument.log" 2>&1
set -e

if grep -q 'INSTRUMENTATION_FAILED\|FAILURES!!!\|Process crashed' "$OUT_DIR/instrument.log"; then
  say "L'instrumentation a terminé en erreur — le compte-rendu dira où"
fi

# --------------------------------------------------------------- pull the report

say "Récupération du compte-rendu"
if ! "$ADB" pull "$REMOTE_REPORT/." "$OUT_DIR/" >/dev/null 2>&1 || [[ ! -f "$OUT_DIR/report.json" ]]; then
  echo "Aucun compte-rendu trouvé sur l'émulateur." >&2
  echo "Log d'instrumentation : $OUT_DIR/instrument.log" >&2
  exit 1
fi

say "Rendu HTML"
set +e
python3 "$REPO_ROOT/scripts/e2e_report.py" "$OUT_DIR"
REPORT_STATUS=$?
set -e

echo
say "Compte-rendu : $OUT_DIR/report.html"
say "Log d'instrumentation : $OUT_DIR/instrument.log"
open "$OUT_DIR/report.html" >/dev/null 2>&1 || true

exit $REPORT_STATUS
