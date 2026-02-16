import XCTest
@testable import MeetingReminder

final class OverlayBackgroundTests: XCTestCase {

    func testAllCasesCount() {
        XCTAssertEqual(OverlayBackground.allCases.count, 9)
    }

    func testDisplayNameNotEmpty() {
        for bg in OverlayBackground.allCases {
            XCTAssertFalse(bg.displayName.isEmpty, "\(bg.rawValue) has empty displayName")
        }
    }

    func testRawValueRoundTrip() {
        for bg in OverlayBackground.allCases {
            let restored = OverlayBackground(rawValue: bg.rawValue)
            XCTAssertEqual(restored, bg)
        }
    }

    func testIdEqualsRawValue() {
        for bg in OverlayBackground.allCases {
            XCTAssertEqual(bg.id, bg.rawValue)
        }
    }

    func testKnownRawValues() {
        let expected = ["dark", "blue", "purple", "gradient", "red", "green", "nightOcean", "electric", "cyber"]
        let actual = OverlayBackground.allCases.map(\.rawValue)
        XCTAssertEqual(actual, expected)
    }

    func testDisplayNames() {
        XCTAssertEqual(OverlayBackground.dark.displayName, "Dark")
        XCTAssertEqual(OverlayBackground.gradient.displayName, "Sunset")
        XCTAssertEqual(OverlayBackground.nightOcean.displayName, "Night Ocean")
    }
}
