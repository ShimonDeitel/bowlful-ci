import XCTest
@testable import Bowlful

final class BowlfulTests: XCTestCase {
    var store: BowlfulStore!

    @MainActor
    override func setUp() {
        super.setUp()
        store = BowlfulStore()
        store.deleteAllData()
        for p in store.pets { store.deletePet(p.id) }
    }

    @MainActor
    func testAddPet() {
        let added = store.addPet(name: "Milo", species: "Cat", feedIntervalHours: 12, isPro: false)
        XCTAssertTrue(added)
        XCTAssertEqual(store.pets.count, 1)
        XCTAssertEqual(store.pets[0].name, "Milo")
    }

    @MainActor
    func testAddPetRejectsEmptyName() {
        let added = store.addPet(name: "   ", species: "Cat", feedIntervalHours: 12, isPro: false)
        XCTAssertFalse(added)
    }

    @MainActor
    func testAddPetRejectsInvalidInterval() {
        let added = store.addPet(name: "Milo", species: "Cat", feedIntervalHours: 0, isPro: false)
        XCTAssertFalse(added)
    }

    @MainActor
    func testFreeLimitBlocksThirdPet() {
        _ = store.addPet(name: "A", species: "Cat", feedIntervalHours: 12, isPro: false)
        _ = store.addPet(name: "B", species: "Dog", feedIntervalHours: 8, isPro: false)
        XCTAssertFalse(store.canAddPet(isPro: false))
        let third = store.addPet(name: "C", species: "Bird", feedIntervalHours: 6, isPro: false)
        XCTAssertFalse(third)
        XCTAssertEqual(store.pets.count, 2)
    }

    @MainActor
    func testProAllowsUnlimitedPets() {
        _ = store.addPet(name: "A", species: "Cat", feedIntervalHours: 12, isPro: true)
        _ = store.addPet(name: "B", species: "Dog", feedIntervalHours: 8, isPro: true)
        let third = store.addPet(name: "C", species: "Bird", feedIntervalHours: 6, isPro: true)
        XCTAssertTrue(third)
        XCTAssertEqual(store.pets.count, 3)
    }

    @MainActor
    func testUpdatePet() {
        _ = store.addPet(name: "Milo", species: "Cat", feedIntervalHours: 12, isPro: false)
        let id = store.pets[0].id
        store.updatePet(id, name: "Milo", species: "Cat", feedIntervalHours: 10)
        XCTAssertEqual(store.pets[0].feedIntervalHours, 10)
    }

    @MainActor
    func testDeletePetAlsoRemovesFeedings() {
        _ = store.addPet(name: "Milo", species: "Cat", feedIntervalHours: 12, isPro: false)
        let id = store.pets[0].id
        store.logFeeding(petID: id, feederName: "Sam", foodNote: "Wet food")
        XCTAssertEqual(store.feedings.count, 1)
        store.deletePet(id)
        XCTAssertTrue(store.pets.isEmpty)
        XCTAssertTrue(store.feedings.isEmpty)
    }

    @MainActor
    func testLogFeeding() {
        _ = store.addPet(name: "Milo", species: "Cat", feedIntervalHours: 12, isPro: false)
        let id = store.pets[0].id
        let logged = store.logFeeding(petID: id, feederName: "Sam", foodNote: "Dry food")
        XCTAssertTrue(logged)
        XCTAssertEqual(store.feedings.count, 1)
        XCTAssertEqual(store.feedings[0].feederName, "Sam")
    }

    @MainActor
    func testLogFeedingRejectsEmptyFeederName() {
        _ = store.addPet(name: "Milo", species: "Cat", feedIntervalHours: 12, isPro: false)
        let id = store.pets[0].id
        let logged = store.logFeeding(petID: id, feederName: "  ", foodNote: "")
        XCTAssertFalse(logged)
        XCTAssertTrue(store.feedings.isEmpty)
    }

