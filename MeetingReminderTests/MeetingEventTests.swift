import XCTest
@testable import MeetingReminder

final class MeetingEventTests: XCTestCase {

    private func makeEvent(startingIn minutes: Double, duration: Double = 30) -> MeetingEvent {
        let start = Date().addingTimeInterval(minutes * 60)
        let end = start.addingTimeInterval(duration * 60)
        return MeetingEvent(
            id: "test-\(UUID().uuidString)",
            title: "Test Meeting",
            startDate: start,
            endDate: end,
            calendar: "Work"
        )
    }

    // MARK: - formattedTimeUntil

    func testFormattedTimeUntilNow() {
        let event = makeEvent(startingIn: -1)
        XCTAssertEqual(event.formattedTimeUntil, "Now")
    }

    func testFormattedTimeUntilOneMinute() {
        // ceil of 0.5 min = 1
        let event = makeEvent(startingIn: 0.5)
        XCTAssertEqual(event.formattedTimeUntil, "1 minute")
    }

    func testFormattedTimeUntilMultipleMinutes() {
        let event = makeEvent(startingIn: 5)
        XCTAssertEqual(event.formattedTimeUntil, "5 minutes")
    }

    func testFormattedTimeUntilZeroMinutes() {
        let event = makeEvent(startingIn: 0)
        XCTAssertEqual(event.formattedTimeUntil, "Now")
    }

    func testFormattedTimeUntilExactHour() {
        let event = makeEvent(startingIn: 60)
        XCTAssertEqual(event.formattedTimeUntil, "1 h")
    }

    func testFormattedTimeUntilHoursAndMinutes() {
        let event = makeEvent(startingIn: 90)
        XCTAssertEqual(event.formattedTimeUntil, "1 h 30 min")
    }

    func testFormattedTimeUntilMultipleHours() {
        let event = makeEvent(startingIn: 150)
        XCTAssertEqual(event.formattedTimeUntil, "2 h 30 min")
    }

    // MARK: - minutesUntilStart

    func testMinutesUntilStartPositive() {
        let event = makeEvent(startingIn: 10)
        XCTAssertEqual(event.minutesUntilStart, 10)
    }

    func testMinutesUntilStartNegative() {
        let event = makeEvent(startingIn: -5)
        XCTAssertTrue(event.minutesUntilStart < 0)
    }

    func testMinutesUntilStartCeils() {
        // 2.1 minutes → ceil = 3
        let event = makeEvent(startingIn: 2.1)
        XCTAssertEqual(event.minutesUntilStart, 3)
    }

    // MARK: - isHappeningSoon

    func testIsHappeningSoonWithin10Minutes() {
        let event = makeEvent(startingIn: 5)
        XCTAssertTrue(event.isHappeningSoon)
    }

    func testIsHappeningSoonFarFuture() {
        let event = makeEvent(startingIn: 60)
        XCTAssertFalse(event.isHappeningSoon)
    }

    func testIsHappeningSoonAlreadyStarted() {
        let event = makeEvent(startingIn: -1)
        XCTAssertFalse(event.isHappeningSoon)
    }

    // MARK: - isInProgress

    func testIsInProgressDuringMeeting() {
        let event = makeEvent(startingIn: -5, duration: 30)
        XCTAssertTrue(event.isInProgress)
    }

    func testIsInProgressBeforeMeeting() {
        let event = makeEvent(startingIn: 10, duration: 30)
        XCTAssertFalse(event.isInProgress)
    }

    func testIsInProgressAfterMeeting() {
        let event = makeEvent(startingIn: -60, duration: 30)
        XCTAssertFalse(event.isInProgress)
    }

    // MARK: - formattedStartTime

    func testFormattedStartTimeNotEmpty() {
        let event = makeEvent(startingIn: 5)
        XCTAssertFalse(event.formattedStartTime.isEmpty)
    }

    // MARK: - Equatable

    func testEqualityBasedOnId() {
        let event1 = MeetingEvent(id: "same", title: "A", startDate: Date(), endDate: Date(), calendar: "X")
        let event2 = MeetingEvent(id: "same", title: "B", startDate: Date(), endDate: Date(), calendar: "Y")
        XCTAssertEqual(event1, event2)
    }

    func testInequalityDifferentIds() {
        let event1 = MeetingEvent(id: "a", title: "A", startDate: Date(), endDate: Date(), calendar: "X")
        let event2 = MeetingEvent(id: "b", title: "A", startDate: Date(), endDate: Date(), calendar: "X")
        XCTAssertNotEqual(event1, event2)
    }
}
