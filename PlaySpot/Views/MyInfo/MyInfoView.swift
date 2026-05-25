// Views/MyInfo/MyInfoView.swift
// Phase 3 — Profile card + ITEMS / DESIGNED / PLAYED FormGroup.
// 디자인: README §12 My Info
import SwiftUI

struct MyInfoView: View {
    @Environment(AppState.self) var appState
    @State private var designedMissions: [Mission] = []
    @State private var playedMissions: [Mission] = []
    private let dataSource: MissionDataSource = AppConfig.dataSource

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("My Info")
                    .font(.duoDisplay(size: 28))
                    .foregroundColor(.duoEel2)
                    .padding(.top, 4)

                profileCard

                FormGroup(title: "ITEMS") {
                    FormRow(label: "Solutions", value: "\(appState.solutionCount)", muted: true)
                    FormRow(label: "Time Add",  value: "\(appState.timeAddCount)",  muted: true, isLast: true)
                }

                FormGroup(title: "DESIGNED (\(designedMissions.count))") {
                    if designedMissions.isEmpty {
                        emptyRow(text: "아직 설계한 미션이 없어요.")
                    } else {
                        ForEach(Array(designedMissions.enumerated()), id: \.element.id) { idx, m in
                            FormRow(label: m.title, link: true,
                                    isLast: idx == designedMissions.count - 1) {}
                        }
                    }
                }

                FormGroup(title: "PLAYED (\(playedMissions.count))") {
                    if playedMissions.isEmpty {
                        emptyRow(text: "플레이한 미션이 없어요.")
                    } else {
                        ForEach(Array(playedMissions.enumerated()), id: \.element.id) { idx, m in
                            FormRow(label: m.title, link: true,
                                    isLast: idx == playedMissions.count - 1) {}
                        }
                    }
                }

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color.duoSnow.ignoresSafeArea())
        .task {
            await AuthBootstrap.ensureAuthenticated()
            do {
                async let d = dataSource.fetchMyDesigned(userID: appState.userID)
                async let p = dataSource.fetchMyPlayed(userID: appState.userID)
                designedMissions = try await d
                playedMissions = try await p
            } catch {}
        }
    }

    private var profileCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.duoMacaw)
                    .overlay(
                        Circle().fill(Color.duoMacawDeep)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .offset(y: 2)
                            .mask(Circle())
                    )
                Image(systemName: "person.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 2) {
                Text(appState.userID)
                    .font(.duoDisplay(size: 16))
                    .foregroundColor(.duoEel2)
                    .lineLimit(1)
                Text(appState.isGuest ? "Guest" : "Member")
                    .font(.duoBody(size: 12, weight: .semibold))
                    .foregroundColor(.duoHare)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: DuoRadius.xl).fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DuoRadius.xl).stroke(Color.duoSwan2, lineWidth: 2)
        )
    }

    private func emptyRow(text: String) -> some View {
        Text(text)
            .font(.duoBody(size: 13))
            .foregroundColor(.duoHare)
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if DEBUG
#Preview("MyInfo") {
    MyInfoView().environment(AppState.shared)
}
#endif
