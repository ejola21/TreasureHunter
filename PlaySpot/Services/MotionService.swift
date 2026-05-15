// Services/MotionService.swift — 가속도계/자이로 (기존 UIAccelerometer 대체)
import CoreMotion
import Observation

@Observable
final class MotionService {
    private let motionManager = CMMotionManager()

    var pitch: Double = 0    // 기존 acceleration.y 대체
    var roll: Double = 0     // 기존 acceleration.x 대체
    var yaw: Double = 0

    // 기존 GamePlayAlert의 shake 감지용
    var isShaking: Bool = false
    private var lastAcceleration: CMAcceleration?
    /// 레거시 ARViewController.m / GamePlayAlert.m:112 의 1.4G 임계.
    private let shakeThreshold: Double = 1.4

    func startUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        // 기존: updateInterval = 0.25
        motionManager.deviceMotionUpdateInterval = 0.25
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.pitch = motion.attitude.pitch
            self.roll = motion.attitude.roll
            self.yaw = motion.attitude.yaw
        }

        // 가속도계 (shake 감지)
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
                guard let self, let data else { return }
                self.detectShake(data.acceleration)
            }
        }
    }

    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
        motionManager.stopAccelerometerUpdates()
    }

    private func detectShake(_ acceleration: CMAcceleration) {
        if let last = lastAcceleration {
            let dx = acceleration.x - last.x
            let dy = acceleration.y - last.y
            let dz = acceleration.z - last.z
            let magnitude = sqrt(dx * dx + dy * dy + dz * dz)
            isShaking = magnitude > shakeThreshold
        }
        lastAcceleration = acceleration
    }
}
