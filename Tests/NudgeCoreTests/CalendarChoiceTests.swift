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

    func testResolveSavedIDWins() {
        let a = cal("a", "Work"), b = cal("b", "Home")
        XCTAssertEqual(CalendarChoice.resolve(savedID: "b", previous: a, from: [a, b]), .use(b))
    }

    func testResolveKeepsPrevious() {
        let a = cal("a", "Work"), b = cal("b", "alex@example.com")
        XCTAssertEqual(CalendarChoice.resolve(savedID: nil, previous: a, from: [b, a]), .use(a))
    }

    func testResolvePreviousGoneIsMissing() {
        let a = cal("a", "alex@example.com")
        XCTAssertEqual(CalendarChoice.resolve(savedID: nil, previous: a, from: [cal("b", "Work")]), .missing(a))
    }

    func testResolvePreviousGoneEmptyListIsMissing() {
        let a = cal("a", "alex@example.com")
        XCTAssertEqual(CalendarChoice.resolve(savedID: nil, previous: a, from: []), .missing(a))
    }

    func testResolveReaddedCalendarMatchesTitleAndSource() {
        let a = cal("a", "alex@example.com"), a2 = cal("a2", "alex@example.com")
        XCTAssertEqual(CalendarChoice.resolve(savedID: nil, previous: a, from: [cal("z", "Work"), a2]), .use(a2))
    }

    func testResolveAmbiguousTitleAndSourceIsMissing() {
        let a = cal("a", "alex@example.com")
        let list = [cal("a2", "alex@example.com"), cal("a3", "alex@example.com")]
        XCTAssertEqual(CalendarChoice.resolve(savedID: nil, previous: a, from: list), .missing(a))
    }

    func testResolveNoPreviousFallsBackToPick() {
        let b = cal("b", "alex@example.com")
        XCTAssertEqual(CalendarChoice.resolve(savedID: nil, previous: nil, from: [cal("a", "Work"), b]), .use(b))
        XCTAssertEqual(CalendarChoice.resolve(savedID: nil, previous: nil, from: []), .none)
    }
}
