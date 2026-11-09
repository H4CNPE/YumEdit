import AudioToolbox
import Foundation

@MainActor enum TapSound {
    enum Cue: CaseIterable { case tap, confirm, warning, success, failure }
    private static let sounds: [Cue: SystemSoundID] = {
        var result: [Cue: SystemSoundID] = [:]
        for cue in Cue.allCases {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("YumEdit-\(cue).wav")
            try? makeWAV(cue).write(to: url, options: .atomic)
            var id: SystemSoundID = 0
            if AudioServicesCreateSystemSoundID(url as CFURL, &id) == kAudioServicesNoError { result[cue] = id }
        }
        return result
    }()

    static func prepare() { _ = sounds }
    static func play(_ cue: Cue = .tap) {
        guard let id = sounds[cue] else { return }
        AudioServicesPlaySystemSound(id)
    }

    private static func makeWAV(_ cue: Cue) -> Data {
        let rate = 22_050
        let duration: Double = cue == .tap ? 0.16 : 0.27
        let count = Int(Double(rate) * duration)
        var pcm = Data(capacity: count * 2)
        for i in 0..<count {
            let t = Double(i) / Double(rate)
            let fade = pow(max(0, 1 - t / duration), cue == .warning ? 1.8 : 3)
            let pitch: Double
            switch cue {
            case .tap: pitch = 690 - 220 * t / duration
            case .confirm: pitch = 510 + 260 * t / duration
            case .warning: pitch = 350 - 80 * t / duration
            case .success: pitch = t < duration / 2 ? 660 : 880
            case .failure: pitch = t < duration / 2 ? 480 : 320
            }
            let thock = sin(2 * .pi * pitch * t) * 0.33
            let tick = sin(2 * .pi * (pitch * 2.1) * t) * 0.06
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
