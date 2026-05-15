// Services/HapticService.swift
import UIKit

final class HapticService {
    static let shared = HapticService()

    private let impactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    /// 기존: AudioServicesPlaySystemSound(kSystemSoundID_Vibrate) — 지뢰 폭발 시
    func vibrate() {
        impactGenerator.impactOccurred()
    }

    /// 성공 피드백 (미션 완료, 아이템 획득)
    func success() {
        notificationGenerator.notificationOccurred(.success)
    }

    /// 경고 피드백 (타이머 임박)
    func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }

    /// 에러 피드백 (퀴즈 오답)
    func error() {
        notificationGenerator.notificationOccurred(.error)
    }
}
