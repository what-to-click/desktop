#!/usr/bin/env bash
# Idempotent environment setup, run inside the sandbox before the agent.
set -euo pipefail

echo "[fleet] setting up what-to-click/desktop"

flutter --version
flutter pub get

# Generated sources are git-ignored (*.g.dart, *.gr.dart, *.config.dart), so
# codegen must run before analyze/test can resolve the router and DI graph.
dart run build_runner build --delete-conflicting-outputs

echo "[fleet] setup complete"
