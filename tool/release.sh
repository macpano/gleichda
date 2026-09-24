#!/usr/bin/env bash
# Neue Version veröffentlichen (die App findet sie selbst über den versteckten Update-Speicher):
#
#   bash tool/release.sh 0.5.1 "Was neu ist"
#
# Zwischenstand als Vorabversion – bekommen nur Geräte mit „Vorabversionen
# erhalten“, reguläre Updates löst sie nicht aus:
#
#   VORAB=1 bash tool/release.sh 0.5.2-vorab.1 "Was neu ist"
#
# Setzt die Version in pubspec.yaml (Build-Nummer +1), prüft, baut die signierte APK, committet und
# taggt lokal. Die APK und die Versionsdateien kommen nach Dropbox/Projekte/Gleich.da; von dort
# spiegelt linienlog-web/tool/veroeffentlichen.mjs alles auf den Speicher (Netlify, Team macpano):
#   release.json   – neueste reguläre Version (Format eines GitHub-Releases, lib/state/updates.dart)
#   releases.json  – Liste für „Vorabversionen erhalten“ (reguläre + neueste Vorabversion)
#   Gleich.da.apk, Gleich.da-vorab.apk
# GitHub entfällt (24.09.2026). GITHUB=ja legt zusätzlich noch ein GitHub-Release an – nur für die
# Übergangsfassung, damit Installationen bis 0.4.23 die neue Update-Adresse erfahren.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:?Version angeben, z. B. 0.5.1}"
NOTES="${2:-}"
REPO="macpano/gleich.da"
ABLAGE="${ABLAGE:-C:/Users/macpa/Dropbox/Projekte/Gleich.da}"
SPEICHER=$(sed -n "s/^const updateStore = '\(.*\)';/\1/p" lib/state/updates.dart)
VEROEFFENTLICHEN="${VEROEFFENTLICHEN:-C:/Users/macpa/Desktop/linienlog-web/tool/veroeffentlichen.mjs}"

if [ -n "$(git status --porcelain)" ]; then
  echo "Ungespeicherte Änderungen – erst committen." >&2
  exit 1
fi
[ -f android/key.properties ] || { echo "android/key.properties fehlt (Signierschlüssel)." >&2; exit 1; }
[ -n "$SPEICHER" ] || { echo "Update-Speicher in lib/state/updates.dart nicht gefunden." >&2; exit 1; }

BUILD=$(sed -n 's/^version: .*+\([0-9]*\)$/\1/p' pubspec.yaml)
BUILD=$((BUILD + 1))
sed -i "s/^version: .*/version: $VERSION+$BUILD/" pubspec.yaml

flutter analyze
flutter test test
# Bildschirmfotos: jede Ansicht muss ohne Fehler aufbauen (die Bilder werden dabei neu geschrieben).
flutter test test_screens --update-goldens
taskkill.exe //F //IM flutter_tester.exe >/dev/null 2>&1 || true
flutter build apk --release
APK="build/app/outputs/flutter-apk/Gleich.da-$VERSION.apk"
cp build/app/outputs/flutter-apk/app-release.apk "$APK"

git add pubspec.yaml
git commit -m "Version $VERSION"
git tag "v$VERSION"

# --- Versteckter Update-Speicher ---
mkdir -p "$ABLAGE"
if [ -n "${VORAB:-}" ]; then NAME="Gleich.da-vorab.apk"; INFO="vorab.json"; else NAME="Gleich.da.apk"; INFO="release.json"; fi
cp "$APK" "$ABLAGE/$NAME"
python - "$ABLAGE" "$INFO" "$VERSION" "$NOTES" "$SPEICHER/$NAME" "$(stat -c %s "$APK")" "${VORAB:+true}" <<'PY'
import datetime, json, os, sys
ablage, info, version, notes, url, size, vorab = sys.argv[1:8]
pre = vorab == "true"
rel = {"tag_name": "v" + version, "name": "Gleich.da " + version + (" (Vorabversion)" if pre else ""),
       "draft": False, "prerelease": pre, "body": notes,
       "published_at": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
       "assets": [{"name": os.path.basename(url), "browser_download_url": url, "size": int(size)}]}
json.dump(rel, open(os.path.join(ablage, info), "w", encoding="utf-8"), ensure_ascii=True, indent=2)
# Eine reguläre Version ersetzt jede ältere Vorabversion.
if not pre:
    for f in ("vorab.json", "Gleich.da-vorab.apk"):
        p = os.path.join(ablage, f)
        if os.path.exists(p): os.remove(p)
liste = [json.load(open(os.path.join(ablage, f), encoding="utf-8")) for f in ("release.json", "vorab.json")
         if os.path.exists(os.path.join(ablage, f))]
json.dump(liste, open(os.path.join(ablage, "releases.json"), "w", encoding="utf-8"), ensure_ascii=True, indent=2)
PY
node "$VEROEFFENTLICHEN"
echo "Veröffentlicht: $SPEICHER/$INFO"

# --- GitHub nur für den Übergang ---
if [ "${GITHUB:-nein}" = "ja" ]; then
  git push origin main "v$VERSION"
  TOKEN=$(printf "protocol=https\nhost=github.com\n\n" | git credential fill | sed -n 's/^password=//p')
  PRE=$([ -n "${VORAB:-}" ] && echo true || echo false)
  BODY=$(python -c 'import json,sys; print(json.dumps({"tag_name":sys.argv[1],"name":"Gleich.da "+sys.argv[2]+(" (Vorabversion)" if sys.argv[4]=="true" else ""),"body":sys.argv[3],"prerelease":sys.argv[4]=="true"}))' "v$VERSION" "$VERSION" "$NOTES" "$PRE")
  ID=$(curl -sf -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github+json" \
    --data-binary "$BODY" "https://api.github.com/repos/$REPO/releases" \
    | python -c 'import json,sys; print(json.load(sys.stdin)["id"])')
  curl -sf -o /dev/null -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/vnd.android.package-archive" \
    --data-binary @"$APK" "https://uploads.github.com/repos/$REPO/releases/$ID/assets?name=$(basename "$APK")"
  echo "Übergang: https://github.com/$REPO/releases/tag/v$VERSION"
fi
