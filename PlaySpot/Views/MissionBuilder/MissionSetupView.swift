// Views/MissionBuilder/MissionSetupView.swift — Mission Edit v2 (Phase 5)
// 디자인: README §10 Mission Edit v2 / screens-v2.jsx ScreenMissionEditV2
// FormGroup 기반 candy. 검증/뱃지 업로드/시간 제한 기능 보존.
import SwiftUI
import PhotosUI
import CoreLocation

struct MissionSetupView: View {
    @State private var viewModel: MissionBuilderViewModel
    @State private var limitEnabled: Bool
    @State private var limitH: Int
    @State private var limitM: Int
    @State private var limitS: Int
    @State private var badgePickerItem: PhotosPickerItem?
    @State private var pendingCropImage: UIImage?
    @State private var showExitConfirm = false
    @Environment(\.dismiss) private var dismiss

    init(mission: Mission?) {
        if let m = mission {
            let vm = MissionBuilderViewModel(mission: m, items: m.items, quizzes: [])
            _viewModel = State(initialValue: vm)
            _limitEnabled = State(initialValue: m.limitTime > 0)
            let s = m.limitTime > 0 ? m.limitTime : 600
            _limitH = State(initialValue: s / 3600)
            _limitM = State(initialValue: (s % 3600) / 60)
            _limitS = State(initialValue: s % 60)
        } else {
            let vm = MissionBuilderViewModel(userID: AppState.shared.userID)
            _viewModel = State(initialValue: vm)
            _limitEnabled = State(initialValue: false)
            _limitH = State(initialValue: 0)
            _limitM = State(initialValue: 10)
            _limitS = State(initialValue: 0)
        }
    }

    private var limitSeconds: Int { limitH * 3600 + limitM * 60 + limitS }

    // MARK: - 상태 표시 (3단계 진행)
    // 서버 R3.1 룰: 0(편집)→1(테스트 완료)→2(공개) 단방향. 빌더 메타 화면에선 표시만.
    // 단계 진행은 디자인 목록의 액션시트에서 수행.
    private var statusLabel: String {
        switch viewModel.mission.status {
        case .unpublished: return "편집 중 (비공개)"
        case .testing:     return "테스트 완료"
        case .published:   return "공개"
        }
    }
    private var statusSubtitle: String {
        switch viewModel.mission.status {
        case .unpublished: return "저장 후 디자인 목록에서 ‘Test Pass’ → ‘Publish’ 로 단계별 공개."
        case .testing:     return "디자인 목록에서 ‘Publish’ 를 눌러 Missions 탭에 공개하세요."
        case .published:   return "Missions 탭에 노출 중. 되돌릴 수 없습니다."
        }
    }
    private var statusIcon: String {
        switch viewModel.mission.status {
        case .unpublished: return "pencil.circle.fill"
        case .testing:     return "checkmark.seal.fill"
        case .published:   return "checkmark.circle.fill"
        }
    }
    private var statusColor: Color {
        switch viewModel.mission.status {
        case .unpublished: return .duoMacaw
        case .testing:     return .duoBee
        case .published:   return .duoGreen500
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                title

                FormGroup(title: "기본 정보") {
                    candyTextRow(label: "미션 제목", text: $viewModel.mission.title, placeholder: "예: 강남역 추리극")
                    rowDivider
                    candyTextRow(label: "장소", text: $viewModel.mission.place, placeholder: "예: 강남역 11번 출구")
                    rowDivider
                    autoFillRow
                }

                FormGroup(title: "설명") {
                    candyTextEditor(text: $viewModel.mission.description, height: 100)
                }

                limitGroup

                FormGroup(title: "플레이 설정") {
                    toggleRow(label: "Virtual 모드 허용",
                              isOn: Binding(
                                get: { viewModel.mission.isVirtual == .virtual },
                                set: { viewModel.mission.isVirtual = $0 ? .virtual : .real
                                       viewModel.isDirty = true }))
                    rowDivider
                    languageRow
                }

                FormGroup(
                    title: "현재 상태",
                    subtitle: statusSubtitle
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: statusIcon).foregroundColor(statusColor)
                        Text(statusLabel).font(.duoBody(size: 15, weight: .semibold))
                            .foregroundColor(.duoEel2)
                        Spacer()
                    }
                    .padding(14)
                }

