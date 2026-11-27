#!/bin/bash
# Creates the permanent Android release key and android/key.properties.
#
#   bash tool/create_release_key.sh
#
# The keystore is kept OUTSIDE the repo (so `git clean` can't delete it).
# If the keystore already exists (for example restored from a backup), it is
# left untouched and only android/key.properties is recreated.
set -euo pipefail
umask 077

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROPS="$ROOT/android/key.properties"
KEYSTORE="${SQUIRRELSTASH_KEYSTORE:-$HOME/keystores/squirrelstash-release.jks}"
ALIAS="squirrelstash"

die() { echo "Error: $*" >&2; exit 1; }

STUDIO_KEYTOOL="/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool"
if [ -x "$STUDIO_KEYTOOL" ]; then
  KEYTOOL="$STUDIO_KEYTOOL"
else
  KEYTOOL="$(command -v keytool)" || die "keytool not found. Install Android Studio or a JDK."
fi

[ -t 0 ] || die "run this in an interactive terminal so you can type the password."
[ -e "$PROPS" ] && die "$PROPS already exists. Nothing was changed."

ask() { # ask "prompt" -> sets REPLY without echoing
  IFS= read -rs -p "$1" REPLY
  echo
}

if [ -e "$KEYSTORE" ]; then
  echo "Found an existing keystore: $KEYSTORE"
  ask "Its password: "
  export SS_PASS="$REPLY"
  "$KEYTOOL" -list -keystore "$KEYSTORE" -alias "$ALIAS" -storepass:env SS_PASS >/dev/null \
    || die "that password (or alias '$ALIAS') doesn't open this keystore."
else
  echo "Creating a new release key at: $KEYSTORE"
  echo "Choose a password (8+ characters). Save it in your password manager NOW:"
  echo "if it is lost, the key is useless and cannot be recovered."
  ask "New password: "
  first="$REPLY"
  [ "${#first}" -ge 8 ] || die "use at least 8 characters."
  if printf '%s' "$first" | LC_ALL=C grep -q '[^ -~]'; then
    die "use plain keyboard characters only (no emoji or accented letters)."
  fi
  case "$first" in " "*) die "the password can't start with a space." ;; esac
  ask "Type it again: "
  [ "$first" = "$REPLY" ] || die "the passwords didn't match. Nothing was created."
  export SS_PASS="$first"
  mkdir -p "$(dirname "$KEYSTORE")"
  "$KEYTOOL" -genkeypair -keystore "$KEYSTORE" -storetype PKCS12 \
    -alias "$ALIAS" -keyalg RSA -keysize 4096 -validity 10000 \
    -dname "CN=SquirrelStash" -storepass:env SS_PASS -keypass:env SS_PASS
fi
chmod 600 "$KEYSTORE"

# Java .properties files treat backslash as an escape character.
escape() { local v="$1"; printf '%s' "${v//\\/\\\\}"; }
{
  printf 'storeFile=%s\n' "$(escape "$KEYSTORE")"
  printf 'storePassword=%s\n' "$(escape "$SS_PASS")"
  printf 'keyAlias=%s\n' "$ALIAS"
  printf 'keyPassword=%s\n' "$(escape "$SS_PASS")"
} > "$PROPS"

echo
echo "Done."
echo "  Keystore:       $KEYSTORE"
echo "  Gradle secrets: $PROPS (ignored by git)"
echo "  Certificate fingerprint:"
"$KEYTOOL" -list -v -keystore "$KEYSTORE" -alias "$ALIAS" -storepass:env SS_PASS | grep 'SHA256:'
unset SS_PASS
echo
echo "Back up the .jks file and the password before installing a release build."
