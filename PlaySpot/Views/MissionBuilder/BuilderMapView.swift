// Views/MissionBuilder/BuilderMapView.swift — UIKit MKMapView 래퍼
// 빌더 지도 전용. SwiftUI Map 의 한계 (longPress 좌표 캡처 불가, Annotation drag 미지원) 를
// 해소하기 위해 UIViewRepresentable 로 직접 감쌈.
//
// 외부 콜백:
//   onLongPress(coord)     — 빈 지도 영역 longPress
//   onTapItem(itemID)      — pin callout 의 파란 버튼 탭 (상세 진입)
//   onMoveItem(itemID, c)  — pin drag 끝
//
// 핀 탭 → callout 말풍선("Start 30m" + 파란 버튼) 표시. 선택 상태가 유지되어 드래그 가능.
// (레거시 old_img/design_img/런아이템 세부설정 진입화면.png 와 동일 흐름.)
//
// 외부 상태:
//   items                  — viewModel.items (Annotation 동기화)
//   region                 — 초기 카메라 영역 (한번만 사용)
import SwiftUI
import UIKit
import MapKit
import CoreLocation

struct BuilderMapView: UIViewRepresentable {
    var items: [MissionItem]
    var initialRegion: MKCoordinateRegion
    var onLongPress: (CLLocationCoordinate2D) -> Void
    var onTapItem: (Int) -> Void
    var onMoveItem: (Int, CLLocationCoordinate2D) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.setRegion(initialRegion, animated: false)
        map.showsUserLocation = true
        map.isRotateEnabled = false

