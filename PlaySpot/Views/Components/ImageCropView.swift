// Views/Components/ImageCropView.swift
// 1:1 정사각 크롭 — drag + pinch zoom. 외부 의존성 없음.
import SwiftUI

struct ImageCropView: View {
    let image: UIImage
    var cropPadding: CGFloat = 24
    let onCrop: (UIImage) -> Void
    let onCancel: () -> Void

    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height) - cropPadding * 2
            let cropFrame = CGRect(
                x: (geo.size.width - side) / 2,
                y: (geo.size.height - side) / 2,
                width: side, height: side
            )

            ZStack {
                Color.black.ignoresSafeArea()

                imageLayer

                // 어두운 마스크 + 정사각 hole
                Color.black.opacity(0.55)
                    .mask(
                        Rectangle()
                            .overlay(
                                Rectangle()
                                    .frame(width: side, height: side)
                                    .blendMode(.destinationOut)
                            )
                            .compositingGroup()
                    )
                    .allowsHitTesting(false)

                // 크롭 가이드 테두리
                Rectangle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: side, height: side)
                    .allowsHitTesting(false)
            }
            .gesture(combinedGesture)
            .overlay(alignment: .bottom) {
                bottomBar(geo: geo, cropFrame: cropFrame)
            }
            .overlay(alignment: .topLeading) {
                Text("드래그 + 핀치로 영역 조정")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.85))
                    .padding(8)
                    .background(.black.opacity(0.4), in: Capsule())
                    .padding(.top, 12).padding(.leading, 12)
            }
        }
        .statusBarHidden()
    }

    @ViewBuilder
    private var imageLayer: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .scaleEffect(scale)
            .offset(offset)
    }

    private var combinedGesture: some Gesture {
        let drag = DragGesture()
            .onChanged { v in
                offset = CGSize(width: lastOffset.width + v.translation.width,
                                height: lastOffset.height + v.translation.height)
            }
            .onEnded { _ in lastOffset = offset }

        let zoom = MagnifyGesture()
            .onChanged { v in
                scale = max(0.5, min(5.0, lastScale * v.magnification))
            }
            .onEnded { _ in lastScale = scale }

        return drag.simultaneously(with: zoom)
    }

    @ViewBuilder
    private func bottomBar(geo: GeometryProxy, cropFrame: CGRect) -> some View {
        HStack(spacing: 16) {
            Button(action: onCancel) {
                Text("취소")
                    .font(.callout.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
            }
            Button {
                let cropped = renderCropped(viewSize: geo.size, cropFrame: cropFrame)
                onCrop(cropped ?? image)
            } label: {
                Text("적용")
                    .font(.callout.bold())
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, max(geo.safeAreaInsets.bottom, 16))
    }

    // MARK: - 크롭 결과 생성
    //
    // 전체 뷰를 `ImageRenderer` 로 스냅샷한 뒤 cropFrame 영역만 잘라낸다.
    // SwiftUI 가 이미 적용해 둔 scale/offset/scaledToFit 변환을 그대로 받기 때문에
    // 좌표 변환을 수동으로 계산할 필요 없음.
    @MainActor
    private func renderCropped(viewSize: CGSize, cropFrame: CGRect) -> UIImage? {
        let content = ZStack {
            Color.black
            imageLayer
        }
        .frame(width: viewSize.width, height: viewSize.height)

        let renderer = ImageRenderer(content: content)
        renderer.scale = UIScreen.main.scale
        guard let snapshot = renderer.uiImage, let cg = snapshot.cgImage else { return nil }

        let s = snapshot.scale
        let pixelRect = CGRect(
            x: cropFrame.minX * s,
            y: cropFrame.minY * s,
            width: cropFrame.width * s,
            height: cropFrame.height * s
        )
        guard let cropped = cg.cropping(to: pixelRect) else { return nil }
        return UIImage(cgImage: cropped, scale: s, orientation: snapshot.imageOrientation)
    }
}

#if DEBUG
#Preview("Crop") {
    ImageCropView(image: UIImage(systemName: "photo.fill")!.withTintColor(.systemBlue)) { _ in } onCancel: {}
}
#endif
