#!/usr/bin/env bash
# scripts/pre_push_check.sh — lefthook 미사용 시 수동 게이트.
# 사용:
#   1) 수동: bash scripts/pre_push_check.sh
#   2) git pre-push 후크: ln -sf ../../scripts/pre_push_check.sh .git/hooks/pre-push
#
# test_flutter_playspot.md §0-3.
set -euo pipefail

cd "$(dirname "$0")/.."
echo "▶ flutter analyze"
( cd flutter_ar_spike && flutter analyze )

echo "▶ flutter test"
( cd flutter_ar_spike && flutter test )

echo "✓ pre-push 검증 통과"
