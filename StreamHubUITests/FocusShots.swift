import XCTest

final class FocusShots: XCTestCase {

    @MainActor
    func testCaptureStates() {
        let app = XCUIApplication()
        app.launch()
        sleep(9)
        snap("01-launch")

        XCUIRemote.shared.press(.down); sleep(3)
        snap("02-cw-focused")

        XCUIRemote.shared.press(.down); sleep(1)
        XCUIRemote.shared.press(.down); sleep(3)
        snap("03-top10-focused")

        XCUIRemote.shared.press(.up); sleep(2)
        snap("04-after-one-up")

        XCUIRemote.shared.press(.up); sleep(1)
        XCUIRemote.shared.press(.up); sleep(3)
        snap("05-hero-return")

        XCUIRemote.shared.press(.right); sleep(3)
        snap("06-hero-plus-focused")
    }

    private func snap(_ name: String) {
        let shot = XCUIScreen.main.screenshot()
        let att = XCTAttachment(screenshot: shot)
        att.name = name
        att.lifetime = .keepAlways
        add(att)
    }
}
