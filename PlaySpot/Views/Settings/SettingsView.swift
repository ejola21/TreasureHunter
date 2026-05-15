// Views/Settings/SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) var appState
    @State private var showTutorial = false

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    LabeledContent("User ID", value: appState.userID)

                    if !appState.isGuest {
                        Button("Logout") {
                            appState.userID = appState.guestUserID
                        }
                        .foregroundColor(.red)
                    }
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
