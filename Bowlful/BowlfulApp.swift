import SwiftUI

@main
struct BowlfulApp: App {
    @StateObject private var store = BowlfulStore()
    @StateObject private var purchases = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environmentObject(purchases)
        }
    }
}
