#!/usr/bin/env bash
# Baseline: known fixture loads cleanly via FilePRActivityProvider.
source "$(dirname "$0")/_lib.sh"

FIXTURE_PATH="$TMP_DIR/fixture.json"
cat >"$FIXTURE_PATH" <<'JSON'
{
  "bucketLabels": ["04/26"],
  "dailyBucketLabels": ["04/29", "04/30", "05/01", "05/02", "05/03", "05/04", "05/05"],
  "window": "1 week",
  "bin": "Day",
  "refreshInterval": "Daily",
  "repositories": [
    {
      "id": "mean-weasel/deckchecker",
      "owner": "mean-weasel",
      "name": "deckchecker",
      "colorHex": "#818cf8",
      "weeklyCounts": [9],
      "dailyCounts": [0, 0, 0, 0, 0, 9, 0],
      "isIncluded": true
    }
  ],
  "refreshedAt": 1777924800
}
JSON

smoke_launch PR_MENU_BAR_FIXTURE_PATH="$FIXTURE_PATH"
smoke_wait_for_dump

smoke_assert_contains '"dataSourceTitle" : "GitHub"' "fixture should select GitHub provider"
smoke_assert_contains '"totalPullRequests" : 9' "fixture total should be 9"
smoke_assert_contains '"activeRepositoryCount" : 1' "fixture should have 1 active repo"
smoke_assert_contains '"bucketTotals" : [' "bucketTotals array must be present"
smoke_assert_not_contains '"totalPullRequests" : 462' "fixture should not produce sample-data totals"
