# T005 Live GitHub Smoke

Live GitHub smoke was available through `gh auth status` for account `neonwatty`; the token was not printed except for GitHub CLI's masked status output.

Command shape:

```text
make build
PR_MENU_BAR_GITHUB_TOKEN=<from gh auth token> PR_MENU_BAR_INITIAL_STATE_DUMP_PATH=build/live-github-initial-state.json build/Build/Products/Debug/PRMenuBar.app/Contents/MacOS/PRMenuBar
```

Result: pass.

Initial state dump:

```json
{
  "activeRepositoryCount" : 14,
  "bucketTotals" : [
    79,
    45,
    47,
    46,
    71,
    54,
    1
  ],
  "dataSourceTitle" : "GitHub",
  "totalPullRequests" : 343,
  "visibleBucketLabels" : [
    "05/23",
    "05/24",
    "05/25",
    "05/26",
    "05/27",
    "05/28",
    "05/29"
  ]
}
```

No `refreshError` field was emitted.
