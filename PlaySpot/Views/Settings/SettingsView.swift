// Views/Settings/SettingsView.swift
// Phase 3 — Duolingo candy 스타일 재디자인.
// 기존 로직 (API Backend 토글 / 401 시뮬 / Logout / Tutorial) 은 모두 보존.
import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) var appState
    @State private var showTutorial = false
    @State private var showHelp = false
    @State private var showLogin = false
    @State private var selectedBackend: APIBackend = AppConfig.backend
    @State private var showLogoutConfirm = false
    #if DEBUG
    @State private var showDesignSystemPreview = false
    @State private var showARSearchDemo = false
    #endif

    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let appBuild   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Settings")
                    .font(.duoDisplay(size: 28))
                    .foregroundColor(.duoEel2)
                    .padding(.top, 4)

                FormGroup(title: "ACCOUNT") {
                    FormRow(label: "User ID", value: appState.userID, muted: true)
                    if appState.isGuest {
                        FormRow(label: "Login", link: true, isLast: true) { showLogin = true }
                    } else {
                        FormRow(label: "Logout", link: true, isLast: true) { showLogoutConfirm = true }
                    }
                }

                FormGroup(title: "API BACKEND",
                          subtitle: "REST 로 전환 시 다음 호출부터 /api/v1/** 사용. 재로그인 필요.") {
                    HStack {
                        Text("Backend")
                            .font(.duoBody(size: 15, weight: .semibold))
                            .foregroundColor(.duoEel)
                        Spacer()
                        SegBtnPair(
                            selection: $selectedBackend,
                            options: [(.legacy, "Legacy"), (.rest, "REST")]
                        )
                        .frame(width: 180)
                    }
                    .padding(14)
                }
                .onChange(of: selectedBackend) { _, new in
                    AppConfig.backend = new
                    Task { await AuthSession.shared.reset() }
                }

                #if DEBUG
                FormGroup(title: "DEBUG — 401 자동 재로그인 검증",
                          subtitle: "Console 로그에서 'auto re-login' 출력 확인.") {
                    FormRow(label: "Simulate 401: token 손상 + fetch 시도",
                            link: true, isLast: true) {
                        Task {
                            await AuthSession.shared.setToken("invalid_test_token")
                            _ = try? await AppConfig.dataSource.fetchMissionList(cursor: 0, lang: "ko")
                        }
                    }
                }
                #endif

                FormGroup(title: "GUIDE · 가이드") {
                    FormRow(label: "Tutorial · 튜토리얼", link: true) {
                        showTutorial = true
                    }
                    FormRow(label: "Help · 아이템 도움말", link: true, isLast: true) {
                        showHelp = true
                    }
                }

                FormGroup(title: "ABOUT") {
                    FormRow(label: "Version", value: appVersion, muted: true)
                    FormRow(label: "Build", value: appBuild, muted: true, isLast: true)
                }

                #if DEBUG
                FormGroup(title: "REDESIGN — PHASE 1/2 PREVIEW") {
                    FormRow(label: "Design System Catalog", link: true) {
                        showDesignSystemPreview = true
                    }
                    FormRow(label: "AR Search Demo", link: true, isLast: true) {
                        showARSearchDemo = true
                    }
                }
                #endif

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color.duoSnow.ignoresSafeArea())
        .sheet(isPresented: $showTutorial) {
            TutorialView()
        }
        .sheet(isPresented: $showHelp) {
            NavigationStack { HelpRoot() }
        }
        .sheet(isPresented: $showLogin) {
            LoginView()
        }
        .alert("로그아웃 하시겠어요?", isPresented: $showLogoutConfirm) {
            Button("취소", role: .cancel) {}
            Button("로그아웃", role: .destructive) {
                Task { await AuthSession.shared.reset() }
                appState.userID = appState.guestUserID
            }
        }
        #if DEBUG
        .sheet(isPresented: $showDesignSystemPreview) {
            NavigationStack {
                PSDesignSystemPreview()
                    .navigationTitle("Design System")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .fullScreenCover(isPresented: $showARSearchDemo) {
            ARSearchView { showARSearchDemo = false }
        }
        #endif
    }
}

#if DEBUG
#Preview("Settings") {
    SettingsView().environment(AppState.shared)
}
#endif
