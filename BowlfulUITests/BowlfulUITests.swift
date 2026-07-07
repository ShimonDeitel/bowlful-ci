import XCTest

final class BowlfulUITests: XCTestCase {
    private var interruptionMonitorToken: NSObjectProtocol?

    override func setUpWithError() throws {
        continueAfterFailure = false
        interruptionMonitorToken = addUIInterruptionMonitor(withDescription: "System alert dismissal") { alert in
            for label in ["Allow", "OK", "Don't Allow", "Cancel"] {
                let button = alert.buttons[label]
                if button.exists {
                    button.tap()
                    return true
                }
            }
            return false
        }
    }

    override func tearDownWithError() throws {
        if let token = interruptionMonitorToken {
            removeUIInterruptionMonitor(token)
        }
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset"]
        app.launch()
        return app
    }

    func testHomeShowsSeedPetsOnLaunch() throws {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["Whiskers"].waitForExistence(timeout: 12))
        XCTAssertTrue(app.staticTexts["Buddy"].waitForExistence(timeout: 12))
    }

    func testLogFeedingShowsInRecentFeedings() throws {
        let app = launchApp()
        let feedButton = app.buttons["feedButton_Whiskers"]
        XCTAssertTrue(feedButton.waitForExistence(timeout: 12))
        feedButton.tap()

        let feederField = app.textFields["feederNameField"]
        XCTAssertTrue(feederField.waitForExistence(timeout: 12))
        feederField.tap()
        feederField.typeText("Jamie")

        let confirmButton = app.buttons["confirmLogFeedingButton"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 8))
        XCTAssertTrue(confirmButton.isEnabled)
        confirmButton.tap()

        XCTAssertTrue(app.staticTexts["Whiskers fed by Jamie"].waitForExistence(timeout: 12), "New feeding did not appear in recent feedings")
    }

    func testLogFeedingRequiresFeederName() throws {
        let app = launchApp()
        let feedButton = app.buttons["feedButton_Buddy"]
        XCTAssertTrue(feedButton.waitForExistence(timeout: 12))
        feedButton.tap()

        let confirmButton = app.buttons["confirmLogFeedingButton"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 8))
        XCTAssertFalse(confirmButton.isEnabled, "Log button should be disabled with no feeder name")
    }

    func testAddPetFromHome() throws {
        let app = launchApp()
        // Seed data already has 2 pets (the free limit) — delete one first
        // so the "+" button opens the add form instead of the paywall.
        let whiskers = app.staticTexts["Whiskers"]
        XCTAssertTrue(whiskers.waitForExistence(timeout: 12))
        whiskers.tap()
        app.buttons["deletePetButton"].tap()
        XCTAssertFalse(app.staticTexts["Whiskers"].waitForExistence(timeout: 6))

        let addButton = app.buttons["addPetButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 12))
        addButton.tap()

        let nameField = app.textFields["petNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 12))
        nameField.tap()
        nameField.typeText("Nibbles")

        let speciesField = app.textFields["petSpeciesField"]
        speciesField.tap()
        speciesField.clearAndTypeText("Rabbit")

        let intervalField = app.textFields["petIntervalField"]
        intervalField.tap()
        intervalField.clearAndTypeText("10")

        app.buttons["savePetButton"].tap()

        XCTAssertTrue(app.staticTexts["Nibbles"].waitForExistence(timeout: 12), "New pet did not appear")
    }

    func testEditPetChangesInterval() throws {
        let app = launchApp()
        let buddy = app.staticTexts["Buddy"]
        XCTAssertTrue(buddy.waitForExistence(timeout: 12))
        buddy.tap()

        let intervalField = app.textFields["petIntervalField"]
        XCTAssertTrue(intervalField.waitForExistence(timeout: 12))
        intervalField.tap()
        intervalField.clearAndTypeText("6")

        app.buttons["savePetButton"].tap()

        // Re-open to confirm the change persisted.
        app.staticTexts["Buddy"].tap()
        let reopenedField = app.textFields["petIntervalField"]
        XCTAssertTrue(reopenedField.waitForExistence(timeout: 12))
        XCTAssertEqual(reopenedField.value as? String, "6")
    }

    func testDeletePetViaForm() throws {
        let app = launchApp()
        let buddy = app.staticTexts["Buddy"]
        XCTAssertTrue(buddy.waitForExistence(timeout: 12))
        buddy.tap()

        app.buttons["deletePetButton"].tap()

        XCTAssertFalse(app.staticTexts["Buddy"].waitForExistence(timeout: 6), "Pet was not deleted")
    }

    func testFreeLimitTriggersPaywallAtThirdPet() throws {
        let app = launchApp()
        // Seed data already has 2 pets (free limit is 2).
        let addButton = app.buttons["addPetButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 12))
        addButton.tap()
        XCTAssertTrue(app.staticTexts["Bowlful Pro"].waitForExistence(timeout: 12), "Paywall did not appear after hitting the free pet limit")
    }

    func testSettingsTabShowsCounts() throws {
        let app = launchApp()
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Pets Tracked"].waitForExistence(timeout: 12))
    }

    func testKeyboardDismissOnTapOutside() throws {
        let app = launchApp()
        let feedButton = app.buttons["feedButton_Whiskers"]
        XCTAssertTrue(feedButton.waitForExistence(timeout: 12))
        feedButton.tap()

        let feederField = app.textFields["feederNameField"]
        XCTAssertTrue(feederField.waitForExistence(timeout: 12))
        feederField.tap()
        feederField.typeText("Jamie")
        XCTAssertTrue(feederField.value as? String == "Jamie")

        // Tap a real Form section header/label (never navigationBars.firstMatch)
        // to trigger the outer simultaneousGesture keyboard dismiss.
        let header = app.staticTexts["Feeding Whiskers"]
        if header.waitForExistence(timeout: 4) {
            header.tap()
        }
        XCTAssertFalse(feederField.value(forKey: "hasKeyboardFocus") as? Bool ?? false)
    }
}

private extension XCUIElement {
    func clearAndTypeText(_ text: String) {
        guard let stringValue = self.value as? String, !stringValue.isEmpty else {
            typeText(text)
            return
        }
        self.press(forDuration: 1.0)
        typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count))
        typeText(text)
    }
}
