import XCTest
@testable import __APP_NAME__

final class __APP_NAME__Tests: XCTestCase {

    // MARK: - Example Tests

    func test_example_passes() {
        // Replace this with your first real test.
        XCTAssertTrue(true)
    }

    func test_example_async() async throws {
        // Example async test. Use `async throws` for tests that call async code.
        let value = await someAsyncHelper()
        XCTAssertEqual(value, 42)
    }

    // MARK: - Private

    private func someAsyncHelper() async -> Int {
        42
    }
}
