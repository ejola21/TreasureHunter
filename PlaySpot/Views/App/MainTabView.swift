// Views/App/MainTabView.swift
// Phase 3 — TabView 의 기본 탭바를 숨기고 BottomNav5 커스텀 바를 오버레이.
// 게스트 차단 정책 (Design/MyInfo/Badge — release 빌드에서만) 은 보존.
import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) var appState
    @State private var active: MainTab = .missions
    @State private var showLogin = false

    var body: some View {
        VStack(spacing: 0) {
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            BottomNav5(active: $active)
        }
        .background(Color.duoSnow.ignoresSafeArea())
        .onChange(of: active) { _, newTab in
            #if !DEBUG
            // 릴리스 빌드: Design/MyInfo/Badge 는 로그인 필수.
            if appState.isGuest, [.design, .info, .badge].contains(newTab) {
                showLogin = true
                active = .missions
            }
            #endif
        }
        .sheet(isPresented: $showLogin) {
            LoginView()
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch active {
        case .missions: MissionListView()
        case .design:   MissionBuilderView()
        case .info:     MyInfoView()
        case .badge:    BadgeListView()
        case .settings: SettingsView()
        }
    }
}

#if DEBUG
#Preview("MainTab") {
    MainTabView().environment(AppState.shared)
}
#endif