        // longPress recognizer — 핀 위에서는 동작 안 하도록 delegate 로 분기.
        let lp = UILongPressGestureRecognizer(target: context.coordinator,
                                              action: #selector(Coordinator.handleLongPress(_:)))
        lp.minimumPressDuration = 0.5
        lp.delegate = context.coordinator
        map.addGestureRecognizer(lp)

        // 현재 위치 이동 버튼 (우상단) — 누르면 사용자 위치로 이동·추적.
        let trackingButton = MKUserTrackingButton(mapView: map)
        trackingButton.translatesAutoresizingMaskIntoConstraints = false
        trackingButton.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        trackingButton.layer.cornerRadius = 8
        trackingButton.layer.borderColor = UIColor.separator.cgColor
        trackingButton.layer.borderWidth = 0.5
        map.addSubview(trackingButton)
        NSLayoutConstraint.activate([
            trackingButton.trailingAnchor.constraint(equalTo: map.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            trackingButton.topAnchor.constraint(equalTo: map.safeAreaLayoutGuide.topAnchor, constant: 12),
            trackingButton.widthAnchor.constraint(equalToConstant: 40),
            trackingButton.heightAnchor.constraint(equalToConstant: 40),
        ])

        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        context.coordinator.parent = self

        // 기존 핀과 viewModel.items 의 diff 동기화.
        let existing = map.annotations.compactMap { $0 as? ItemAnnotation }
        let existingIDs = Set(existing.map(\.itemID))
        let newIDs = Set(items.map(\.itemID))

        // 제거
        for ann in existing where !newIDs.contains(ann.itemID) {
            map.removeAnnotation(ann)
        }
        // 추가 + 좌표/메타 갱신
        for it in items {
            let calloutTitle = "\(it.itemType.displayLabel) \(it.rangeAR)m"
            if let ann = existing.first(where: { $0.itemID == it.itemID }) {
                if ann.coordinate.latitude != it.latitude || ann.coordinate.longitude != it.longitude {
                    ann.coordinate = it.coordinate
                }
                ann.title = calloutTitle
                if ann.itemType != it.itemType.rawValue || ann.mandatory != it.isMandatory {
                    ann.itemType = it.itemType.rawValue
                    ann.mandatory = it.isMandatory
                    ann.iconName = it.mapIconName
                    if let view = map.view(for: ann) {
                        view.image = UIImage(named: it.mapIconName)
                    }
                }
            } else {
                let ann = ItemAnnotation(itemID: it.itemID,
                                         itemType: it.itemType.rawValue,
                                         mandatory: it.isMandatory,
                                         iconName: it.mapIconName,
                                         coordinate: it.coordinate,
                                         title: calloutTitle)
                map.addAnnotation(ann)
            }
        }

        // Mine(빨간 원) / Dark(검은 원) 반경 표시.
        // 좌표/반경/개수가 바뀔 수 있어 매번 재생성 (개수가 적어 비용 무시 가능).
        let oldMineCircles = map.overlays.compactMap { $0 as? MineRadiusCircle }
        let oldDarkCircles = map.overlays.compactMap { $0 as? DarkZoneCircle }
        map.removeOverlays(oldMineCircles)
        map.removeOverlays(oldDarkCircles)
        for it in items where it.itemType == .mine {
            let circle = MineRadiusCircle(center: it.coordinate,
                                          radius: CLLocationDistance(it.rangeAR))
            map.addOverlay(circle)
        }
        for it in items where it.itemType == .black {
            let circle = DarkZoneCircle(center: it.coordinate,
                                        radius: CLLocationDistance(it.rangeAR))
            map.addOverlay(circle)
        }
    }

    /// Mine 반경 식별용 MKCircle 서브클래스 (다른 overlay 와 구분).
    final class MineRadiusCircle: MKCircle {}

    /// Dark(다크존) 반경 식별용 MKCircle 서브클래스.
    final class DarkZoneCircle: MKCircle {}

    // MARK: - Annotation 모델

    final class ItemAnnotation: NSObject, MKAnnotation {
        let itemID: Int
        var itemType: String
        var mandatory: Bool
        var iconName: String
        @objc dynamic var coordinate: CLLocationCoordinate2D
        var title: String?
        init(itemID: Int, itemType: String, mandatory: Bool, iconName: String,
             coordinate: CLLocationCoordinate2D, title: String?) {
            self.itemID = itemID
            self.itemType = itemType
            self.mandatory = mandatory
            self.iconName = iconName
            self.coordinate = coordinate
            self.title = title
        }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        var parent: BuilderMapView
        init(_ parent: BuilderMapView) { self.parent = parent }

        // long-press 가 annotation view 위에서 시작되면 무시 (drag 와 충돌 방지).
        func gestureRecognizer(_ g: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            var v: UIView? = touch.view
            while v != nil {
                if v is MKAnnotationView { return false }
                v = v?.superview
            }
            return true
        }

        @objc func handleLongPress(_ g: UILongPressGestureRecognizer) {
            guard g.state == .began, let map = g.view as? MKMapView else { return }
            let point = g.location(in: map)
            let coord = map.convert(point, toCoordinateFrom: map)
            parent.onLongPress(coord)
        }

        // 반경 원 렌더러 — Mine 빨강 / Dark 검정.
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circle = overlay as? MineRadiusCircle {
                let r = MKCircleRenderer(circle: circle)
                r.fillColor = UIColor.systemRed.withAlphaComponent(0.18)
                r.strokeColor = UIColor.systemRed
                r.lineWidth = 2
                return r
            }
            if let circle = overlay as? DarkZoneCircle {
                let r = MKCircleRenderer(circle: circle)
                r.fillColor = UIColor.black.withAlphaComponent(0.30)
                r.strokeColor = UIColor.black
                r.lineWidth = 2
                return r
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let ia = annotation as? ItemAnnotation else { return nil }
            let id = "ItemPin"
            let view = (mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKAnnotationView)
                ?? MKAnnotationView(annotation: ia, reuseIdentifier: id)
            view.annotation = ia
            view.image = UIImage(named: ia.iconName)
            // 핀 탭 시 callout 말풍선 표시 — "Start 30m" + 우측 파란 버튼.
            view.canShowCallout = true
            view.isDraggable = true
            view.centerOffset = CGPoint(x: 0, y: -16)

            // 우측 파란 disclosure 버튼 (레거시 화면의 파란 원형 버튼).
            let chevron = UIButton(type: .system)
            chevron.setImage(UIImage(systemName: "chevron.right.circle.fill"), for: .normal)
            chevron.tintColor = .systemBlue
            chevron.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            view.rightCalloutAccessoryView = chevron
            return view
        }

        // callout 의 파란 버튼 탭 → 상세 화면 진입.
        func mapView(_ mapView: MKMapView,
                     annotationView view: MKAnnotationView,
                     calloutAccessoryControlTapped control: UIControl) {
            guard let ia = view.annotation as? ItemAnnotation else { return }
            parent.onTapItem(ia.itemID)
        }

        // didSelect 에서는 callout 만 띄우고 deselect 하지 않는다.
        // → 선택 상태가 유지되어 핀 드래그가 동작한다 (드래그 버그 수정의 핵심).

        // Drag — .ending 시점에 좌표 갱신.
        func mapView(_ mapView: MKMapView,
                     annotationView view: MKAnnotationView,
                     didChange newState: MKAnnotationView.DragState,
                     fromOldState oldState: MKAnnotationView.DragState) {
            guard let ia = view.annotation as? ItemAnnotation else { return }
            switch newState {
            case .ending, .canceling:
                view.setDragState(.none, animated: false)
                parent.onMoveItem(ia.itemID, ia.coordinate)
            default:
                break
            }
        }
    }
}
