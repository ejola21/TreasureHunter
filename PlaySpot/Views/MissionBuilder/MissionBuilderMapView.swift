// Views/MissionBuilder/MissionBuilderMapView.swift — 빌더 지도 화면 (아이템 배치 전용)
// plan_designer.md §7.1 / 레거시 MissionBuilder.m
//
// 흐름:
//   - 빈 영역 longPress → ItemPickerView sheet(.medium) → placeItem
//   - pin tap → ItemDetailView sheet → 편집
//   - pin drag → viewModel.moveItem (BuilderMapView 가 직접 처리)
//   - "완료" → 미션 상세 화면(MissionSetupView)으로 복귀. 저장은 상세 화면에서만 한다.
//
// viewModel 은 MissionSetupView 와 공유하므로, 여기서 배치한 아이템은
// 상세 화면의 "저장" 시 함께 서버로 전송된다.
import SwiftUI
import MapKit
import CoreLocation

struct MissionBuilderMapView: View {
    @Bindable var viewModel: MissionBuilderViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var initialRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.486, longitude: 126.808),
        span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
    )
    @State private var pendingCoord: CLLocationCoordinate2D?
    @State private var pickerType: ItemType?
    @State private var pickerShowType: ShowType = .all
    @State private var pickerRangeAR: Int = 30
    @State private var showPicker = false
    @State private var editingItemID: Int?

    var body: some View {
        ZStack {
            BuilderMapView(
                items: viewModel.items,
                initialRegion: regionForCurrentItems(),
                onLongPress: { coord in
                    pendingCoord = coord
                    pickerType = .start
                    pickerShowType = .all
                    pickerRangeAR = 30
                    showPicker = true
                },
                onTapItem: { id in
                    editingItemID = id
                },
                onMoveItem: { id, coord in
                    viewModel.moveItem(itemID: id, to: coord)
                }
            )
            .ignoresSafeArea(edges: .bottom)

            VStack {
                Spacer()
                if !viewModel.validationErrors.isEmpty {
                    validationBanner
                }
                bottomToolbar
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text("EDITING").font(.duoDisplay(size: 9))
                        .kerning(0.6)
                        .foregroundColor(.duoHare)
                    Text("아이템 배치").font(.duoDisplay(size: 14))
                        .foregroundColor(.duoEel2)
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("완료") { dismiss() }
                    .foregroundColor(.duoMacaw)
                    .fontWeight(.heavy)
            }
        }
        // ── 아이템 배치 picker (3-컬럼 휠) — sheet medium detent 로 지도 절반이 보이게.
        .sheet(isPresented: $showPicker, onDismiss: { pendingCoord = nil; pickerType = nil }) {
            ItemPickerView(
                selectedType: $pickerType,
                showType: $pickerShowType,
                rangeAR: $pickerRangeAR
            ) {
                if let type = pickerType, let coord = pendingCoord {
                    viewModel.placeItem(at: coord, type: type, showType: pickerShowType, rangeAR: pickerRangeAR)
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        // ── pin callout 파란 버튼 → 상세 편집.
        // ItemDetailView 가 itemID 로 자체 복사본을 들기 때문에, 배열 인덱스를 캡처하지 않는다.
        .sheet(item: editingItemBinding()) { proxy in
            if let current = viewModel.items.first(where: { $0.itemID == proxy.id }) {
                NavigationStack {
                    ItemDetailView(item: current, viewModel: viewModel)
                }
            }
        }
        .onAppear {
            viewModel.validate()
            // 현재 위치 이동 버튼이 동작하도록 위치 서비스 시작.
            let loc = AppState.shared.locationService
            loc.requestPermission()
            loc.startUpdating()
        }
    }

    // MARK: - 초기 지도 영역

    /// 아이템이 있으면 그 좌표 평균. 없으면 기본 (튜토리얼 광장).
    private func regionForCurrentItems() -> MKCoordinateRegion {
        guard !viewModel.items.isEmpty else { return initialRegion }
        let lats = viewModel.items.map(\.latitude)
        let lons = viewModel.items.map(\.longitude)
        let center = CLLocationCoordinate2D(
            latitude: (lats.min()! + lats.max()!) / 2,
            longitude: (lons.min()! + lons.max()!) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((lats.max()! - lats.min()!) * 1.4, 0.002),
            longitudeDelta: max((lons.max()! - lons.min()!) * 1.4, 0.002)
        )
        return MKCoordinateRegion(center: center, span: span)
    }

    // MARK: - 검증 배너 (Candy)

    private var validationBanner: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(viewModel.validationErrors.prefix(3)) { err in
                HStack(spacing: 6) {
                    Image(systemName: err.isBlocking ? "exclamationmark.triangle.fill" : "info.circle.fill")
                        .foregroundColor(err.isBlocking ? .duoCardinalDeep : .duoFoxDeep)
                    Text(err.fallbackMessage)
                        .font(.duoBody(size: 12, weight: .semibold))
                        .foregroundColor(err.isBlocking ? .duoCardinalDeep : .duoFoxDeep)
                }
            }
            if viewModel.validationErrors.count > 3 {
                Text("외 \(viewModel.validationErrors.count - 3)건")
                    .font(.duoBody(size: 11))
                    .foregroundColor(.duoHare)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.duoCardinalBg.opacity(0.95)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.duoCardinal, lineWidth: 1.5))
        .padding(.horizontal, 12)
    }

    // MARK: - 하단 헬퍼 토스트 (Fox + 안내)

    private var bottomToolbar: some View {
        HStack(spacing: 10) {
            FoxMascot(pose: .think, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text("꾹 눌러서 아이템 배치 · 탭으로 설정")
                    .font(.duoDisplay(size: 12))
                    .foregroundColor(.white)
                Text("아이템 \(viewModel.items.count) · 필수 \(viewModel.items.filter { $0.isMandatory }.count)")
                    .font(.duoBody(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.duoEel2)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    // MARK: - Sheet item binding (editingItemID)

    private func editingItemBinding() -> Binding<EditingProxy?> {
        Binding(
            get: { editingItemID.map { EditingProxy(id: $0) } },
            set: { new in editingItemID = new?.id }
        )
    }

    private struct EditingProxy: Identifiable { let id: Int }
}

#if DEBUG
#Preview("MissionBuilderMap") {
    NavigationStack {
        MissionBuilderMapView(viewModel: MissionBuilderViewModel(userID: "preview"))
    }
}
#endif
