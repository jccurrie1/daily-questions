#!/bin/sh
set -eu
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
check_dir=$(mktemp -d "${TMPDIR:-/tmp}/daily-questions-report.XXXXXX")
trap 'rm -rf "$check_dir"' EXIT HUP INT TERM
xcrun swiftc -swift-version 6 -parse-as-library -target arm64-apple-macos26.0 \
    -module-cache-path "$check_dir/modules" \
    "$repo_dir/DailyQuestions/Models.swift" "$repo_dir/DailyQuestions/PerformanceView.swift" \
    "$repo_dir/Tests/ReportWeekCheck.swift" -o "$check_dir/report-checks"
"$check_dir/report-checks"
