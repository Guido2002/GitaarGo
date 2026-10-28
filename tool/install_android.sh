#!/bin/sh
# Install without deleting existing app data; preserve Android's exact error.
# Usage: tool/install_android.sh [apk] [adb-serial]
set -eu
cd "$(dirname "$0")/.."
apk=${1:-build/releases/GitaarGo-0.2.0.apk}
if [ ! -f "$apk" ]; then
  printf 'APK niet gevonden: %s\n' "$apk" >&2
  exit 1
fi
# Reject damaged or truncated transfers before opening an install session.
python3 tool/verify_apk.py "$apk"
if command -v adb >/dev/null 2>&1; then
  adb_path=$(command -v adb)
else
  sdk_path=$(sed -n 's/^sdk.dir=//p' android/local.properties 2>/dev/null || true)
  adb_path="$sdk_path/platform-tools/adb"
fi
if [ ! -x "$adb_path" ]; then
  printf 'ADB niet gevonden. Installeer Android SDK Platform Tools of voeg adb toe aan PATH.\n' >&2
  exit 1
fi
install_serial=${2:-}
adb_run() {
  if [ -n "$install_serial" ]; then
    "$adb_path" -s "$install_serial" "$@"
  else
    "$adb_path" "$@"
  fi
}
if ! adb_run get-state >/dev/null 2>&1; then
  printf 'Geen eenduidig Android-toestel bereikbaar. Verbind het toestel via USB, schakel USB-debugging in en accepteer de computer op het toestel.
' >&2
  "$adb_path" devices
  exit 1
fi
printf 'Toestel: '

adb_run shell getprop ro.product.model
printf 'Android: '
adb_run shell getprop ro.build.version.release
printf 'CPU-architecturen: '
adb_run shell getprop ro.product.cpu.abilist
printf '\nAPK installeren: %s\n' "$apk"
if adb_run install -r "$apk"; then
  printf '\nInstallatie geslaagd.\n'
else
  printf '\nInstallatie mislukt. Bewaar de INSTALL_FAILED-code hierboven; die geeft de echte oorzaak.\n' >&2
  exit 1
fi
