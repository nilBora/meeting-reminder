import XCTest
@testable import MeetingReminder

final class ReminderFilterTests: XCTestCase {

    private func triggers(
        title: String = "Sync",
        hasVideoLink: Bool = false,
        otherAttendeeCount: Int = 0,
        isFree: Bool = false,
        meetingsOnly: Bool = false,
        skipFree: Bool = false,
        excludedKeywords: [String] = []
    ) -> Bool {
        ReminderFilter.triggersReminder(
            title: title,
            hasVideoLink: hasVideoLink,
            otherAttendeeCount: otherAttendeeCount,
            isFree: isFree,
            meetingsOnly: meetingsOnly,
            skipFree: skipFree,
            excludedKeywords: excludedKeywords
        )
    }

    // MARK: - Defaults

    func testEverythingOffAlwaysTriggers() {
        XCTAssertTrue(triggers())
        XCTAssertTrue(triggers(isFree: true))
    }

    // MARK: - Meetings only

    func testMeetingsOnlyRejectsEventWithNoLinkAndNoAttendees() {
        XCTAssertFalse(triggers(meetingsOnly: true))
    }

    func testMeetingsOnlyAcceptsVideoLink() {
        XCTAssertTrue(triggers(hasVideoLink: true, meetingsOnly: true))
    }

    func testMeetingsOnlyAcceptsOtherAttendee() {
        XCTAssertTrue(triggers(otherAttendeeCount: 1, meetingsOnly: true))
    }

    func testMeetingsOnlyOffIgnoresMissingLinkAndAttendees() {
        XCTAssertTrue(triggers(meetingsOnly: false))
    }

    // MARK: - Skip free

    func testSkipFreeRejectsFreeEvent() {
        XCTAssertFalse(triggers(isFree: true, skipFree: true))
    }

    func testSkipFreeKeepsBusyEvent() {
        XCTAssertTrue(triggers(isFree: false, skipFree: true))
    }

    func testFreeEventTriggersWhenSkipFreeOff() {
        XCTAssertTrue(triggers(isFree: true, skipFree: false))
    }

    func testSkipFreeRejectsFreeEventEvenWithVideoLink() {
        XCTAssertFalse(triggers(hasVideoLink: true, isFree: true, skipFree: true))
    }

    // MARK: - Keywords

    func testKeywordMatchRejects() {
        XCTAssertFalse(triggers(title: "Team Lunch", excludedKeywords: ["lunch"]))
    }

    func testKeywordMatchIsCaseInsensitive() {
        XCTAssertFalse(triggers(title: "FOCUS time", excludedKeywords: ["focus"]))
        XCTAssertFalse(triggers(title: "focus time", excludedKeywords: ["FOCUS"]))
    }

    func testKeywordMatchIsDiacriticInsensitive() {
        XCTAssertFalse(triggers(title: "Café break", excludedKeywords: ["cafe"]))
    }

    func testKeywordMatchAppliesEvenWhenMeetingsOnlyOff() {
        XCTAssertFalse(triggers(title: "Focus", meetingsOnly: false, excludedKeywords: ["focus"]))
    }

    func testKeywordMatchRejectsEvenWithVideoLink() {
        XCTAssertFalse(triggers(title: "Lunch call", hasVideoLink: true, excludedKeywords: ["lunch"]))
    }

    func testNonMatchingKeywordDoesNotReject() {
        XCTAssertTrue(triggers(title: "Standup", excludedKeywords: ["lunch", "focus"]))
    }

    func testEmptyKeywordDoesNotMatchEverything() {
        XCTAssertTrue(triggers(title: "Standup", excludedKeywords: [""]))
    }

    // MARK: - parseKeywords

    func testParseKeywordsSplitsAndTrims() {
        XCTAssertEqual(ReminderFilter.parseKeywords("Focus, Lunch, Block"), ["Focus", "Lunch", "Block"])
    }

    func testParseKeywordsDropsEmptyEntries() {
        XCTAssertEqual(ReminderFilter.parseKeywords(" , Focus ,, lunch "), ["Focus", "lunch"])
    }

    func testParseKeywordsEmptyString() {
        XCTAssertEqual(ReminderFilter.parseKeywords(""), [])
        XCTAssertEqual(ReminderFilter.parseKeywords("  ,  "), [])
    }
}
