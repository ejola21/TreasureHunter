// Views/Settings/SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) var appState
    @State private var showTutorial = false
    @State private var selectedBackend: APIBackend = AppConfig.backend

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    LabeledContent("User ID", value: appState.userID)

                    if !appState.isGuest {
                        Button("Logout") {
                            // 신규 API: 토큰 + 자격증명 폐기. 게스트 사용자로 되돌림.
                            Task { await AuthSession.shared.reset() }
                            appState.userID = appState.guestUserID
                        }
                        .foregroundColor(.red)
                    }
                }

                Section("API Backend") {
                    Picker("Backend", selection: $selectedBackend) {
                        ForEach(APIBackend.allCases) { backend in
                            Text(backend.displayName).tag(backend)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedBackend) { _, new in
                        AppConfig.backend = new
                        // 백엔드 변경 시 토큰/자격증명 폐기 — 다른 백엔드의 토큰은 무의미.
                        Task { await AuthSession.shared.reset() }
                    }
                    Text("REST 로 전환 시 다음 호출부터 /api/v1/** 사용. 재로그인 필요.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Tutorial") {
                    Button("How to Play") {
                        showTutorial = true
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    LabeledContent("Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showTutorial) {
                TutorialPagerView()
            }
        }
    }
}

private struct TutorialPagerView: View {
    @Environment(\.dismiss) private var dismiss

    // 레거시 Setting.m 의 nameArray 순서 유지: tutorial1 → tutorial0 → tutorial2
    private var pages: [String] {
        let lang = Locale.current.language.languageCode?.identifier ?? "en"
        let suffix = lang == "ko" ? "" : "_en"
        return [
            "Tutorial/tutorial1\(suffix)",
            "Tutorial/tutorial0\(suffix)",
            "Tutorial/tutorial2\(suffix)"
        ]
    }

    var body: some View {
        NavigationStack {
            TabView {
                ForEach(pages, id: \.self) { name in
                    Image(name)
                        .resizable()
                        .scaledToFit()
                        .padding()
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .navigationTitle("Tutorial")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#if DEBUG
#Preview("Settings") {
    SettingsView().environment(AppState.shared)
}
#endif