    @MainActor
    func testLogFeedingRejectsUnknownPet() {
        let logged = store.logFeeding(petID: UUID(), feederName: "Sam", foodNote: "")
        XCTAssertFalse(logged)
    }

    @MainActor
    func testLatestFeedingReturnsMostRecent() {
        _ = store.addPet(name: "Milo", species: "Cat", feedIntervalHours: 12, isPro: false)
        let id = store.pets[0].id
        store.logFeeding(petID: id, feederName: "Sam", foodNote: "", timestamp: Date().addingTimeInterval(-3600))
        store.logFeeding(petID: id, feederName: "Alex", foodNote: "", timestamp: Date())
        let latest = store.latestFeeding(for: id)
        XCTAssertEqual(latest?.feederName, "Alex")
    }

    @MainActor
    func testDeleteFeeding() {
        _ = store.addPet(name: "Milo", species: "Cat", feedIntervalHours: 12, isPro: false)
        let id = store.pets[0].id
        store.logFeeding(petID: id, feederName: "Sam", foodNote: "")
        let feedingID = store.feedings[0].id
        store.deleteFeeding(feedingID)
        XCTAssertTrue(store.feedings.isEmpty)
    }

    // MARK: - Bowl fullness

    func testBowlFullnessIsZeroWithNoFeeding() {
        let pet = Pet(name: "Milo", species: "Cat", feedIntervalHours: 12)
        XCTAssertEqual(pet.bowlFullness(latestFeeding: nil), 0)
    }

    func testBowlFullnessIsFullRightAfterFeeding() {
        let pet = Pet(name: "Milo", species: "Cat", feedIntervalHours: 12)
        let feeding = Feeding(petID: pet.id, feederName: "Sam", timestamp: Date())
        XCTAssertEqual(pet.bowlFullness(latestFeeding: feeding, now: Date()), 1.0, accuracy: 0.01)
    }

    func testBowlFullnessDrainsHalfwayThroughInterval() {
        let pet = Pet(name: "Milo", species: "Cat", feedIntervalHours: 12)
        let fedAt = Date().addingTimeInterval(-3600 * 6)
        let feeding = Feeding(petID: pet.id, feederName: "Sam", timestamp: fedAt)
        XCTAssertEqual(pet.bowlFullness(latestFeeding: feeding, now: Date()), 0.5, accuracy: 0.02)
    }

    func testBowlFullnessClampsToZeroWhenOverdue() {
        let pet = Pet(name: "Milo", species: "Cat", feedIntervalHours: 12)
        let fedAt = Date().addingTimeInterval(-3600 * 30)
        let feeding = Feeding(petID: pet.id, feederName: "Sam", timestamp: fedAt)
        XCTAssertEqual(pet.bowlFullness(latestFeeding: feeding, now: Date()), 0.0, accuracy: 0.001)
    }

    @MainActor
    func testPetNameLookup() {
        _ = store.addPet(name: "Milo", species: "Cat", feedIntervalHours: 12, isPro: false)
        let id = store.pets[0].id
        XCTAssertEqual(store.petName(for: id), "Milo")
        XCTAssertEqual(store.petName(for: UUID()), "Unknown")
    }

    @MainActor
    func testRecentFeedingsSortedNewestFirst() {
        _ = store.addPet(name: "Milo", species: "Cat", feedIntervalHours: 12, isPro: true)
        _ = store.addPet(name: "Rex", species: "Dog", feedIntervalHours: 8, isPro: true)
        let id1 = store.pets[0].id
        let id2 = store.pets[1].id
        store.logFeeding(petID: id1, feederName: "Sam", foodNote: "", timestamp: Date().addingTimeInterval(-7200))
        store.logFeeding(petID: id2, feederName: "Alex", foodNote: "", timestamp: Date())
        XCTAssertEqual(store.recentFeedings.first?.feederName, "Alex")
    }
}
