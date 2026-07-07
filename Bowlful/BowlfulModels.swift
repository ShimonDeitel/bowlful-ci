import Foundation

/// A pet in the household whose feedings are tracked.
struct Pet: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var species: String
    /// Hours after which the bowl is considered fully "empty" again —
    /// drives the quirky bowl-drain visual. Defaults to a typical
    /// once-per-12-hours feeding cadence.
    var feedIntervalHours: Double

    init(id: UUID = UUID(), name: String, species: String, feedIntervalHours: Double = 12) {
        self.id = id
        self.name = name
        self.species = species
        self.feedIntervalHours = feedIntervalHours
    }
}

/// A single logged feeding: which pet, who fed them, when, and optionally
/// what/how much.
struct Feeding: Identifiable, Codable, Equatable {
    let id: UUID
    var petID: UUID
    var feederName: String
    var timestamp: Date
    var foodNote: String

    init(id: UUID = UUID(), petID: UUID, feederName: String, timestamp: Date = Date(), foodNote: String = "") {
        self.id = id
        self.petID = petID
        self.feederName = feederName
        self.timestamp = timestamp
        self.foodNote = foodNote
    }
}

extension Pet {
    /// Fraction from 0 (empty bowl / overdue) to 1 (full bowl / just fed),
    /// computed against the most recent feeding for this pet.
    func bowlFullness(latestFeeding: Feeding?, now: Date = Date()) -> Double {
        guard let latestFeeding else { return 0 }
        let elapsedHours = now.timeIntervalSince(latestFeeding.timestamp) / 3600
        guard feedIntervalHours > 0 else { return 0 }
        let fraction = 1 - (elapsedHours / feedIntervalHours)
        return min(max(fraction, 0), 1)
    }

    func hoursSince(latestFeeding: Feeding?, now: Date = Date()) -> Double? {
        guard let latestFeeding else { return nil }
        return now.timeIntervalSince(latestFeeding.timestamp) / 3600
    }
}
