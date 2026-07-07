import Foundation
import Combine

@MainActor
final class BowlfulStore: ObservableObject {
    @Published private(set) var pets: [Pet] = []
    @Published private(set) var feedings: [Feeding] = []

    static let freePetLimit = 2

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("bowlful_data.json")
        if ProcessInfo.processInfo.arguments.contains("-uiTestReset") {
            try? FileManager.default.removeItem(at: fileURL)
        }
        load()
        if pets.isEmpty {
            seedDefaults()
        }
    }

    private func seedDefaults() {
        let cat = Pet(name: "Whiskers", species: "Cat", feedIntervalHours: 12)
        let dog = Pet(name: "Buddy", species: "Dog", feedIntervalHours: 8)
        pets = [cat, dog]
        feedings = [
            Feeding(petID: cat.id, feederName: "Mom", timestamp: Date().addingTimeInterval(-3600 * 3), foodNote: "Dry food"),
            Feeding(petID: dog.id, feederName: "Dad", timestamp: Date().addingTimeInterval(-3600 * 1), foodNote: "")
        ]
        save()
    }

    func canAddPet(isPro: Bool) -> Bool {
        isPro || pets.count < Self.freePetLimit
    }

    @discardableResult
    func addPet(name: String, species: String, feedIntervalHours: Double, isPro: Bool) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSpecies = species.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, feedIntervalHours > 0, canAddPet(isPro: isPro) else { return false }
        pets.append(Pet(name: trimmedName, species: trimmedSpecies.isEmpty ? "Pet" : trimmedSpecies, feedIntervalHours: feedIntervalHours))
        save()
        return true
    }

    func updatePet(_ id: UUID, name: String, species: String, feedIntervalHours: Double) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSpecies = species.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, feedIntervalHours > 0, let idx = pets.firstIndex(where: { $0.id == id }) else { return }
        pets[idx].name = trimmedName
        pets[idx].species = trimmedSpecies.isEmpty ? "Pet" : trimmedSpecies
        pets[idx].feedIntervalHours = feedIntervalHours
        save()
    }

    func deletePet(_ id: UUID) {
        pets.removeAll { $0.id == id }
        feedings.removeAll { $0.petID == id }
        save()
    }

    @discardableResult
    func logFeeding(petID: UUID, feederName: String, foodNote: String, timestamp: Date = Date()) -> Bool {
        let trimmedFeeder = feederName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFeeder.isEmpty, pets.contains(where: { $0.id == petID }) else { return false }
        feedings.append(Feeding(petID: petID, feederName: trimmedFeeder, timestamp: timestamp, foodNote: foodNote.trimmingCharacters(in: .whitespacesAndNewlines)))
        save()
        return true
    }

    func deleteFeeding(_ id: UUID) {
        feedings.removeAll { $0.id == id }
        save()
    }

    /// Most recent feeding for a given pet, or nil if never fed.
    func latestFeeding(for petID: UUID) -> Feeding? {
        feedings.filter { $0.petID == petID }.max { $0.timestamp < $1.timestamp }
    }

    /// All feedings for a pet, newest first.
    func feedingHistory(for petID: UUID) -> [Feeding] {
        feedings.filter { $0.petID == petID }.sorted { $0.timestamp > $1.timestamp }
    }

    /// Recent feedings across all pets, newest first — the shared household
    /// activity feed so nobody double-feeds.
    var recentFeedings: [Feeding] {
        feedings.sorted { $0.timestamp > $1.timestamp }
    }

    func petName(for id: UUID) -> String {
        pets.first { $0.id == id }?.name ?? "Unknown"
    }

    func deleteAllData() {
        pets = []
        feedings = []
        seedDefaults()
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var pets: [Pet]
        var feedings: [Feeding]
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) {
            pets = decoded.pets
            feedings = decoded.feedings
        }
    }

    private func save() {
        let snapshot = Snapshot(pets: pets, feedings: feedings)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
