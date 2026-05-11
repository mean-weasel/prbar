PROJECT := PRMenuBar.xcodeproj
SCHEME := PRMenuBar
DESTINATION := platform=macOS
DERIVED_DATA := build
APP_BINARY := $(DERIVED_DATA)/Build/Products/Debug/PRMenuBar.app/Contents/MacOS/PRMenuBar

.PHONY: generate format-check file-size-check build test coverage-report app-smoke run ci-local clean

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

# Direct exec (not `open`) so env vars propagate to ProcessInfo.processInfo.environment.
run: build
	@test -x "$(APP_BINARY)" || { echo "error: $(APP_BINARY) not found after build" >&2; exit 1; }
	@pkill -fx "$(APP_BINARY)" 2>/dev/null || true
	@{ "$(APP_BINARY)" </dev/null >/dev/null 2>&1 & \
	   PID=$$!; \
	   sleep 0.3; \
	   if kill -0 $$PID 2>/dev/null; then \
	     echo "PRMenuBar launched (pid $$PID). Click the menu bar icon."; \
	   else \
	     echo "error: PRMenuBar exited immediately (pid $$PID); check Console.app" >&2; \
	     exit 1; \
	   fi; }

ci-local: format-check file-size-check build test coverage-report app-smoke

clean:
	rm -rf $(DERIVED_DATA) TestResults.xcresult $(PROJECT)
