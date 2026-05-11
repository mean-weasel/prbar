#!/usr/bin/env bash
# Live provider fails to load → empty store + non-null refreshError in the dump.
# Triggered via PR_MENU_BAR_FIXTURE_PATH pointing at a path that doesn't exist,
# so FilePRActivityProvider throws inside PRInitialActivityState.load.
source "$(dirname "$0")/_lib.sh"

MISSING_FIXTURE="$TMP_DIR/does-not-exist.json"

smoke_launch PR_MENU_BAR_FIXTURE_PATH="$MISSING_FIXTURE"
smoke_wait_for_dump

smoke_assert_contains '"dataSourceTitle" : "GitHub"' "fixture path → GitHub provider selected"
smoke_assert_contains '"totalPullRequests" : 0' "failed load → empty store totals"
smoke_assert_contains '"activeRepositoryCount" : 0' "failed load → no active repos"
smoke_assert_contains '"refreshError" :' "refreshError field must be present"
smoke_assert_not_contains '"refreshError" : null' "refreshError must be non-null on failure"
