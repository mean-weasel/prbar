#!/usr/bin/env bash
# Sample-data path: no token, no fixture, no gh fallback — the
# StaticPRActivityProvider runs.
source "$(dirname "$0")/_lib.sh"

smoke_launch PR_MENU_BAR_DISABLE_GH_AUTH=1
smoke_wait_for_dump

smoke_assert_contains '"dataSourceTitle" : "Sample Data"' "no env → sample data"
smoke_assert_not_contains '"totalPullRequests" : 0' "sample data should be non-zero"
smoke_assert_not_contains '"activeRepositoryCount" : 0' "sample data should have active repos"
smoke_assert_not_contains '"refreshError"' "sample path should not surface refreshError"
