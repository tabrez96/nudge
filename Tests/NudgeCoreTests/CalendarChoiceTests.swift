import XCTest
@testable import NudgeCore

final class CalendarChoiceTests: XCTestCase {
    private func cal(_ id: String, _ title: String) -> CalendarInfo {
        CalendarInfo(id: id, title: title, sourceTitle: "Google")
    }

    func testSavedIDPresentIsChosen() {
        let list = [cal("a", "alex@example.com"), cal("b", "Work")]
        XCTAssertEqual(CalendarChoice.pick(savedID: "b", from: list)?.id, "b")
    }

    func testSavedIDGoneFallsBackToEmailTitled() {
        let list = [cal("a", "Work"), cal("b", "alex@example.com")]
        XCTAssertEqual(CalendarChoice.pick(savedID: "gone", from: list)?.id, "b")
    }

    func testNilSavedIDPicksEmailTitled() {
        let list = [cal("a", "Work"), cal("b", "alex@example.com"), cal("c", "sam@example.com")]
        XCTAssertEqual(CalendarChoice.pick(savedID: nil, from: list)?.title, "alex@example.com")
    }

    func testFallbackToFirstWhenNoEmailTitle() {
        let list = [cal("a", "Work"), cal("b", "Home")]
        XCTAssertEqual(CalendarChoice.pick(savedID: nil, from: list)?.title, "Work")
    }

    func testEmptyListReturnsNil() {
        XCTAssertNil(CalendarChoice.pick(savedID: "a", from: []))
    }

    func testLooksLikeEmail() {
        XCTAssertTrue(CalendarChoice.looksLikeEmail("alex@example.com"))
        for text in ["Work", "a@b", "@example.com", "alex@.com", "alex@example.", "a b@example.com", "a@b@c.com", ""] {
            XCTAssertFalse(CalendarChoice.looksLikeEmail(text), text)
        }
    }
}
