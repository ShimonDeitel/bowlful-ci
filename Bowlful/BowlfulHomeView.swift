import SwiftUI

struct BowlfulHomeView: View {
    @EnvironmentObject private var store: BowlfulStore
    @EnvironmentObject private var purchases: PurchaseManager
    @State private var activeSheet: BowlfulSheet?
    @State private var now = Date()

    /// Ticks every 30 seconds so bowl fullness visibly drains over time
    /// without needing app relaunch.
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack {
                BWTheme.backdrop.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        HStack {
                            Text("Bowlful")
                                .font(BWTheme.titleFont)
                                .foregroundStyle(BWTheme.ink)
                            Spacer()
                            Button {
                                if store.canAddPet(isPro: purchases.isPro) {
                                    activeSheet = .addPet
                                } else {
                                    activeSheet = .paywall
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(BWTheme.terracotta)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("addPetButton")
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 8)

                        if store.pets.isEmpty {
                            emptyState
                        } else {
                            bowlsGrid
                        }

                        if !store.recentFeedings.isEmpty {
                            recentFeedingsSection
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
            .onReceive(timer) { date in
                now = date
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .addPet:
                    PetFormView(existing: nil)
                case .editPet(let pet):
                    PetFormView(existing: pet)
                case .logFeeding(let pet):
                    LogFeedingView(pet: pet)
                case .paywall:
                    PaywallView()
                }
            }
        }
    }

    private var bowlsGrid: some View {
        VStack(spacing: 14) {
            ForEach(store.pets) { pet in
                BowlCard(
                    pet: pet,
                    latestFeeding: store.latestFeeding(for: pet.id),
                    now: now,
                    onFeed: { activeSheet = .logFeeding(pet) },
                    onEdit: { activeSheet = .editPet(pet) }
                )
            }
        }
        .padding(.horizontal, 18)
    }

    private var recentFeedingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RECENT FEEDINGS")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(BWTheme.inkFaded)
                .padding(.horizontal, 18)

            VStack(spacing: 8) {
                ForEach(store.recentFeedings.prefix(10)) { feeding in
                    FeedingRow(feeding: feeding, petName: store.petName(for: feeding.petID))
                }
            }
            .padding(.horizontal, 18)
        }
        .padding(.top, 6)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 48))
                .foregroundStyle(BWTheme.inkFaded)
            Text("No pets yet")
                .font(BWTheme.headlineFont)
                .foregroundStyle(BWTheme.ink)
            Text("Add a pet to start tracking who fed them.")
                .font(.subheadline)
                .foregroundStyle(BWTheme.inkFaded)
        }
        .padding(.top, 24)
        .padding(.horizontal, 18)
    }
}

/// Quirky signature feature: each pet gets a literal food-bowl visual that
/// fills right after feeding and visibly drains as time passes, coloring
/// from forest-green (full) through terracotta to danger-red (overdue).
struct BowlCard: View {
    let pet: Pet
    let latestFeeding: Feeding?
    let now: Date
    var onFeed: () -> Void
    var onEdit: () -> Void

    private var fullness: Double {
        pet.bowlFullness(latestFeeding: latestFeeding, now: now)
    }

    private var hoursSince: Double? {
        pet.hoursSince(latestFeeding: latestFeeding, now: now)
    }

    private var bowlColor: Color {
        if fullness > 0.6 { return BWTheme.forestBright }
        if fullness > 0.25 { return BWTheme.terracottaBright }
        return BWTheme.danger
    }

    private var statusText: String {
        guard let hoursSince else { return "Never fed" }
        if hoursSince < 1 {
            return "Fed \(Int(hoursSince * 60)) min ago"
        }
        return "Fed \(Int(hoursSince))h ago"
    }

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onEdit) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(pet.name)
                        .font(BWTheme.headlineFont)
                        .foregroundStyle(BWTheme.ink)
                    Text("\(pet.species) \u{00B7} \(statusText)")
                        .font(.caption)
                        .foregroundStyle(BWTheme.inkFaded)
                        .accessibilityIdentifier("bowlStatus_\(pet.name)")
                }
            }
            .buttonStyle(.plain)

            Spacer()

            bowlVisual
                .accessibilityElement(children: .ignore)
                .accessibilityIdentifier("bowlVisual_\(pet.name)")
                .accessibilityLabel("\(Int(fullness * 100)) percent full")

            Button(action: onFeed) {
                Text("Feed")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(BWTheme.terracotta)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("feedButton_\(pet.name)")
        }
        .padding(14)
        .background(BWTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(BWTheme.rule, lineWidth: 1))
    }

    private var bowlVisual: some View {
        ZStack(alignment: .bottom) {
            Circle()
                .stroke(BWTheme.rule, lineWidth: 2)
                .frame(width: 46, height: 46)

            Circle()
                .fill(BWTheme.surfaceRaised)
                .frame(width: 40, height: 40)

            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 6)
                    .fill(bowlColor)
                    .frame(height: geo.size.height * fullness)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            .animation(.easeInOut(duration: 0.4), value: fullness)
        }
        .frame(width: 46, height: 46)
    }
}

struct FeedingRow: View {
    let feeding: Feeding
    let petName: String

    private var timeAgoText: String {
        let elapsed = Date().timeIntervalSince(feeding.timestamp)
        let minutes = Int(elapsed / 60)
        if minutes < 1 { return "just now" }
        if minutes < 60 { return "\(minutes)m ago" }
        return "\(minutes / 60)h ago"
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(petName) fed by \(feeding.feederName)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(BWTheme.ink)
                if !feeding.foodNote.isEmpty {
                    Text(feeding.foodNote)
                        .font(.caption)
                        .foregroundStyle(BWTheme.inkFaded)
                }
            }
            Spacer()
            Text(timeAgoText)
                .font(.caption)
                .foregroundStyle(BWTheme.inkFaded)
        }
        .padding(10)
        .background(BWTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(BWTheme.rule, lineWidth: 1))
    }
}

#Preview {
    BowlfulHomeView()
        .environmentObject(BowlfulStore())
        .environmentObject(PurchaseManager())
}
