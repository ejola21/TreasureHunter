// Views/DesignSystem/FormGroup.swift
// kicker (선택) + DuoCard + 내부 1px swan divider rows + footer 힌트 (선택)
// 디자인: README §"Section Group (form card)" / screens-v2.jsx FormGroup

import SwiftUI

struct FormGroup<Content: View>: View {
    var title: String? = nil
    var subtitle: String? = nil
    var footer: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                DuoKicker(text: title)
                    .padding(.horizontal, 4)
            }
            DuoCard(radius: DuoRadius.xl, padding: 0) {
                content
            }
            if let subtitle {
                Text(subtitle)
                    .font(.duoBody(size: 12))
                    .foregroundColor(.duoHare)
                    .padding(.horizontal, 4)
            }
            if let footer {
                Text(footer)
                    .font(.duoBody(size: 12))
                    .foregroundColor(.duoHare)
                    .padding(.horizontal, 4)
            }
        }
    }
}

/// 내부 행 1줄 — label (좌) + value/chevron (우) + 옵션 divider.
struct FormRow: View {
    let label: String
    var value: String? = nil
    var muted: Bool = false
    var link: Bool = false
    var isLast: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        let row = HStack(spacing: 12) {
            Text(label)
                .font(.duoBody(size: 15, weight: link ? .bold : .semibold))
                .foregroundColor(link ? .duoMacaw : .duoEel)
            Spacer()
            if let value {
                Text(value)
                    .font(.duoBody(size: 14))
                    .foregroundColor(muted ? .duoHare : .duoWolf2)
            }
            if action != nil && !link {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.duoHare)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())

        VStack(spacing: 0) {
            if let action {
                Button(action: action) { row }.buttonStyle(.plain)
            } else {
                row
            }
            if !isLast {
                Divider().background(Color.duoSwan).padding(.leading, 14)
            }
        }
    }
}

#if DEBUG
#Preview("FormGroup") {
    ScrollView {
        VStack(spacing: 16) {
            FormGroup(title: "ACCOUNT") {
                FormRow(label: "User ID", value: "Guest@2026")
                FormRow(label: "Login", link: true, isLast: true) {}
            }
            FormGroup(title: "API BACKEND", subtitle: "REST 로 전환 시 재로그인 필요.") {
                FormRow(label: "Backend", value: "REST", isLast: true)
            }
            FormGroup(title: "ABOUT") {
                FormRow(label: "Version", value: "1.0", muted: true)
                FormRow(label: "Build", value: "12", muted: true, isLast: true)
            }
        }
        .padding()
    }
    .background(Color.duoSnow)
}
#endif
