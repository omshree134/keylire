#!/usr/bin/env bash
# Downloads the on-device embedding model Keylire needs. Without it the app
# silently runs a bag-of-words fallback with no semantic matching.
set -euo pipefail
cd "$(dirname "$0")/../keylire"
mkdir -p assets/models

BASE="https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2/resolve/main"
# int8 arm64 build is what phones want; check the HF "onnx/" folder if the
# filename has changed.
curl -L "$BASE/onnx/model_qint8_arm64.onnx" -o assets/models/minilm-l6-v2-int8.onnx
curl -L "$BASE/vocab.txt"                   -o assets/models/vocab.txt

ls -la assets/models
echo "Done. Run: flutter pub get && flutter run"

