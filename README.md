# lernsystem-modelle

Release-Assets für die Android-App des RAG-Lernsystems: Sprachmodell (Gemma 4 E2B) und Embedding-Modell (EmbeddingGemma 2), beide Apache 2.0 und unverändert. Die App lädt `manifest.json` und die Teile von hier, damit sie nicht von Hugging Face oder einer API abhängt.

- `manifest.json` beschreibt Modelle, Teile, URLs, Größen und SHA-256 (Schema: `schemaVersion` 1).
- Release-Assets sind in Teile à höchstens 1 GiB zerlegt (GitHub-Limit 2 GiB). Die App prüft jedes Teil per SHA-256 und setzt sie zusammen.
- Neu bauen: `python3 -I tools/make_release.py --out dist --release v1 e2b=… emb=…`, dann `gh release create`.

Lizenz: Apache 2.0, siehe LICENSE und NOTICE.

## Stimmenpaket (Release v2)

`voice-de-thorsten-medium.zip` enthält die deutsche Piper-Stimme „Thorsten“ samt der für Deutsch nötigen espeak-ng-Daten für die Offline-Sprachausgabe der App (optional, ca. 59 MB). Bauen: `bash tools/make_voice_pack.sh dist`; der Eintrag steht in `manifest.json` (`optional`, `unpack`). Lizenzen siehe NOTICE (Stimme CC0, Piper MIT, espeak-ng-Daten GPL-3.0+).