                FormGroup(title: "뱃지 이미지") {
                    badgeBlock
                        .padding(14)
                }

                if !viewModel.validationErrors.isEmpty {
                    validationCard
                }

                mapEntryButton

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color.duoSnow.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("취소") {
                    if viewModel.isDirty { showExitConfirm = true } else { dismiss() }
                }
                .foregroundColor(.duoMacaw)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("저장") {
                    Task {
                        _ = await viewModel.save()
                        dismiss()
                    }
                }
                .foregroundColor(.duoMacaw)
                .fontWeight(.heavy)
                .disabled(!viewModel.canSave || viewModel.isSaving)
            }
        }
        .overlay {
            if viewModel.isSaving {
                progressOverlay("저장 중…")
            } else if viewModel.isLoadingDetail {
                progressOverlay("아이템 불러오는 중…")
            }
        }
        .confirmationDialog("변경사항을 저장하시겠습니까?",
                            isPresented: $showExitConfirm,
                            titleVisibility: .visible) {
            if viewModel.canSave {
                Button("저장 후 닫기") {
                    Task {
                        let ok = await viewModel.save()
                        if ok { dismiss() }
                    }
                }
            }
            Button("저장 안 함", role: .destructive) { dismiss() }
            Button("취소", role: .cancel) {}
        } message: {
            Text(viewModel.canSave
                 ? "‘저장 후 닫기’ 는 서버에 저장합니다."
                 : "필수 항목이 비어 있어 저장할 수 없습니다. 저장하지 않고 닫거나 계속 편집하세요.")
        }
        .onAppear { viewModel.validate() }
        .onChange(of: viewModel.items.count) { _, _ in viewModel.validate() }
        .fullScreenCover(item: Binding(
            get: { pendingCropImage.map(IdentifiableImage.init) },
            set: { pendingCropImage = $0?.image }
        )) { wrapped in
            ImageCropView(image: wrapped.image) { cropped in
                viewModel.badgeImage = cropped
                viewModel.badgeFileName = nil
                viewModel.isDirty = true
                pendingCropImage = nil
                badgePickerItem = nil
            } onCancel: {
                pendingCropImage = nil
                badgePickerItem = nil
            }
        }
        .task {
            await viewModel.loadDetail()
            let s = viewModel.mission.limitTime
            limitEnabled = s > 0
            if s > 0 {
                limitH = s / 3600
                limitM = (s % 3600) / 60
                limitS = s % 60
            }
        }
    }

    // MARK: - 타이틀

    private var title: some View {
        Text(viewModel.isNewMission ? "새 미션" : "미션 편집")
            .font(.duoDisplay(size: 28))
            .foregroundColor(.duoEel2)
            .padding(.top, 4)
    }

    // MARK: - 공통 행 헬퍼

    private func candyTextRow(label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            DuoKicker(text: label, color: .duoHare)
            TextField(placeholder, text: text)
                .font(.duoBody(size: 15, weight: .semibold))
                .foregroundColor(.duoEel2)
                .onChange(of: text.wrappedValue) { _, _ in viewModel.isDirty = true }
        }
        .padding(14)
    }

    private func candyTextEditor(text: Binding<String>, height: CGFloat) -> some View {
        TextEditor(text: text)
            .font(.duoBody(size: 14))
            .foregroundColor(.duoEel2)
            .scrollContentBackground(.hidden)
            .frame(minHeight: height)
            .padding(10)
            .onChange(of: text.wrappedValue) { _, _ in viewModel.isDirty = true }
    }

    private var autoFillRow: some View {
        Button {
            Task { await autoFillPlace() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "location.magnifyingglass")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(viewModel.items.isEmpty ? .duoHare : .duoMacaw)
                Text("좌표로 장소 자동 채우기")
                    .font(.duoBody(size: 14, weight: .bold))
                    .foregroundColor(viewModel.items.isEmpty ? .duoHare : .duoMacaw)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(viewModel.items.isEmpty ? .duoHare : .duoMacaw)
            }
            .padding(14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(viewModel.items.isEmpty)
    }

    private func toggleRow(label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(.duoBody(size: 15, weight: .semibold))
                .foregroundColor(.duoEel)
            Spacer()
            PSToggle(isOn: isOn)
        }
        .padding(14)
    }

    private var languageRow: some View {
        HStack {
            Text("언어")
                .font(.duoBody(size: 15, weight: .semibold))
                .foregroundColor(.duoEel)
            Spacer()
            Picker("", selection: $viewModel.mission.lang) {
                Text("한국어").tag("ko")
                Text("English").tag("en")
            }
            .pickerStyle(.menu)
            .tint(.duoMacaw)
        }
        .padding(14)
    }

    private var rowDivider: some View {
        Rectangle().fill(Color.duoSwan).frame(height: 1).padding(.leading, 14)
    }

    // MARK: - 제한 시간 그룹

    private var limitGroup: some View {
        FormGroup(
            title: "플레이 제한 시간",
            subtitle: limitEnabled
                ? "플레이 중 남은 시간이 표시되고, 시간이 초과되면 미션이 종료됩니다."
                : "시간 제한 없음 — 경과 시간만 표시됩니다."
        ) {
            toggleRow(label: "시간 제한", isOn: $limitEnabled)
                .onChange(of: limitEnabled) { _, on in
                    viewModel.mission.limitTime = on ? limitSeconds : 0
                    viewModel.isDirty = true
                }
            if limitEnabled {
                rowDivider
                limitWheels
            }
        }
    }

    private var limitWheels: some View {
        HStack(spacing: 0) {
            wheel($limitH, range: 0..<24, suffix: "시")
            Text(":").font(.duoDisplay(size: 22)).foregroundColor(.duoHare)
            wheel($limitM, range: 0..<60, suffix: "분")
            Text(":").font(.duoDisplay(size: 22)).foregroundColor(.duoHare)
            wheel($limitS, range: 0..<60, suffix: "초")
        }
        .frame(height: 130)
        .padding(.horizontal, 8)
    }

    private func wheel(_ value: Binding<Int>, range: Range<Int>, suffix: String) -> some View {
        VStack(spacing: 0) {
            Picker("", selection: value) {
                ForEach(range, id: \.self) { n in
                    Text(String(format: "%02d", n)).tag(n)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .clipped()
            .onChange(of: value.wrappedValue) { _, _ in
                viewModel.mission.limitTime = limitSeconds
                viewModel.isDirty = true
            }
            Text(suffix).font(.duoBody(size: 10, weight: .semibold)).foregroundColor(.duoHare)
        }
    }

    // MARK: - 뱃지

    @ViewBuilder
    private var badgeBlock: some View {
        VStack(spacing: 12) {
            badgePreview
            HStack(spacing: 10) {
                PhotosPicker(selection: $badgePickerItem, matching: .images) {
                    HStack(spacing: 6) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 14, weight: .bold))
                        Text(hasBadge ? "이미지 변경" : "이미지 선택")
                            .font(.duoDisplay(size: 12))
                            .kerning(0.6)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.duoMacaw))
                }
                if hasBadge {
                    Button(role: .destructive) {
                        viewModel.badgeImage = nil
                        viewModel.badgeFileName = nil
                        badgePickerItem = nil
                        viewModel.isDirty = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .bold))
                            Text("제거")
                                .font(.duoDisplay(size: 12))
                                .kerning(0.6)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .frame(height: 36)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.duoCardinal))
                    }
                }
            }
        }
        .onChange(of: badgePickerItem) { _, new in
            Task {
                if let data = try? await new?.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    pendingCropImage = img
                }
            }
        }
    }

    @ViewBuilder
    private var badgePreview: some View {
        ZStack {
            if let img = viewModel.badgeImage {
                Image(uiImage: img).resizable().scaledToFit()
            } else if let url = badgeRemoteURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty: ProgressView()
                    case .success(let image): image.resizable().scaledToFit()
                    case .failure:
                        VStack(spacing: 6) {
                            Image(systemName: "photo.badge.exclamationmark")
                                .font(.system(size: 32))
                                .foregroundColor(.duoHare)
                            Text("이미지를 불러올 수 없어요")
                                .font(.duoBody(size: 11))
                                .foregroundColor(.duoHare)
                        }
                    @unknown default: EmptyView()
                    }
                }
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 36))
                        .foregroundColor(.duoHare)
                    Text("뱃지 미설정").font(.duoBody(size: 11)).foregroundColor(.duoHare)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.duoSnow))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.duoSwan, lineWidth: 1.5))
    }

    private var badgeRemoteURL: URL? {
        guard let name = viewModel.badgeFileName, !name.isEmpty else { return nil }
        if name.hasPrefix("http://") || name.hasPrefix("https://") {
            return URL(string: name)
        }
        return URL(string: "\(APIEndpoint.badgeBaseURL)\(name)")
    }

    private var hasBadge: Bool {
        viewModel.badgeImage != nil || (viewModel.badgeFileName?.isEmpty == false)
    }

    // MARK: - 검증 카드

    private var validationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            DuoKicker(text: "검증", color: .duoCardinalDeep)
            ForEach(viewModel.validationErrors) { err in
                HStack(spacing: 8) {
                    Image(systemName: err.isBlocking ? "exclamationmark.triangle.fill" : "info.circle.fill")
                        .foregroundColor(err.isBlocking ? .duoCardinalDeep : .duoFoxDeep)
                    Text(err.fallbackMessage)
                        .font(.duoBody(size: 12, weight: .semibold))
                        .foregroundColor(err.isBlocking ? .duoCardinalDeep : .duoFoxDeep)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.duoCardinalBg.opacity(0.6)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.duoCardinal, lineWidth: 1.5))
    }

    // MARK: - 지도 진입 버튼

    private var mapEntryButton: some View {
        NavigationLink {
            MissionBuilderMapView(viewModel: viewModel)
        } label: {
            HStack {
                Image(systemName: "map.fill")
                    .font(.system(size: 16, weight: .bold))
                Text("아이템 배치 (지도 진입)")
                    .font(.duoDisplay(size: 14))
                    .kerning(0.84)
                    .textCase(.uppercase)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .heavy))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: DuoRadius.lg).fill(Color.duoBeetle))
            .background(
                RoundedRectangle(cornerRadius: DuoRadius.lg)
                    .fill(Color.duoBeetleDeep)
                    .offset(y: 4)
            )
        }
        .padding(.top, 4)
    }

    // MARK: - 헬퍼

    private func progressOverlay(_ label: String) -> some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
            HStack(spacing: 10) {
                ProgressView()
                Text(label)
                    .font(.duoBody(size: 14, weight: .semibold))
                    .foregroundColor(.duoEel)
            }
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func autoFillPlace() async {
        guard let first = viewModel.items.first else { return }
        let loc = CLLocation(latitude: first.latitude, longitude: first.longitude)
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(
                loc,
                preferredLocale: Locale(identifier: viewModel.mission.lang.isEmpty
                                        ? "ko_KR"
                                        : "\(viewModel.mission.lang)_\(viewModel.mission.lang.uppercased())"))
            if let pm = placemarks.first {
                let parts = [pm.administrativeArea, pm.locality, pm.subLocality, pm.thoroughfare].compactMap { $0 }
                let name = parts.joined(separator: " ")
                if !name.isEmpty {
                    viewModel.mission.place = name
                    viewModel.isDirty = true
                }
            }
        } catch {}
    }
}

private struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

#if DEBUG
#Preview("MissionSetup - New") {
    NavigationStack { MissionSetupView(mission: nil) }
}
#endif
