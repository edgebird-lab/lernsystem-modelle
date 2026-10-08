#!/usr/bin/env bash
# Baut ein Stimmenpaket für die Offline-Sprachausgabe aus einer Piper-Stimme im Format des sherpa-onnx-Modellreleases (k2-fsa), volle 32-Bit-Genauigkeit,
# zusammen mit den für die Sprache nötigen Daten von espeak-ng (GPL-3.0). Ergebnis: <Ausgabe>/voice-<sprache>-<name>.zip
#
# Aufruf: bash tools/make_voice_pack.sh <sherpa-Name> <Sprache> <Anzeigename> <Lizenz-Zeile> [Ausgabeordner]
# Beispiel: bash tools/make_voice_pack.sh vits-piper-en_US-ljspeech-medium en "LJSpeech (en_US, medium)" "LJ Speech Dataset, public domain" dist
#
# Das Paket enthält model.onnx, tokens.txt, espeak-ng-data/ (nur die Wörterbücher der Sprache und Englisch), voice.json (Name, Sprache) und LICENSES.txt.
# Eigene Stimmen für die App lassen sich genauso packen und über „Eigene Stimme importieren“ laden.
set -euo pipefail
SRC="$1"; LANG_TAG="$2"; TITLE="$3"; LICENSE_LINE="$4"; OUT="$(realpath -m "${5:-dist}")"
mkdir -p "$OUT"; WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
gh release download tts-models --repo k2-fsa/sherpa-onnx --pattern "$SRC.tar.bz2" --dir "$WORK"
tar -xjf "$WORK/$SRC.tar.bz2" -C "$WORK"
D="$WORK/$SRC"; P="$WORK/pack"; mkdir -p "$P"
ONNX="$(ls "$D"/*.onnx | head -1)"
cp "$ONNX" "$P/model.onnx"; cp "$D/tokens.txt" "$P/tokens.txt"; [ -f "$D/MODEL_CARD" ] && cp "$D/MODEL_CARD" "$P/MODEL_CARD.txt"
cp -r "$D/espeak-ng-data" "$P/espeak-ng-data"
# nur die Sprache der Stimme und Englisch (Fremdwörter) behalten
find "$P/espeak-ng-data" -maxdepth 1 -name '*_dict' ! -name "${LANG_TAG}_dict" ! -name 'en_dict' -delete
python3 - "$P/voice.json" "$TITLE" "$LANG_TAG" <<'PY'
import json,sys
json.dump({"name": sys.argv[2], "lang": sys.argv[3]}, open(sys.argv[1], "w"), ensure_ascii=False)
PY
cat > "$P/LICENSES.txt" <<LIC
Stimmenpaket "$TITLE" für das RAG-Lernsystem

- Stimme/Datensatz: $LICENSE_LINE
- Modell: Piper VITS (rhasspy/piper), MIT-Lizenz, im Format von sherpa-onnx (k2-fsa), Apache-2.0
- espeak-ng-data: Daten des Sprachsynthesizers eSpeak NG, GNU GPL v3 oder später, https://github.com/espeak-ng/espeak-ng
LIC
NAME="voice-$LANG_TAG-$(echo "$SRC" | sed -E 's/^vits-piper-[a-z]{2}_[A-Z]{2}-//')"
rm -f "$OUT/$NAME.zip"; ( cd "$P" && zip -qr "$OUT/$NAME.zip" . )
ls -la "$OUT/$NAME.zip"; sha256sum "$OUT/$NAME.zip"
