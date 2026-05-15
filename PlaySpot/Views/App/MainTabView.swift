// Views/App/MainTabView.swift
import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) var appState
    @State private var selectedTab = 0
    @State private var showLogin = false

    var body: some View {
        TabView(selection: $selectedTab) {
            MissionListView()
                .tabItem { Label("Missions", image: "UI/menu_list") }
                .tag(0)

            MissionBuilderView()
                .tabItem { Label("Design", image: "UI/menu_design") }
                .tag(1)

            MyInfoView()
                .tabItem { Label("My Info", image: "UI/menu_info") }
                .tag(2)

            BadgeListView()
                .tabItem { Label("Badge", image: "UI/menu_board") }
                .tag(3)

            SettingsView()
                .tabItem { Label("Settings", image: "UI/menu_help") }
                .tag(4)
        }
        .onChange(of: selectedTab) { _, newTab in
            if appState.isGuest && [1, 2, 3].contains(newTab) {
                showLogin = true
                selectedTab = 0
            }
        }
        .sheet(isPresented: $showLogin) {
            LoginView()
        }
    }
}

#if DEBUG
#Preview("MainTab") {
    MainTabView().environment(AppState.shared)
}
#endif
