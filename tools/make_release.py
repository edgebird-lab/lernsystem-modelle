#!/usr/bin/env python3
"""Teilt die Modelldateien in Release-Teile (je max. 1 GiB, GitHub erlaubt 2 GiB pro Asset),
berechnet SHA-256 und schreibt manifest.json. Die Teile werden in der App nacheinander geladen und zusammengesetzt.

Aufruf: python3 -I tools/make_release.py --out dist --release v1 e2b=/pfad/gemma-4-E2B-it.litertlm emb=/pfad/embeddinggemma-2-text-270m.litertlm
Danach: gh release create v1 dist/* --repo edgebird-lab/lernsystem-modelle
"""
import argparse, hashlib, json
from pathlib import Path

PART = 1 << 30
REPO = "edgebird-lab/lernsystem-modelle"
META = {
    "e2b": dict(id="gemma-4-e2b-it", role="llm", title="Gemma 4 E2B (Sprachmodell)", relSpeed=1.0, source="https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm", minRamMb=6000),
    "e4b": dict(id="gemma-4-e4b-it", role="llm", title="Gemma 4 E4B (größeres Sprachmodell)", titleEn="Gemma 4 E4B (larger language model)", source="https://huggingface.co/litert-community/gemma-4-E4B-it-litert-lm", minRamMb=10000, optional=True, relSpeed=0.7,
                description="Größer als E2B: etwas gründlichere Antworten, aber spürbar langsamer (rund ein Drittel weniger Tempo) und mit mehr Arbeitsspeicher. Empfohlen ab 12 GB RAM. Ersetzt E2B (nur eines ist aktiv).",
                descriptionEn="Larger than E2B: somewhat more thorough answers, but noticeably slower (about a third less speed) and needs more memory. Recommended from 12 GB RAM. Replaces E2B (only one is active)."),
    "emb": dict(id="embeddinggemma-2-270m", role="embedding", title="EmbeddingGemma 2 (Suche)", source="https://huggingface.co/litert-community/embeddinggemma-2-text-270m-litert-lm", minRamMb=2000),
}

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="dist"); ap.add_argument("--release", default="v1")
    ap.add_argument("files", nargs="+", help="schluessel=pfad, Schluessel: " + ", ".join(META))
    a = ap.parse_args()
    out = Path(a.out); out.mkdir(parents=True, exist_ok=True)
    models = []
    for spec in a.files:
        key, path = spec.split("=", 1); src = Path(path)
        whole = hashlib.sha256(); parts = []
        with src.open("rb") as f:
            i = 0
            while True:
                chunk = f.read(PART)
                if not chunk: break
                i += 1; name = f"{src.name}.part{i}"
                (out / name).write_bytes(chunk); whole.update(chunk)
                parts.append(dict(name=name, size=len(chunk), sha256=hashlib.sha256(chunk).hexdigest(),
                                  urls=[f"https://github.com/{REPO}/releases/download/{a.release}/{name}"]))
        models.append(dict(**META[key], version=a.release, fileName=src.name, size=src.stat().st_size, sha256=whole.hexdigest(), license="Apache-2.0", parts=parts))
    manifest = dict(schemaVersion=1, release=a.release, minAppVersion=1, licenseUrl=f"https://github.com/{REPO}/blob/main/LICENSE", models=models)
    (out / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print("fertig:", out / "manifest.json")

if __name__ == "__main__":
    main()
