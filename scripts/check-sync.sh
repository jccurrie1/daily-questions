#!/bin/sh
set -eu
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
check_dir=$(mktemp -d "${TMPDIR:-/tmp}/daily-questions-sync.XXXXXX")
trap 'rm -rf "$check_dir"' EXIT HUP INT TERM
xcrun swiftc -swift-version 6 -parse-as-library -target arm64-apple-macos26.0 \
    -module-cache-path "$check_dir/modules" \
    "$repo_dir/DailyQuestions/Models.swift" "$repo_dir/DailyQuestions/Sync.swift" "$repo_dir/Tests/SyncChecks.swift" \
    -o "$check_dir/sync-checks"
"$check_dir/sync-checks"
