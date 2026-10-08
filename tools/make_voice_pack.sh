#!/usr/bin/env bash
# Baut das Stimmenpaket für die Offline-Sprachausgabe: Piper-Stimme „Thorsten“ (de_DE, medium, volle 32-Bit-Genauigkeit; Datensatz CC0) aus dem sherpa-onnx-Modellrelease,
# zusammen mit den für Deutsch nötigen Daten von espeak-ng (GPL-3.0). Ergebnis: dist/voice-de-thorsten-medium.zip
# Aufruf: bash tools/make_voice_pack.sh [Ausgabeordner]
set -euo pipefail
OUT="$(realpath -m "${1:-dist}")"; mkdir -p "$OUT"; WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
SRC="vits-piper-de_DE-thorsten-medium"
gh release download tts-models --repo k2-fsa/sherpa-onnx --pattern "$SRC.tar.bz2" --dir "$WORK"
tar -xjf "$WORK/$SRC.tar.bz2" -C "$WORK"
D="$WORK/$SRC"; P="$WORK/pack"; mkdir -p "$P"
cp "$D/de_DE-thorsten-medium.onnx" "$P/model.onnx"; cp "$D/tokens.txt" "$P/tokens.txt"; cp "$D/MODEL_CARD" "$P/MODEL_CARD.txt"
cp -r "$D/espeak-ng-data" "$P/espeak-ng-data"
# nur Deutsch und Englisch (Fremdwörter) behalten; die übrigen Wörterbücher sind für diese Stimme unnötig (ru_dict allein 8,5 MB)
find "$P/espeak-ng-data" -maxdepth 1 -name '*_dict' ! -name 'de_dict' ! -name 'en_dict' -delete
cat > "$P/LICENSES.txt" <<'LIC'
Stimmenpaket "Thorsten (de_DE, medium)" für das RAG-Lernsystem

- Stimme/Datensatz: Thorsten-Voice (Thorsten Müller), CC0 1.0, https://github.com/thorstenMueller/Thorsten-Voice
- Modell: Piper VITS (rhasspy/piper), MIT-Lizenz, im Format von sherpa-onnx (k2-fsa), Apache-2.0
- espeak-ng-data: Daten des Sprachsynthesizers eSpeak NG, GNU GPL v3 oder später, https://github.com/espeak-ng/espeak-ng
LIC
rm -f "$OUT/voice-de-thorsten-medium.zip"; ( cd "$P" && zip -qr "$OUT/voice-de-thorsten-medium.zip" . )
ls -la "$OUT/voice-de-thorsten-medium.zip"
