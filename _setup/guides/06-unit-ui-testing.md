# 06 — Unit & UI Testing

Automated testing keeps your app from regressing as you add features. This covers XCTest (unit), XCUITest (UI), and how to run them locally and in CI.

---

## Test Targets

This template creates two test targets in `project.yml`:

- `__APP_NAME__Tests` — Unit tests (XCTest)
- `__APP_NAME__UITests` — UI tests (XCUITest, requires the app to run)

---

## Unit Tests (XCTest)

### Writing a Test

```swift
import XCTest
@testable import __APP_NAME__

final class HomeViewModelTests: XCTestCase {

    var sut: HomeViewModel!  // system under test

    override func setUp() async throws {
        try await super.setUp()
        sut = HomeViewModel()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    func test_loadItems_returnsItems() async throws {
        // Given
        let expectedCount = 3

        // When
        await sut.loadItems()

        // Then
        XCTAssertEqual(sut.items.count, expectedCount)
    }

    func test_loadItems_setsIsLoading() async {
        let task = Task { await sut.loadItems() }
        XCTAssertTrue(sut.isLoading)
        await task.value
        XCTAssertFalse(sut.isLoading)
    }

    func test_emptyState_whenNoItems() async {
        await sut.loadItems()
        XCTAssertTrue(sut.items.isEmpty)
    }
}
```

### Test Naming Convention

Use `test_methodName_expectedBehavior_whenCondition`:
- `test_login_succeeds_withValidCredentials`
- `test_login_fails_withInvalidPassword`

### Async Tests

Swift's `async/await` is natively supported in XCTest:

```swift
func test_fetchData() async throws {
    let result = try await sut.fetchData()
    XCTAssertNotNil(result)
}
```

### Testing With Mocks

Inject dependencies via protocols to make them mockable:

```swift
protocol ItemServiceProtocol {
    func fetchAll() async throws -> [Item]
}

// Mock
final class MockItemService: ItemServiceProtocol {
    var stubbedItems: [Item] = []
    var fetchCallCount = 0

    func fetchAll() async throws -> [Item] {
        fetchCallCount += 1
        return stubbedItems
    }
}

// Test
func test_loadItems_callsService() async throws {
    let mockService = MockItemService()
    mockService.stubbedItems = [Item(name: "Test")]
    sut = HomeViewModel(service: mockService)

    await sut.loadItems()

    XCTAssertEqual(mockService.fetchCallCount, 1)
    XCTAssertEqual(sut.items.count, 1)
}
```

---

## UI Tests (XCUITest)

UI tests launch the real app and simulate user interactions.

### Basic UI Test

```swift
import XCTest

final class HomeUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["--uitesting"]  // flag to app to use test data
        app.launch()
    }

    func test_homeScreen_showsTitle() {
        XCTAssertTrue(app.navigationBars["Home"].exists)
    }

    func test_tappingAddButton_showsForm() {
        app.buttons["Add Item"].tap()
        XCTAssertTrue(app.sheets.firstMatch.exists)
    }

    func test_addItem_appearsInList() {
        app.buttons["Add Item"].tap()
        app.textFields["Item Name"].tap()
        app.textFields["Item Name"].typeText("My New Item")
        app.buttons["Save"].tap()

        XCTAssertTrue(app.cells.staticTexts["My New Item"].exists)
    }
}
```

### Accessibility Identifiers

Set `.accessibilityIdentifier` on views to make UI tests robust (not dependent on display text):

```swift
// In your view
Button("Add") { ... }
    .accessibilityIdentifier("addItemButton")

// In your test
app.buttons["addItemButton"].tap()
```

### Launch Arguments for Testing

Pass flags from UI tests to the app:

```swift
// Test
app.launchArguments = ["--uitesting", "--reset-state"]
app.launch()

// App
if CommandLine.arguments.contains("--uitesting") {
    // Use mock data, reset user defaults, etc.
}
```

### Waiting for Elements

```swift
// Wait up to 5 seconds for element to appear
let button = app.buttons["Submit"]
XCTAssertTrue(button.waitForExistence(timeout: 5))
button.tap()
```

---

## Running Tests

### In Xcode

- ⌘U — run all tests
- Click the diamond icon next to a test class or method to run just that test
- Test Navigator (⌘6) — see all tests and their status

### Command Line

```bash
# Run all tests
xcodebuild test \
  -project App/__APP_NAME__.xcodeproj \
  -scheme __APP_NAME__ \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
  2>&1 | xcpretty

# Run a specific test class
xcodebuild test \
  -project App/__APP_NAME__.xcodeproj \
  -scheme __APP_NAME__ \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
  -only-testing:__APP_NAME__Tests/HomeViewModelTests

# Run with result bundle for CI
xcodebuild test \
  -project App/__APP_NAME__.xcodeproj \
  -scheme __APP_NAME__ \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
  -resultBundlePath TestResults.xcresult

# Pretty output (requires: gem install xcpretty)
xcodebuild test ... 2>&1 | xcpretty --test --color
```

### Via fastlane

```bash
bundle exec fastlane test
```

Defined in `fastlane/Fastfile`:
```ruby
lane :test do
  run_tests(
    project: "App/__APP_NAME__.xcodeproj",
    scheme: "__APP_NAME__",
    devices: ["iPhone 16 Pro"],
    clean: true
  )
end
```

---

## Test Plans

Test Plans (`.xctestplan`) let you run different subsets of tests with different settings. Create one in Xcode:

1. Product → Test Plan → New Test Plan
2. Add test targets
3. Configure: parallel execution, randomization, code coverage, environment variables

Use test plans in CI to run fast unit tests on every commit and slow UI tests only on PRs.

---

## Code Coverage

Enable in the scheme:

1. Product → Scheme → Edit Scheme → Test → Options
2. Check "Gather coverage for all targets"

View coverage after running tests:
- Xcode → Report navigator (⌘9) → your test run → Coverage tab

Or generate a coverage report:
```bash
xcrun xccov view --report TestResults.xcresult
```

---

## Snapshot Testing (Optional)

Snapshot tests capture a view's rendered output and fail if it changes. Useful for UI regression testing.

Popular library: [pointfreeco/swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing)

Add to `project.yml`:
```yaml
packages:
  swift-snapshot-testing:
    url: https://github.com/pointfreeco/swift-snapshot-testing
    from: 1.15.0
```

```swift
import SnapshotTesting

func test_homeView_snapshot() {
    let view = HomeView()
    assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13Pro)))
}
```

Run once to generate reference images, then snapshots fail if the UI changes unexpectedly.

---

## Testing Best Practices

1. **Test behavior, not implementation** — test what the code does, not how
2. **One assertion per test** (roughly) — makes failures easy to diagnose
3. **Fast tests run more often** — keep unit tests < 0.1s each; UI tests are fine to be slower
4. **No network in unit tests** — mock all external dependencies
5. **Deterministic tests** — no random data, no time-dependent assertions without mocking `Date`
6. **Name tests clearly** — future you will thank you
7. **Test the unhappy path** — error states, empty states, edge cases
8. **Don't test Apple's frameworks** — test your code, not UIKit/SwiftUI internals
