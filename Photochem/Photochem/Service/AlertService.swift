import AVFoundation
import UIKit

/// Сигналы раннера — звук и хаптик вместе: у раковины руки мокрые, телефон поодаль,
/// и вибрация дублирует звук над шумом воды.
protocol AlertService: AnyObject {
    func activate()
    func deactivate()
    func playPreAlert()
    func playTick()
    func playStageEnd()
}

final class AlertServiceImpl: AlertService {
    private let audioSession: AVAudioSession

    private let preAlertHaptics = UINotificationFeedbackGenerator()
    private let tickHaptics = UIImpactFeedbackGenerator(style: .light)
    private let stageEndHaptics = UIImpactFeedbackGenerator(style: .heavy)

    private let preAlertPlayer: AVAudioPlayer?
    private let tickPlayer: AVAudioPlayer?
    private let stageEndPlayer: AVAudioPlayer?

    init(audioSession: AVAudioSession) {
        self.audioSession = audioSession

        preAlertPlayer = Self.player(named: "sound_pre")
        tickPlayer = Self.player(named: "sound_tick")
        stageEndPlayer = Self.player(named: "sound_end")

        preAlertPlayer?.prepareToPlay()
        tickPlayer?.prepareToPlay()
        stageEndPlayer?.prepareToPlay()
    }

    func activate() {
        try? audioSession.setCategory(.playback, options: [.duckOthers])
        try? audioSession.setActive(true)
        tickHaptics.prepare()
    }

    func deactivate() {
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
    }

    func playPreAlert() {
        preAlertHaptics.notificationOccurred(.warning)
        play(preAlertPlayer)
    }

    func playTick() {
        tickHaptics.impactOccurred()
        play(tickPlayer)
    }

    func playStageEnd() {
        play(stageEndPlayer)
        // Удар на каждый из трёх бипов sound_end (0 / 0.8 / 1.6 с) — одиночный success не чувствуется.
        Task { @MainActor in
            for beat in 0..<3 {
                if beat > 0 {
                    try? await Task.sleep(for: .milliseconds(800))
                }
                stageEndHaptics.impactOccurred()
            }
        }
    }

    private func play(_ player: AVAudioPlayer?) {
        player?.currentTime = 0
        player?.play()
    }

    private static func player(named name: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "caf") else {
            return nil
        }

        return try? AVAudioPlayer(contentsOf: url)
    }
}
