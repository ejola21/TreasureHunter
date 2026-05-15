// Views/App/ContentView.swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#if DEBUG
#Preview("Content") {
    ContentView().environment(AppState.shared)
}
#endif
