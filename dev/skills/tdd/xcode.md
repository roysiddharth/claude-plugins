# Xcode / Swift TDD

## Infrastructure Prerequisite

**A test target must exist before the first RED cycle.** Many Xcode projects ship without one.
Identify this during planning and resolve it first.

### Does a test target exist?

```bash
grep -c "unit-test" MyApp.xcodeproj/project.pbxproj
```

Zero means no test target. Add one before proceeding.

### Adding a test target (modern Xcode, pbxproj)

Modern Xcode uses `PBXFileSystemSynchronizedRootGroup` — the test directory is auto-discovered,
so you don't need to list individual source files in the pbxproj.

Minimum entries needed in `project.pbxproj`:

| Entry | Purpose |
|---|---|
| `PBXFileSystemSynchronizedRootGroup` for `AppTests/` | auto-discovers test files |
| `PBXNativeTarget` (product type `bundle.unit-test`) | the test target |
| `PBXSourcesBuildPhase` (empty `files`) | populated by sync group |
| `PBXFrameworksBuildPhase` with XCTest.framework | links XCTest |
| `PBXContainerItemProxy` + `PBXTargetDependency` | builds app first |
| `XCBuildConfiguration` Debug + Release | target build settings |
| `XCConfigurationList` | wires configs to target |

Critical build settings for the test target:

```
BUNDLE_LOADER = "$(TEST_HOST)"
TEST_HOST = "$(BUILT_PRODUCTS_DIR)/MyApp.app/Contents/MacOS/MyApp"
GENERATE_INFOPLIST_FILE = YES
```

`BUNDLE_LOADER` + `TEST_HOST` makes this a *hosted* unit test — the test bundle loads inside the
running app, giving `@testable import MyApp` access to all `internal` symbols.

`ENABLE_TESTABILITY = YES` must be set at the project or app-target level (default for Debug).

### Running RED/GREEN

**Verify compile errors (RED):**

```bash
xcodebuild -project MyApp.xcodeproj -target MyAppTests build \
  CODE_SIGNING_ALLOWED=NO 2>&1 | grep "error:"
```

**Verify build succeeds (GREEN):**

```bash
xcodebuild -project MyApp.xcodeproj -target MyAppTests build \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -3
# → ** BUILD SUCCEEDED **
```

**Full test run** (requires valid signing + macOS destination):

```bash
xcodebuild test -project MyApp.xcodeproj -scheme MyApp \
  -destination 'platform=macOS'
```

`CODE_SIGNING_ALLOWED=NO` skips signing so build errors are visible even without a
development certificate — useful in the RED loop and in environments without Xcode credentials.

---

## AppKit Constraints

**`NSNavigationController` does not exist in AppKit.** It is UIKit-only.
For macOS push navigation, use a custom `NSViewController` container:

```swift
class NavigationContainer: NSViewController {
    private var stack: [NSViewController] = []
    var stackDepth: Int { stack.count }
    var topViewController: NSViewController? { stack.last }

    func push(_ vc: NSViewController) { ... }
    func pop() { guard stack.count > 1 else { return }; ... }
}
```

This is testable: `isViewLoaded` is `false` in unit tests, so UI transitions no-op
while the stack logic runs and is fully assertable.

**`NSWindow`, `NSScreen`, `NSPanel`** — don't test framework behavior. Test the logic *around* it.
Example: frame persistence (UserDefaults read/write) is independently testable without a real window.

**Sandbox**: In sandboxed apps, `NSHomeDirectory()` returns the app sandbox container
(`~/Library/Containers/<bundle-id>/Data`), not the user's real home directory.
Account for this when testing file-creation paths.

**`INFOPLIST_KEY_*` build settings** — Info.plist values like `LSUIElement` and
`NSScreenCaptureUsageDescription` are set as `INFOPLIST_KEY_LSUIElement` and
`INFOPLIST_KEY_NSScreenCaptureUsageDescription` in build settings, not directly in the plist file
when `GENERATE_INFOPLIST_FILE = YES`.

---

## Patterns

### Free functions over AppDelegate methods

`AppDelegate` is hard to instantiate in tests — it triggers `NSApplication` initialization.
Extract testable logic as free functions that the delegate calls:

```swift
// Testable in isolation via @testable import
func ensureDirectory(at url: URL) throws { ... }
func saveWindowFrame(_ rect: NSRect, to defaults: UserDefaults = .standard) { ... }
func restoreWindowFrame(from defaults: UserDefaults = .standard) -> NSRect? { ... }

// AppDelegate just calls them
func applicationDidFinishLaunching(_ notification: Notification) {
    try? ensureDirectory(at: appDirectoryURL)
    ...
}
```

### Isolate UserDefaults between tests

Never write to `UserDefaults.standard` in tests — it persists across runs.
Use a named suite and clear it in `tearDown`:

```swift
class WindowFrameTests: XCTestCase {
    var defaults: UserDefaults!
    var suiteName: String!

    override func setUp() {
        suiteName = "com.myapp.tests.\(UUID())"
        defaults = UserDefaults(suiteName: suiteName)!
    }
    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }
}
```

### Isolate the file system between tests

Use a unique temp directory per test case, cleaned up in `tearDown`:

```swift
var testDir: URL!

override func setUp() {
    testDir = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
}
override func tearDown() {
    try? FileManager.default.removeItem(at: testDir)
}
```
