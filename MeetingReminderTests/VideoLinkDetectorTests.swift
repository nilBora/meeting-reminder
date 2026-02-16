import XCTest
@testable import MeetingReminder

final class VideoLinkDetectorTests: XCTestCase {

    // MARK: - findVideoURL(in:)

    func testFindsZoomLink() {
        let text = "Join at https://us04web.zoom.us/j/123456789"
        let url = VideoLinkDetector.findVideoURL(in: text)
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("zoom.us/j/"))
    }

    func testFindsGoogleMeetLink() {
        let text = "Meeting: https://meet.google.com/abc-defg-hij"
        let url = VideoLinkDetector.findVideoURL(in: text)
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("meet.google.com"))
    }

    func testFindsTeamsLink() {
        let text = "Click https://teams.microsoft.com/l/meetup-join/abc123 to join"
        let url = VideoLinkDetector.findVideoURL(in: text)
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("teams.microsoft.com"))
    }

    func testFindsWebexLink() {
        let text = "Webex: https://company.webex.com/meet/john.doe"
        let url = VideoLinkDetector.findVideoURL(in: text)
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("webex.com"))
    }

    func testFindsSlackHuddleLink() {
        let text = "Huddle: https://app.slack.com/huddle/T123/C456"
        let url = VideoLinkDetector.findVideoURL(in: text)
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("slack.com/huddle"))
    }

    func testReturnsNilForNoMatch() {
        let text = "No video link here, just a regular meeting in room 5B."
        XCTAssertNil(VideoLinkDetector.findVideoURL(in: text))
    }

    func testReturnsNilForEmptyString() {
        XCTAssertNil(VideoLinkDetector.findVideoURL(in: ""))
    }

    func testStripsTrailingParenthesis() {
        let text = "(https://us04web.zoom.us/j/123456789)"
        let url = VideoLinkDetector.findVideoURL(in: text)
        XCTAssertNotNil(url)
        XCTAssertFalse(url!.absoluteString.hasSuffix(")"))
    }

    func testStripsTrailingAngleBracket() {
        let text = "<https://meet.google.com/abc-defg-hij>"
        let url = VideoLinkDetector.findVideoURL(in: text)
        XCTAssertNotNil(url)
        XCTAssertFalse(url!.absoluteString.hasSuffix(">"))
    }

    func testStripsTrailingQuote() {
        let text = "\"https://us04web.zoom.us/j/123456789\""
        let url = VideoLinkDetector.findVideoURL(in: text)
        XCTAssertNotNil(url)
        XCTAssertFalse(url!.absoluteString.hasSuffix("\""))
    }

    // MARK: - isVideoLink(_:)

    func testIsVideoLinkReturnsTrueForZoom() {
        let url = URL(string: "https://us04web.zoom.us/j/123456789")!
        XCTAssertTrue(VideoLinkDetector.isVideoLink(url))
    }

    func testIsVideoLinkReturnsTrueForMeet() {
        let url = URL(string: "https://meet.google.com/abc-defg-hij")!
        XCTAssertTrue(VideoLinkDetector.isVideoLink(url))
    }

    func testIsVideoLinkReturnsFalseForRegularURL() {
        let url = URL(string: "https://www.google.com")!
        XCTAssertFalse(VideoLinkDetector.isVideoLink(url))
    }

    // MARK: - serviceName(for:)

    func testServiceNameZoom() {
        let url = URL(string: "https://us04web.zoom.us/j/123456789")!
        XCTAssertEqual(VideoLinkDetector.serviceName(for: url), "Zoom")
    }

    func testServiceNameGoogleMeet() {
        let url = URL(string: "https://meet.google.com/abc-defg-hij")!
        XCTAssertEqual(VideoLinkDetector.serviceName(for: url), "Google Meet")
    }

    func testServiceNameTeams() {
        let url = URL(string: "https://teams.microsoft.com/l/meetup-join/abc")!
        XCTAssertEqual(VideoLinkDetector.serviceName(for: url), "Teams")
    }

    func testServiceNameWebex() {
        let url = URL(string: "https://company.webex.com/meet/john")!
        XCTAssertEqual(VideoLinkDetector.serviceName(for: url), "Webex")
    }

    func testServiceNameSlack() {
        let url = URL(string: "https://app.slack.com/huddle/T123/C456")!
        XCTAssertEqual(VideoLinkDetector.serviceName(for: url), "Slack")
    }

    func testServiceNameUnknownReturnsMeeting() {
        let url = URL(string: "https://example.com/call")!
        XCTAssertEqual(VideoLinkDetector.serviceName(for: url), "Meeting")
    }
}
