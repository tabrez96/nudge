import XCTest
@testable import NudgeCore

private let packageRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

final class BundleFilesTests: XCTestCase {
    private var scriptPath: String { packageRoot.appendingPathComponent("scripts/make-app.sh").path }

    private func infoPlist() throws -> [String: Any] {
        let data = try Data(contentsOf: packageRoot.appendingPathComponent("Support/Info.plist"))
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        return try XCTUnwrap(plist as? [String: Any])
    }

    func testInfoPlistIsMenuBarApp() throws {
        XCTAssertEqual(try infoPlist()["LSUIElement"] as? Bool, true)
    }

    func testInfoPlistHasBothCalendarUsageStrings() throws {
        let plist = try infoPlist()
        for key in ["NSCalendarsUsageDescription", "NSCalendarsFullAccessUsageDescription"] {
            let text = try XCTUnwrap(plist[key] as? String, key)
            XCTAssertFalse(text.isEmpty, key)
        }
    }

    func testInfoPlistIdentityMatchesApp() throws {
        let plist = try infoPlist()
        XCTAssertEqual(plist["CFBundleExecutable"] as? String, AppInfo.name)
        XCTAssertEqual(plist["CFBundleShortVersionString"] as? String, AppInfo.version)
        XCTAssertFalse((plist["CFBundleIdentifier"] as? String ?? "").isEmpty)
    }

    func testMakeAppScriptIsExecutable() {
        XCTAssertTrue(FileManager.default.isExecutableFile(atPath: scriptPath))
    }

    func testMakeAppScriptCopiesBinaryAndInfoPlist() throws {
        let text = try String(contentsOfFile: scriptPath, encoding: .utf8)
        for needle in ["Contents/MacOS/Nudge", "Support/Info.plist", "Contents/Info.plist",
                       "codesign --force --sign -"] {
            XCTAssertTrue(text.contains(needle), needle)
        }
    }
}
