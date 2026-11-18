#!/usr/bin/env bash
# PolyCode Local & Release Web Build Script
set -e

echo "=== Building PolyCode Flutter Web Playground ==="

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXAMPLE_DIR="$ROOT_DIR/example"

cd "$EXAMPLE_DIR"

echo "-> Fetching dependencies..."
flutter pub get

echo "-> Running static analysis..."
flutter analyze

echo "-> Compiling Flutter Web release bundle..."
flutter build web --release --base-href "/PolyCode/"

echo "-> Ensuring .nojekyll exists..."
touch "$EXAMPLE_DIR/build/web/.nojekyll"

echo "-> Verifying Web Worker assets..."
ls -la "$EXAMPLE_DIR/build/web/workers"

echo "=== Build Complete: $EXAMPLE_DIR/build/web ==="
