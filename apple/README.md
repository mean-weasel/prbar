## Task 1 Verification

- Note: Task 1 originally asked for an empty app plist. To make simulator install and `xcodebuild test` pass, `apple/PRBar/Info.plist` now includes the minimal required bundle keys.
- Ran `./scripts/ios-generate.sh` successfully.
- Ran `xcodebuild build -project apple/PRBar.xcodeproj -scheme PRBar -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath apple/build CODE_SIGNING_ALLOWED=NO` successfully.
- Ran `xcodebuild test -project apple/PRBar.xcodeproj -scheme PRBar -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath apple/build CODE_SIGNING_ALLOWED=NO` successfully.
- `iPhone 16` was unavailable in local simulator destinations, so verification used `iPhone 17`.
