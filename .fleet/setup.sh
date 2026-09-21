#!/usr/bin/env bash
# Idempotent environment setup, run inside the sandbox before the agent.
set -euo pipefail

echo "[fleet] setting up what-to-click/desktop"

# setup/agent/verify run in separate ephemeral containers; only the workspace
# persists. Keep the pub cache inside the workspace (git-ignored) so the
# packages fetched here are still resolvable by verify/agent.
export PUB_CACHE="$PWD/.pub-cache"

flutter --version
flutter pub get

# The bundled plugin example is a separate package with its own deps;
# resolve them too so a root `flutter analyze` is clean.
(cd click_tracker/example && flutter pub get)

# Generated sources are git-ignored (*.g.dart, *.gr.dart, *.config.dart), so
# codegen must run before analyze/test can resolve the router and DI graph.
dart run build_runner build --delete-conflicting-outputs

echo "[fleet] setup complete"
