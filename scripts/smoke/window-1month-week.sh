#!/usr/bin/env bash
# 1 month + Week aggregates the rolling 30 dailyCounts into seven-day groups.
source "$(dirname "$0")/_lib.sh"

FIXTURE_PATH="$TMP_DIR/fixture.json"
cat >"$FIXTURE_PATH" <<'JSON'
{
  "bucketLabels": ["W1", "W2", "W3", "W4"],
  "dailyBucketLabels": [
    "04/28", "04/29", "04/30", "05/01", "05/02", "05/03", "05/04",
    "05/05", "05/06", "05/07", "05/08", "05/09", "05/10", "05/11",
    "05/12", "05/13", "05/14", "05/15", "05/16", "05/17", "05/18",
    "05/19", "05/20", "05/21", "05/22", "05/23", "05/24", "05/25",
    "05/26", "05/27"
  ],
  "window": "1 month",
  "bin": "Week",
  "refreshInterval": "Daily",
  "repositories": [
    {
      "id": "test/window",
      "owner": "test",
      "name": "window",
      "colorHex": "#abc123",
      "weeklyCounts": [10, 20, 30, 40],
      "dailyCounts": [
        1, 1, 1, 1, 1, 1, 1,
        2, 2, 2, 2, 2, 2, 2,
        3, 3, 3, 3, 3, 3, 3,
        4, 4, 4, 4, 4, 4, 4,
        5, 5
      ],
      "isIncluded": true
    }
  ],
  "refreshedAt": 1777924800
}
JSON

smoke_launch PR_MENU_BAR_FIXTURE_PATH="$FIXTURE_PATH"
smoke_wait_for_dump

smoke_assert_contains '"dataSourceTitle" : "GitHub"' "fixture should select GitHub provider"
smoke_assert_contains '"totalPullRequests" : 80' "1 month / Week should sum the rolling 30 daily buckets"
smoke_assert_contains '"activeRepositoryCount" : 1'
smoke_assert_dump_contains_block '  "bucketTotals" : [
    7,
    14,
    21,
    28,
    10
  ],' "bucketTotals must equal rolling seven-day groups in order"
smoke_assert_dump_contains_block '  "visibleBucketLabels" : [
    "04\/28-05\/04",
    "05\/05-05\/11",
    "05\/12-05\/18",
    "05\/19-05\/25",
    "05\/26-05\/27"
  ]' "visibleBucketLabels must equal rolling seven-day ranges in order"
