// Views/MissionPlay/StartGameView.swift
import SwiftUI

struct StartGameView: View {
    let mission: Mission
    let onStart: (Bool) -> Void  // isVirtualMode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text(mission.title)
                .font(.title2.bold())

            Text(mission.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            VStack(spacing: 12) {
                Button {
                    onStart(false)
                    dismiss()
                } label: {
                    Label("Real Mode", systemImage: "location.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                if mission.isVirtual == .virtual {
                    Button {
                        onStart(true)
                        dismiss()
                    } label: {
                        Label("Virtual Mode", systemImage: "globe")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

#if DEBUG
#Preview("StartGame") {
    StartGameView(mission: .preview) { _ in }
}
#endif
