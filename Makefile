PROJECT := PRMenuBar.xcodeproj
SCHEME := PRMenuBar
DESTINATION := platform=macOS
DERIVED_DATA := build

.PHONY: generate format-check file-size-check build test coverage-report app-smoke ci-local clean

generate:
	xcodegen generate

format-check:
	./scripts/format-check.sh

file-size-check:
	./scripts/file-size-check.sh

build: generate
	xcodebuild build \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration Debug \
		-destination '$(DESTINATION)' \
		-derivedDataPath $(DERIVED_DATA) \
		CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO \
		OTHER_SWIFT_FLAGS='-warnings-as-errors'

test: generate
	rm -rf TestResults.xcresult
	xcodebuild test \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration Debug \
		-destination '$(DESTINATION)' \
		-derivedDataPath $(DERIVED_DATA) \
		CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO \
		-enableCodeCoverage YES \
		-resultBundlePath TestResults.xcresult

coverage-report:
	xcrun xccov view --report TestResults.xcresult

app-smoke: generate
	xcodebuild build \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration Release \
		-destination '$(DESTINATION)' \
		-derivedDataPath $(DERIVED_DATA) \
		CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO
	test -d "$(DERIVED_DATA)/Build/Products/Release/PRMenuBar.app"
	./scripts/app-smoke.sh "$(DERIVED_DATA)/Build/Products/Release/PRMenuBar.app"

ci-local: format-check file-size-check build test coverage-report app-smoke

clean:
	rm -rf $(DERIVED_DATA) TestResults.xcresult $(PROJECT)
