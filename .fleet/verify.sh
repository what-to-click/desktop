#!/usr/bin/env bash
# Code-quality gate, run inside the sandbox after each agent iteration.
# Exit 0 = pass. Anything non-zero feeds the failure back to the next iteration.
set -euo pipefail

# Match setup.sh: the pub cache lives in the workspace so it survives the
# container boundary between setup, agent and verify.
export PUB_CACHE="$PWD/.pub-cache"

echo "[fleet] verify: flutter analyze"
# The repo baseline carries pre-existing warnings/infos; only errors are fatal.
flutter analyze --no-fatal-warnings --no-fatal-infos

echo "[fleet] verify: flutter test"
flutter test
