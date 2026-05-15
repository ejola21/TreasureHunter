// Game/TimerManager.swift
import Foundation

/// 시간 포맷 유틸리티 (기존 SBTickerView 숫자 표시 로직)
enum TimerFormatter {
    /// TimeInterval -> "HH:MM:SS" 포맷 변환
    static func format(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(max(0, interval))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    /// TimeInterval -> (hours, minutes, seconds) 개별 자릿수
    static func digits(_ interval: TimeInterval) -> (h1: Int, h2: Int, m1: Int, m2: Int, s1: Int, s2: Int) {
        let totalSeconds = Int(max(0, interval))
        let h = totalSeconds / 3600
        let m = (totalSeconds % 3600) / 60
        let s = totalSeconds % 60
        return (h / 10, h % 10, m / 10, m % 10, s / 10, s % 10)
    }
}
