import SwiftUI

enum BowlfulSheet: Identifiable {
    case addPet
    case editPet(Pet)
    case logFeeding(Pet)
    case paywall

    var id: String {
        switch self {
        case .addPet: return "addPet"
        case .editPet(let p): return "edit-\(p.id)"
        case .logFeeding(let p): return "log-\(p.id)"
        case .paywall: return "paywall"
        }
    }
}

struct PetFormView: View {
    @EnvironmentObject private var store: BowlfulStore
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    let existing: Pet?

    @State private var name: String
    @State private var species: String
    @State private var intervalText: String

    init(existing: Pet?) {
        self.existing = existing
        _name = State(initialValue: existing?.name ?? "")
        _species = State(initialValue: existing?.species ?? "Cat")
        _intervalText = State(initialValue: existing.map { String(Int($0.feedIntervalHours)) } ?? "12")
    }

    private var isEditing: Bool { existing != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Pet") {
                    TextField("Name", text: $name)
                        .accessibilityIdentifier("petNameField")
                    TextField("Species (e.g. Cat, Dog)", text: $species)
                        .accessibilityIdentifier("petSpeciesField")
                    TextField("Hours between feedings", text: $intervalText)
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("petIntervalField")
                }

                if isEditing {
                    Section {
                        Button("Delete Pet", role: .destructive) {
                            if let existing {
                                store.deletePet(existing.id)
                            }
                            dismiss()
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("deletePetButton")
                    }
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle(isEditing ? "Edit Pet" : "New Pet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .buttonStyle(.plain)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        let interval = Double(intervalText) ?? 0
                        if isEditing, let existing {
                            store.updatePet(existing.id, name: name, species: species, feedIntervalHours: interval)
                        } else {
                            store.addPet(name: name, species: species, feedIntervalHours: interval, isPro: purchases.isPro)
                        }
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || Double(intervalText) == nil || (Double(intervalText) ?? 0) <= 0)
                    .accessibilityIdentifier("savePetButton")
                }
            }
        }
    }
}

struct LogFeedingView: View {
    @EnvironmentObject private var store: BowlfulStore
    @Environment(\.dismiss) private var dismiss

    let pet: Pet

    @State private var feederName: String = ""
    @State private var foodNote: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Feeding \(pet.name)") {
                    TextField("Who's feeding?", text: $feederName)
                        .accessibilityIdentifier("feederNameField")
                    TextField("What/how much (optional)", text: $foodNote)
                        .accessibilityIdentifier("foodNoteField")
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle("Log Feeding")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .buttonStyle(.plain)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") {
                        store.logFeeding(petID: pet.id, feederName: feederName, foodNote: foodNote)
                        dismiss()
                    }
                    .disabled(feederName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("confirmLogFeedingButton")
                }
            }
        }
    }
}
