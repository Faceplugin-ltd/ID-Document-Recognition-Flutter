#!/usr/bin/env bash
# Optional macOS helper — prefer: dart run tool/bootstrap.dart
# (Podfile creates the xcframework with xcodebuild directly; no bash required there.)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
exec dart run tool/bootstrap.dart
