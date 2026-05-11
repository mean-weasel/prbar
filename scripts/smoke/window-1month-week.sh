#!/usr/bin/env bash
# 1 month + Week aggregates the last 4 weeklyCounts. 10+20+30+40 = 100.
source "$(dirname "$0")/_lib.sh"

FIXTURE_PATH="$TMP_DIR/fixture.json"
cat >"$FIXTURE_PATH" <<'JSON'
{
  "bucketLabels": ["W1", "W2", "W3", "W4"],
  "dailyBucketLabels": ["d1", "d2", "d3", "d4", "d5", "d6", "d7"],
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
      "dailyCounts": [0, 0, 0, 0, 0, 0, 0],
      "isIncluded": true
    }
  ],
  "refreshedAt": 1777924800
}
JSON

smoke_launch PR_MENU_BAR_FIXTURE_PATH="$FIXTURE_PATH"
smoke_wait_for_dump

smoke_assert_contains '"dataSourceTitle" : "GitHub"' "fixture should select GitHub provider"
smoke_assert_contains '"totalPullRequests" : 100' "1 month / Week should sum all 4 visible buckets"
smoke_assert_contains '"activeRepositoryCount" : 1'
smoke_assert_dump_contains_block '  "bucketTotals" : [
    10,
    20,
    30,
    40
  ],' "bucketTotals must equal [10,20,30,40] in that order — total alone would pass for any aggregation summing to 100"
smoke_assert_dump_contains_block '  "visibleBucketLabels" : [
    "W1",
    "W2",
    "W3",
    "W4"
  ]' "visibleBucketLabels must equal [W1,W2,W3,W4] in that order"
