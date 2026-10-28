import XCTest
@testable import NudgeCore

final class AppInfoTests: XCTestCase {
    func testAppNameIsNudge() {
        XCTAssertEqual(AppInfo.name, "Nudge")
    }

    func testVersionIsNotEmpty() {
        XCTAssertFalse(AppInfo.version.isEmpty)
    }
}
