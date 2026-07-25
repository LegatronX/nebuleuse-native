import AVFoundation

final class AudioManager {
    static let shared = AudioManager()
    private var player: AVAudioPlayer?

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func playMusic() {
        guard player == nil else {
            player?.play()
            return
        }
        guard let url = Bundle.main.url(forResource: "music-glass", withExtension: "mp3") else { return }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.volume = 0.7
            player?.play()
        } catch {
            player = nil
        }
    }

    func stopMusic() {
        player?.stop()
    }
}
