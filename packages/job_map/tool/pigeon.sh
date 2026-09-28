#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

dart_out=lib/src/generated/job_map_api.g.dart
kotlin_out=android/src/main/kotlin/com/cataqui/job_map/JobMapApi.g.kt
swift_out=ios/job_map/Sources/job_map/JobMapApi.g.swift

if [[ "${1:-}" == "--check" ]]; then
  temp_dir=$(mktemp -d "$PWD/.pigeon-check.XXXXXX")
  trap 'rm -rf "$temp_dir"' EXIT
  fvm dart run pigeon \
    --input pigeons/job_map_api.dart \
    --dart_out "$temp_dir/job_map_api.g.dart" \
    --kotlin_out "$temp_dir/JobMapApi.g.kt" \
    --kotlin_package com.cataqui.job_map \
    --swift_out "$temp_dir/JobMapApi.g.swift"
  cmp "$dart_out" "$temp_dir/job_map_api.g.dart"
  cmp "$kotlin_out" "$temp_dir/JobMapApi.g.kt"
  cmp "$swift_out" "$temp_dir/JobMapApi.g.swift"
  exit
fi

fvm dart run pigeon \
  --input pigeons/job_map_api.dart \
  --dart_out "$dart_out" \
  --kotlin_out "$kotlin_out" \
  --kotlin_package com.cataqui.job_map \
  --swift_out "$swift_out"
