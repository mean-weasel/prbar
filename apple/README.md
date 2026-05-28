## Task 1 Verification

- Note: Task 1 originally asked for an empty app plist. To make simulator install and `xcodebuild test` pass, `apple/PRBar/Info.plist` now includes the minimal required bundle keys.
- Ran `./scripts/ios-generate.sh` successfully.
- Ran `xcodebuild build -project apple/PRBar.xcodeproj -scheme PRBar -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath apple/build CODE_SIGNING_ALLOWED=NO` successfully.
- Ran `xcodebuild test -project apple/PRBar.xcodeproj -scheme PRBar -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath apple/build CODE_SIGNING_ALLOWED=NO` successfully.
- `iPhone 16` was unavailable in local simulator destinations, so verification used `iPhone 17`.

## Physical iPhone Channels

PRBar has separate physical-device channels for preview testing and production-device installs.

- Preview app: `PRBarPreview`, bundle id `com.neonwatty.PRBar.ios.preview`, device default `iPhone-preview`.
- Production app: `PRBar`, bundle id `com.neonwatty.PRBar.ios`, device default `iPhone-prod`.

Use the preview workflows for CI-like physical smoke testing:

```bash
gh workflow run ios-preview-install.yml \
  --repo mean-weasel/prbar \
  --ref <branch> \
  -f device_name=iPhone-preview

gh workflow run ios-physical-preview.yml \
  --repo mean-weasel/prbar \
  --ref <branch> \
  -f smoke_profile=fast \
  -f device_name=iPhone-preview
```

Use the production workflows only when the production iPhone is connected, trusted, unlocked, and ready to receive the day-to-day app build:

```bash
gh workflow run ios-production-install.yml \
  --repo mean-weasel/prbar \
  --ref <branch> \
  -f device_name=iPhone-prod

gh workflow run ios-physical-production.yml \
  --repo mean-weasel/prbar \
  --ref <branch> \
  -f smoke_profile=fast \
  -f device_name=iPhone-prod
```

The production install workflow is also a lightweight launch smoke: after it verifies the built app bundle id is `com.neonwatty.PRBar.ios` and installs the app, it launches that bundle on the production iPhone with `devicectl`. The physical production workflow runs the fuller XCTest UI smoke and requires Automation Mode to initialize successfully on the phone.

The production scripts refuse to install if the built app bundle id is not `com.neonwatty.PRBar.ios`. If signing fails, fix Apple Developer provisioning or device registration rather than retrying with the preview bundle. If GitHub sign-in reports missing configuration, confirm `PRBAR_IOS_GITHUB_CLIENT_ID` is available to the workflow.

For a local build-and-bundle-id dry run that does not install on the phone:

```bash
IOS_SKIP_INSTALL=1 \
IOS_XCODEBUILD_EXTRA_ARGS=CODE_SIGNING_ALLOWED=NO \
./scripts/ios-production-install.sh
```
