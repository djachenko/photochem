import AVFoundation

protocol SoundService: AnyObject {
    func activate()
    func deactivate()
    func playPreAlert()
    func playStageEnd()
}

final class SoundServiceImpl: SoundService {
    private let audioSession: AVAudioSession

    private let preAlertPlayer: AVAudioPlayer?
    private let stageEndPlayer: AVAudioPlayer?

    init(audioSession: AVAudioSession) {
        self.audioSession = audioSession

        preAlertPlayer = Self.player(named: "sound_pre")
        stageEndPlayer = Self.player(named: "sound_end")

        preAlertPlayer?.prepareToPlay()
        stageEndPlayer?.prepareToPlay()
    }

    func activate() {
        try? audioSession.setCategory(.playback, options: [.duckOthers])
        try? audioSession.setActive(true)
    }

    func deactivate() {
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
    }

    func playPreAlert() {
        play(preAlertPlayer)
    }

    func playStageEnd() {
        play(stageEndPlayer)
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
