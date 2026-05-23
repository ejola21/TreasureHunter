// Views/MissionBuilder/MissionSetupView.swift — 미션 메타 입력 + 지도 진입
// plan_designer.md §7.1
import SwiftUI
import PhotosUI
import CoreLocation

struct MissionSetupView: View {
    @State private var viewModel: MissionBuilderViewModel
    /// 시간 제한 ON/OFF. OFF 면 limitTime = 0 (무제한).
    @State private var limitEnabled: Bool
    /// 제한 시간 입력 — 시 / 분 / 초 (00:00:00 포맷).
    @State private var limitH: Int
    @State private var limitM: Int
    @State private var limitS: Int
    @State private var badgePickerItem: PhotosPickerItem?
    @State private var pendingCropImage: UIImage?     // 크롭 시트 입력 (사진 선택 후, 크롭 확정 전)
    @State private var showExitConfirm = false
    @Environment(\.dismiss) private var dismiss

    /// 신규 / 편집 진입.
    /// 편집 진입 시 items 는 init 시점엔 비어 있을 수 있고 (designed 목록 응답은 slim),
    /// `.task` 의 `viewModel.loadDetail()` 이 서버 상세에서 items/quizzes 를 채운다.
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

    /// 현재 시:분:초 → 총 초.
    private var limitSeconds: Int { limitH * 3600 + limitM * 60 + limitS }

