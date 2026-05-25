// Views/MissionBuilder/DesignActionSheet.swift — 디자인 액션 시트 (Modify / Test / 공개·해제 / 삭제 / Cancel)
// 디자인: README §"Design Action Sheet" / screens-design.jsx ScreenDesignAction
// 카드형 행 (icon badge + title + subtitle + chevron). 공개된 미션은 삭제가 회색 안내.
import SwiftUI

struct DesignActionSheet: View {
    let mission: Mission
    let onModify: () -> Void
    let onTest: () -> Void
    let onTogglePublish: () -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void

    private var isPublished: Bool { mission.status == .published }

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
                    ActionRow(
                        icon: isPublished ? "lock.open.fill" : "square.and.arrow.up.fill",
                        tint: isPublished ? .duoBeetle : .duoGreen500,
                        title: isPublished ? "Unpublish · 공개 해제" : "Publish · 서버 업로드",
                        subtitle: isPublished
                            ? "비공개 상태로 되돌립니다"
                            : "Missions 탭에 공개합니다",
                        important: true,
                        action: onTogglePublish
                    )
                    ActionRow(
                        icon: "trash.fill",
                        tint: isPublished ? .duoHare : .duoCardinal,
                        title: "Delete · 삭제",
                        subtitle: isPublished
                            ? "먼저 공개 해제 후 삭제 가능"
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
        onModify: {}, onTest: {}, onTogglePublish: {},
        onDelete: {}, onCancel: {}
    )
}
#endif
