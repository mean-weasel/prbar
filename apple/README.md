## Task 1 Verification

- Ran `./scripts/ios-generate.sh` successfully.
- Ran `xcodebuild build -project apple/PRBar.xcodeproj -scheme PRBar -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath apple/build CODE_SIGNING_ALLOWED=NO` successfully.
- `iPhone 16` was unavailable in local simulator destinations, so verification used `iPhone 17`.
