import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            BowlfulHomeView()
                .tabItem {
                    Label("Bowls", systemImage: "cup.and.saucer.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(BWTheme.terracotta)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(BWTheme.surface)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(BowlfulStore())
        .environmentObject(PurchaseManager())
}
