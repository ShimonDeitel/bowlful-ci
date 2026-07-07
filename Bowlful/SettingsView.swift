import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: BowlfulStore
    @EnvironmentObject private var purchases: PurchaseManager
    @AppStorage("bowlful_reminders_enabled") private var remindersEnabled: Bool = false
    @State private var activeSheet: BowlfulSheet?
    @State private var showResetConfirm = false
    @State private var restoreMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Feeding") {
                    Toggle("Overdue reminders", isOn: $remindersEnabled)
                        .accessibilityIdentifier("remindersToggle")
                }

                Section("Household") {
                    HStack {
                        Text("Pets Tracked")
                        Spacer()
                        Text("\(store.pets.count)")
                            .foregroundStyle(BWTheme.inkFaded)
                    }
                    HStack {
                        Text("Total Feedings Logged")
                        Spacer()
                        Text("\(store.feedings.count)")
                            .foregroundStyle(BWTheme.inkFaded)
                    }
                }

                Section("Bowlful Pro") {
                    if purchases.isPro {
                        Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(BWTheme.terracotta)
                    } else {
                        Button("Upgrade to Pro") {
                            activeSheet = .paywall
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("upgradeProButton")
                    }
                    Button("Restore Purchases") {
                        Task {
                            await purchases.restore()
                            restoreMessage = purchases.isPro ? "Purchases restored." : "No purchases found."
                        }
                    }
                    .buttonStyle(.plain)
                    if let restoreMessage {
                        Text(restoreMessage)
                            .font(.caption)
                            .foregroundStyle(BWTheme.inkFaded)
                    }
                }

                Section("About") {
                    Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/bowlful-site/privacy.html")!)
                    Link("Contact Support", destination: URL(string: "mailto:s0533495227@gmail.com")!)
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(BWTheme.inkFaded)
                    }
                }

                Section {
                    Button("Reset All Data", role: .destructive) {
                        showResetConfirm = true
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Reset all pets and feedings?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    store.deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .paywall:
                    PaywallView()
                default:
                    EmptyView()
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(BowlfulStore())
        .environmentObject(PurchaseManager())
}
