import AudioToolbox
import Foundation

@MainActor enum TapSound {
    private static let soundID: SystemSoundID? = {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("YumEditTap.wav")
        guard let data = makeWAV() else { return nil }
        do { try data.write(to: url, options: .atomic) } catch { return nil }
        var id: SystemSoundID = 0
        guard AudioServicesCreateSystemSoundID(url as CFURL, &id) == kAudioServicesNoError else { return nil }
        return id
    }()

    static func prepare() { _ = soundID }
    static func play() {
        guard let soundID else { return }
        AudioServicesPlaySystemSound(soundID)
    }

    private static func makeWAV() -> Data? {
        let rate = 22_050
        let count = Int(Double(rate) * 0.16)
        var pcm = Data(capacity: count * 2)
        for i in 0..<count {
            let t = Double(i) / Double(rate)
            let fade = pow(max(0, 1 - t / 0.16), 3)
            let pitch = 690 - 220 * t / 0.16
            let thock = sin(2 * .pi * pitch * t) * 0.33
            let tick = sin(2 * .pi * 1_440 * t) * 0.06
            var sample = Int16(clamping: Int((thock + tick) * fade * 32_767)).littleEndian
            withUnsafeBytes(of: &sample) { pcm.append(contentsOf: $0) }
        }
        var wav = Data()
        func u16(_ number: UInt16) {
            var value = number.littleEndian
            withUnsafeBytes(of: &value) { wav.append(contentsOf: $0) }
        }
        func u32(_ number: UInt32) {
            var value = number.littleEndian
            withUnsafeBytes(of: &value) { wav.append(contentsOf: $0) }
        }
        wav.append(contentsOf: "RIFF".utf8)
        u32(UInt32(36 + pcm.count))
        wav.append(contentsOf: "WAVEfmt ".utf8)
        u32(16)
        u16(1)
        u16(1)
        u32(UInt32(rate))
        u32(UInt32(rate * 2))
        u16(2)
        u16(16)
        wav.append(contentsOf: "data".utf8)
        u32(UInt32(pcm.count))
        wav.append(pcm)
        return wav
    }
}
