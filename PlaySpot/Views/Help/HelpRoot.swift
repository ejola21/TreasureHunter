// Views/Help/HelpRoot.swift — Help 플로우 3탭 라우터 (Items / How to Play / Design)
// 디자인: README §14~16 Help

import SwiftUI

enum HelpTab: String, Identifiable, CaseIterable {
    case items, howto, design
    var id: String { rawValue }
    var label: String {
        switch self {
        case .items: return "Items"
        case .howto: return "How to Play"
        case .design: return "Design"
        }
    }
}

struct HelpRoot: View {
    @State private var tab: HelpTab
    var onStartDesign: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    init(initial: HelpTab = .items, onStartDesign: (() -> Void)? = nil) {
        _tab = State(initialValue: initial)
        self.onStartDesign = onStartDesign
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            SegmentedTabs(
                selection: $tab,
                options: HelpTab.allCases,
                label: { $0.label }
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            ScrollView {
                Group {
                    switch tab {
                    case .items: HelpItemsView()
                    case .howto: HelpHowToView()
                    case .design: HelpDesignView { onStartDesign?() }
                    }
                }
            }
            .background(Color.duoSnow)
        }
        .background(Color.duoSnow.ignoresSafeArea())
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(.duoEel2)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white))
                    .overlay(Circle().stroke(Color.duoSwan2, lineWidth: 2))
            }
            VStack(alignment: .leading, spacing: 0) {
                DuoKicker(text: "Help · 도움말")
                Text(tab.label)
                    .font(.duoDisplay(size: 22))
                    .foregroundColor(.duoEel2)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

#if DEBUG
#Preview("HelpRoot") { HelpRoot() }
#endif
