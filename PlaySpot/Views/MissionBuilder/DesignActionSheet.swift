// Views/MissionBuilder/DesignActionSheet.swift — 디자인 액션 시트 (Modify / Test / 공개·해제 / 삭제 / Cancel)
// 디자인: README §"Design Action Sheet" / screens-design.jsx ScreenDesignAction
// 카드형 행 (icon badge + title + subtitle + chevron). 공개된 미션은 삭제가 회색 안내.
import SwiftUI

struct DesignActionSheet: View {
    let mission: Mission
    let onModify: () -> Void
    let onTest: () -> Void
    let onTogglePublish: () -> Void   // 0→1 또는 1→2 전진
    let onDemote: () -> Void          // 2→1 후퇴 (공개 → 테스트로)
    let onDelete: () -> Void
    let onCancel: () -> Void

    private var isPublished: Bool { mission.status == .published }
    private var isTesting: Bool { mission.status == .testing }

    /// 다음 단계 행동 라벨 — 서버 0→1→2 단방향 룰에 맞춰 진행만.
    private var advanceTitle: String {
        switch mission.status {
        case .unpublished: return "Test Pass · 테스트 통과로 표시"
        case .testing:     return "Publish · 서버 업로드"
        case .published:   return "—"
        }
    }
    private var advanceSubtitle: String {
        switch mission.status {
        case .unpublished: return "테스트 플레이를 마쳤다면 다음 단계로"
        case .testing:     return "Missions 탭에 공개합니다 (되돌릴 수 없음)"
        case .published:   return "이미 공개된 미션입니다"
        }
    }
    private var advanceIcon: String {
        switch mission.status {
        case .unpublished: return "checkmark.seal.fill"
        case .testing:     return "square.and.arrow.up.fill"
        case .published:   return "lock.fill"
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 헤더 (미션 제목)
                VStack(alignment: .leading, spacing: 6) {
                    DuoKicker(text: "Design · 디자인 작업")
                    Text(mission.title.isEmpty ? "Untitled" : mission.title)
                        .font(.duoDisplay(size: 22))
                        .foregroundColor(.duoEel2)
                        .lineLimit(2)
                    if !mission.place.isEmpty {
                        Text(mission.place)
                            .font(.duoBody(size: 12))
                            .foregroundColor(.duoHare)
                    }
                }
                .padding(.top, 12)

                Text("완성된 디자인을 테스트해본 뒤 서버에 업로드하세요.")
                    .font(.duoBody(size: 13))
                    .foregroundColor(.duoWolf2)

                VStack(spacing: 12) {
                    ActionRow(
                        icon: "square.and.pencil",
                        tint: .duoMacaw,
                        title: "Modify · 수정",
                        subtitle: "제목·아이템·맵 편집",
                        action: onModify
                    )
                    ActionRow(
                        icon: "play.fill",
                        tint: .duoFox,
                        title: "Test Play · 테스트",
                        subtitle: "가상 모드로 미리 플레이",
                        action: onTest
                    )
                    // 전진 (0→1, 1→2) — 공개 상태가 아닐 때만 노출.
                    if !isPublished {
                        ActionRow(
                            icon: advanceIcon,
                            tint: isTesting ? .duoGreen500 : .duoMacaw,
                            title: advanceTitle,
                            subtitle: advanceSubtitle,
                            important: true,
                            action: onTogglePublish
                        )
                    }
                    // 후퇴 (2→1) — 공개 상태에서만 노출.
                    if isPublished {
                        ActionRow(
                            icon: "arrow.uturn.backward",
                            tint: .duoFox,
                            title: "Demote · 테스트로 되돌리기",
                            subtitle: "Missions 탭에서 내리고 테스트 단계로 돌아갑니다",
                            important: true,
                            action: onDemote
                        )
                    }
                    ActionRow(
                        icon: "trash.fill",
                        tint: isPublished ? .duoHare : .duoCardinal,
                        title: "Delete · 삭제",
                        subtitle: isPublished
                            ? "먼저 테스트 단계로 되돌린 뒤 삭제하세요"
                            : "되돌릴 수 없습니다",
                        muted: isPublished,
                        action: onDelete
                    )
                }

                Button("취소", action: onCancel)
                    .buttonStyle(CandyButtonStyle(tint: .white, shadowColor: .duoSwan2))
                    .overlay(
                        Text("취소")
                            .font(.duoDisplay(size: 14))
                            .kerning(0.84)
                            .textCase(.uppercase)
                            .foregroundColor(.duoWolf)
                    )
                    .padding(.top, 4)

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color.duoSnow.ignoresSafeArea())
    }
}

private struct ActionRow: View {
    let icon: String
    let tint: Color
    let title: String
    let subtitle: String
    var important: Bool = false
    var muted: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(tint)
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.duoDisplay(size: 14))
                        .foregroundColor(muted ? .duoHare : .duoEel2)
                    Text(subtitle)
                        .font(.duoBody(size: 12))
                        .foregroundColor(.duoHare)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.duoHare)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(important ? tint : Color.duoSwan2, lineWidth: 2)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(muted ? 0.7 : 1.0)
    }
}

#if DEBUG
#Preview("DesignActionSheet") {
    DesignActionSheet(
        mission: .preview,
        onModify: {}, onTest: {}, onTogglePublish: {}, onDemote: {},
        onDelete: {}, onCancel: {}
    )
}
#endif
