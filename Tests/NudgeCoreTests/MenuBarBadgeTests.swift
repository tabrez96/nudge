import XCTest
@testable import NudgeCore

final class MenuBarBadgeTests: XCTestCase {
    func testDotSitsInTopRightCorner() {
        let rect = MenuBarBadge.dotRect(in: CGSize(width: 16, height: 16))
        XCTAssertEqual(rect, CGRect(x: 10, y: 10, width: 6, height: 6))
        XCTAssertEqual(rect.maxX, 16)
        XCTAssertEqual(rect.maxY, 16)
    }

    func testDotStaysInsideImage() {
        for size in [CGSize(width: 16, height: 16), CGSize(width: 18, height: 17), CGSize(width: 20, height: 20)] {
            XCTAssertTrue(CGRect(origin: .zero, size: size).contains(MenuBarBadge.dotRect(in: size)))
        }
    }

    func testKnockoutSurroundsDotByGap() {
        let size = CGSize(width: 16, height: 16)
        let dot = MenuBarBadge.dotRect(in: size)
        let knockout = MenuBarBadge.knockoutRect(in: size)
        XCTAssertEqual(knockout, dot.insetBy(dx: -1.5, dy: -1.5))
        XCTAssertEqual(knockout.width, MenuBarBadge.dotDiameter + 3)
        XCTAssertTrue(knockout.contains(dot))
    }

    func testDotIsBigEnoughToRead() {
        XCTAssertGreaterThanOrEqual(MenuBarBadge.dotDiameter, 6)
    }
}