    var body: some View {
        Form {
            Section("기본 정보") {
                TextField("미션 제목", text: $viewModel.mission.title)
                TextField("장소", text: $viewModel.mission.place)
                Button {
                    Task { await autoFillPlace() }
                } label: {
                    Label("좌표로 장소 자동 채우기", systemImage: "location.magnifyingglass")
                }
                .disabled(viewModel.items.isEmpty)
            }

            Section("설명") {
                TextEditor(text: $viewModel.mission.description)
                    .frame(minHeight: 100)
            }

            limitSection

            Section("플레이 설정") {
                Toggle("Virtual 모드 허용", isOn: Binding(
                    get: { viewModel.mission.isVirtual == .virtual },
                    set: { viewModel.mission.isVirtual = $0 ? .virtual : .real
                           viewModel.isDirty = true }
                ))
                Picker("언어", selection: $viewModel.mission.lang) {
                    Text("한국어").tag("ko")
                    Text("English").tag("en")
                }
            }

            Section {
                Toggle("공개 (Missions 탭에 노출)", isOn: Binding(
                    get: { viewModel.mission.status == .published },
                    set: { viewModel.mission.status = $0 ? .published : .unpublished
                           viewModel.isDirty = true }
                ))
            } header: {
                Text("공개 설정")
            } footer: {
                Text(viewModel.mission.status == .published
                     ? "다른 사용자가 Missions 탭에서 플레이할 수 있습니다."
                     : "비공개 — 내 디자인 목록에만 보이고 Missions 탭에는 노출되지 않습니다.")
            }

            Section("뱃지 이미지") {
                VStack(alignment: .center, spacing: 12) {
                    badgePreview
                    HStack(spacing: 12) {
                        PhotosPicker(selection: $badgePickerItem, matching: .images) {
                            Label(hasBadge ? "이미지 변경" : "이미지 선택", systemImage: "photo.badge.plus")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.accentColor.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        if hasBadge {
                            Button(role: .destructive) {
                                viewModel.badgeImage = nil
                                viewModel.badgeFileName = nil
                                badgePickerItem = nil
                                viewModel.isDirty = true
                            } label: {
                                Label("제거", systemImage: "trash")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.red.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                .onChange(of: badgePickerItem) { _, new in
                    Task {
                        // PhotosPicker 로 받은 원본을 일단 pendingCropImage 에 넣어 크롭 시트 표시.
                        // 크롭 확정 시점에만 viewModel.badgeImage 에 반영.
                        if let data = try? await new?.loadTransferable(type: Data.self),
                           let img = UIImage(data: data) {
                            pendingCropImage = img
                        }
                    }
                }
            }

            // 검증 인라인 에러
            if !viewModel.validationErrors.isEmpty {
                Section("검증") {
                    ForEach(viewModel.validationErrors) { err in
                        HStack(spacing: 6) {
                            Image(systemName: err.isBlocking ? "exclamationmark.triangle.fill" : "info.circle.fill")
                                .foregroundColor(err.isBlocking ? .red : .orange)
                            Text(err.fallbackMessage)
                                .font(.caption)
                                .foregroundColor(err.isBlocking ? .red : .orange)
                        }
                    }
                }
            }

            Section {
                NavigationLink("아이템 배치 (지도 진입) →") {
                    MissionBuilderMapView(viewModel: viewModel)
                }
            }
        }
        .navigationTitle(viewModel.isNewMission ? "새 미션" : "미션 편집")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("취소") {
                    if viewModel.isDirty { showExitConfirm = true } else { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("저장") {
                    Task {
                        _ = await viewModel.save()
                        dismiss()
                    }
                }
                .disabled(!viewModel.canSave || viewModel.isSaving)
            }
        }
        .overlay {
            if viewModel.isSaving {
                ProgressView("저장 중…")
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            } else if viewModel.isLoadingDetail {
                ProgressView("아이템 불러오는 중…")
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
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
            Button("취소", role: .cancel) { }
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
                viewModel.badgeFileName = nil   // 새로 업로드 필요
                viewModel.isDirty = true
                pendingCropImage = nil
                badgePickerItem = nil
            } onCancel: {
                pendingCropImage = nil
                badgePickerItem = nil
            }
        }
        .task {
            // 편집 진입 시 서버 상세(items/quizzes) 로드 — designed 목록 응답은 slim 이라
            // 이게 없으면 지도 화면에 아이템이 0개로 보인다.
            await viewModel.loadDetail()
            // 상세 로드 후 제한 시간 UI 동기화.
            let s = viewModel.mission.limitTime
            limitEnabled = s > 0
            if s > 0 {
                limitH = s / 3600
                limitM = (s % 3600) / 60
                limitS = s % 60
            }
        }
    }

    // MARK: - 제한 시간 섹션

    @ViewBuilder
    private var limitSection: some View {
        Section {
            Toggle("시간 제한", isOn: $limitEnabled)
                .onChange(of: limitEnabled) { _, on in
                    viewModel.mission.limitTime = on ? limitSeconds : 0
                    viewModel.isDirty = true
                }
            if limitEnabled {
                // 00:00:00 — 시 / 분 / 초 3-휠 입력.
                HStack(spacing: 0) {
                    wheel($limitH, range: 0..<24, suffix: "시")
                    Text(":").font(.title3.bold()).foregroundColor(.secondary)
                    wheel($limitM, range: 0..<60, suffix: "분")
                    Text(":").font(.title3.bold()).foregroundColor(.secondary)
                    wheel($limitS, range: 0..<60, suffix: "초")
                }
                .frame(height: 130)
                HStack {
                    Text("설정된 제한").foregroundColor(.secondary)
                    Spacer()
                    Text(TimerFormatter.hms(limitSeconds))
                        .font(.body.monospaced().bold())
                }
            }
        } header: {
            Text("플레이 제한 시간")
        } footer: {
            Text(limitEnabled
                 ? "플레이 중 남은 시간이 표시되고, 시간이 초과되면 미션이 종료됩니다."
                 : "시간 제한 없음 — 경과 시간만 표시됩니다.")
        }
    }

    // MARK: - 뱃지 미리보기

    /// 새로 고른 이미지(메모리) 가 우선 → 없으면 서버 URL(기존 미션) 의 AsyncImage → 없으면 placeholder.
    @ViewBuilder
    private var badgePreview: some View {
        ZStack {
            if let img = viewModel.badgeImage {
                Image(uiImage: img).resizable().scaledToFit()
            } else if let url = badgeRemoteURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image.resizable().scaledToFit()
                    case .failure:
                        // S3 직접 접근 차단 등으로 다운로드 실패 — fileName 만 작은 캡션으로 보조 표시.
                        VStack(spacing: 6) {
                            Image(systemName: "photo.badge.exclamationmark")
                                .font(.system(size: 36))
                                .foregroundColor(.secondary)
                            Text("이미지를 불러올 수 없어요")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("뱃지 미설정").font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    /// `badgeFileName` 이 http URL 이면 그대로, 짧은 파일명이면 레거시 베이스URL 과 합쳐 조립.
    private var badgeRemoteURL: URL? {
        guard let name = viewModel.badgeFileName, !name.isEmpty else { return nil }
        if name.hasPrefix("http://") || name.hasPrefix("https://") {
            return URL(string: name)
        }
        return URL(string: "\(APIEndpoint.badgeBaseURL)\(name)")
    }

    /// 새로 고른 이미지나 서버 저장 fileName 중 하나라도 있으면 뱃지 보유로 간주.
    private var hasBadge: Bool {
        viewModel.badgeImage != nil || (viewModel.badgeFileName?.isEmpty == false)
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
            Text(suffix).font(.caption2).foregroundColor(.secondary)
        }
    }

    /// 첫 아이템 좌표로 CLGeocoder.reverseGeocode → place 자동 채움.
    private func autoFillPlace() async {
        guard let first = viewModel.items.first else { return }
        let loc = CLLocation(latitude: first.latitude, longitude: first.longitude)
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(loc, preferredLocale: Locale(identifier: viewModel.mission.lang.isEmpty ? "ko_KR" : "\(viewModel.mission.lang)_\(viewModel.mission.lang.uppercased())"))
            if let pm = placemarks.first {
                let parts = [pm.administrativeArea, pm.locality, pm.subLocality, pm.thoroughfare].compactMap { $0 }
                let name = parts.joined(separator: " ")
                if !name.isEmpty {
                    viewModel.mission.place = name
                    viewModel.isDirty = true
                }
            }
        } catch {
            // 무시 — 사용자가 직접 입력 가능
        }
    }
}

/// fullScreenCover(item:) 에 UIImage 를 직접 못 넘기므로 Identifiable 어댑터.
private struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

#if DEBUG
#Preview("MissionSetup - New") {
    NavigationStack { MissionSetupView(mission: nil) }
}
#endif
