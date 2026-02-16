import XCTest
@testable import MeetingReminder

final class ClampedExtensionTests: XCTestCase {

    func testValueInRange() {
        XCTAssertEqual(5.clamped(to: 1...10, default: 3), 5)
    }

    func testValueBelowRange() {
        XCTAssertEqual((-1).clamped(to: 1...10, default: 3), 1)
    }

    func testValueAboveRange() {
        XCTAssertEqual(20.clamped(to: 1...10, default: 3), 10)
    }

    func testZeroReturnsDefault() {
        XCTAssertEqual(0.clamped(to: 1...10, default: 5), 5)
    }

    func testValueAtLowerBound() {
        XCTAssertEqual(1.clamped(to: 1...10, default: 5), 1)
    }

    func testValueAtUpperBound() {
        XCTAssertEqual(10.clamped(to: 1...10, default: 5), 10)
    }
}
