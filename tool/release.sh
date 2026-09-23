#!/usr/bin/env bash
# Neue Version für Obtainium veröffentlichen:
#
#   bash tool/release.sh 0.1.1 "Was neu ist"
#
# Setzt die Version in pubspec.yaml (Build-Nummer +1), prüft, baut die
# signierte APK, committet, taggt v<Version>, pusht und legt das
# GitHub-Release mit der APK an. Der Zugang kommt aus der Git-Anmeldung
# (Git Credential Manager), kein Token im Repo.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:?Version angeben, z. B. 0.1.1}"
NOTES="${2:-}"
REPO="macpano/gleichda"

if [ -n "$(git status --porcelain)" ]; then
  echo "Ungespeicherte Änderungen – erst committen." >&2
  exit 1
fi
[ -f android/key.properties ] || { echo "android/key.properties fehlt (Signierschlüssel)." >&2; exit 1; }

BUILD=$(sed -n 's/^version: .*+\([0-9]*\)$/\1/p' pubspec.yaml)
BUILD=$((BUILD + 1))
sed -i "s/^version: .*/version: $VERSION+$BUILD/" pubspec.yaml
sed -i "s/^const appVersion = .*/const appVersion = '$VERSION';/" lib/ui/screens/more_screen.dart

flutter analyze
flutter test test
flutter build apk --release
APK="build/app/outputs/flutter-apk/gleichda-$VERSION.apk"
cp build/app/outputs/flutter-apk/app-release.apk "$APK"

git add pubspec.yaml lib/ui/screens/more_screen.dart
git commit -m "Version $VERSION"
git tag "v$VERSION"
git push origin main "v$VERSION"

TOKEN=$(printf "protocol=https\nhost=github.com\n\n" | git credential fill | sed -n 's/^password=//p')
BODY=$(python -c 'import json,sys; print(json.dumps({"tag_name":sys.argv[1],"name":"Gleichda "+sys.argv[2],"body":sys.argv[3]}))' "v$VERSION" "$VERSION" "$NOTES")
ID=$(curl -sf -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github+json" \
  --data-binary "$BODY" "https://api.github.com/repos/$REPO/releases" \
  | python -c 'import json,sys; print(json.load(sys.stdin)["id"])')
curl -sf -o /dev/null -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/vnd.android.package-archive" \
  --data-binary @"$APK" "https://uploads.github.com/repos/$REPO/releases/$ID/assets?name=$(basename "$APK")"
echo "Veröffentlicht: https://github.com/$REPO/releases/tag/v$VERSION"
