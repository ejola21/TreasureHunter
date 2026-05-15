// Services/SoundService.swift
import AVFoundation

final class SoundService {
    static let shared = SoundService()

    private var players: [Sound: AVAudioPlayer] = [:]

    enum Sound: String {
        case explosion = "s_explosion"
        case timer = "s_timer"
        case timeOver = "s_timeover"
        case quizCorrect = "quiz_rightanswer"
        case quizWrong = "quiz_wronganswer"
        case quizFail = "s_quiz_fail"
        case itemGet = "s_yougotit"
        case applause = "s_applause"
        case gogogo = "s_gogogo"
        case gameTouch = "s_game_touch"
        case winSomething = "s_winsomething"
        case radar = "s_radar"
        case gameFinish = "game_finish"
    }

    func play(_ sound: Sound) {
        if let player = players[sound] {
            player.currentTime = 0
            player.play()
            return
        }

        // mp3 먼저 시도, 없으면 wav
        let extensions = ["mp3", "wav"]
        for ext in extensions {
            if let url = Bundle.main.url(forResource: sound.rawValue, withExtension: ext) {
                if let player = try? AVAudioPlayer(contentsOf: url) {
                    player.prepareToPlay()
                    player.play()
                    players[sound] = player
                    return
                }
            }
        }
    }

    func stop(_ sound: Sound) {
        players[sound]?.stop()
    }

    func stopAll() {
        players.values.forEach { $0.stop() }
    }
}
