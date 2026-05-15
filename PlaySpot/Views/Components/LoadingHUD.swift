// Views/Components/LoadingHUD.swift
import SwiftUI

struct LoadingHUD: ViewModifier {
    let isPresented: Bool
    let message: String

    func body(content: Content) -> some View {
        content.overlay {
            if isPresented {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.white)
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .padding(24)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}

extension View {
    func loadingHUD(isPresented: Bool, message: String = "Loading..") -> some View {
        modifier(LoadingHUD(isPresented: isPresented, message: message))
    }
}

#if DEBUG
#Preview("LoadingHUD") {
    Color.blue.opacity(0.3)
        .ignoresSafeArea()
        .loadingHUD(isPresented: true, message: "Loading missions…")
}
#endif
