import SwiftUI
import Darwin

private let accent = Color(red: 0.13, green: 0.44, blue: 0.96)
private let accent2 = Color(red: 0.30, green: 0.68, blue: 1)
private let brand = LinearGradient(colors: [accent, accent2], startPoint: .topLeading, endPoint: .bottomTrailing)

struct ContentView: View {
    @State private var busy = false
    @State private var success = false
    @State private var experimental = false
    @State private var spoofProduct = "iPhone16,1"
    @State private var showRisk = false
    @State private var status = "备份 MobileGestalt 后，将已知机型的区域切换为美版。"

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            RadialGradient(colors: [accent.opacity(0.33), .black], center: .topLeading, startRadius: 20, endRadius: 680).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.system(size: 44)).foregroundStyle(brand)
                        .frame(width: 88, height: 88)
                        .background(Color(red: 1/255, green: 26/255, blue: 92/255), in: RoundedRectangle(cornerRadius: 24))
                    VStack(spacing: 8) {
                        Text("Siri AI · US").font(.system(size: 34, weight: .bold, design: .rounded))
                        Text("一键切换美版设备区域").font(.subheadline).foregroundStyle(.white.opacity(0.65))
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Label(success ? "缓存文件已写入并校验" : "设备状态", systemImage: success ? "checkmark.seal.fill" : "iphone.gen3")
                            .font(.headline)
                        Text(status).font(.subheadline).foregroundStyle(.white.opacity(0.72))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(20)
                    .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 22))
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.12)))
                    Toggle(isOn: $experimental) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("旧机型实验模式").font(.headline)
                            Text("iPhone 11 起；伪装设备身份，可能导致 Face ID 失效")
                                .font(.caption).foregroundStyle(.white.opacity(0.58))
                        }
                    }
                    .tint(.red)
                    .padding(20)
                    .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 22))
                    if experimental {
                        Picker("伪装机型", selection: $spoofProduct) {
                            ForEach(RegionWriter.spoofProfiles) { profile in
                                Text(profile.name).tag(profile.product)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.white)
                        .padding(16)
                        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
                    }
                    Button {
                        if experimental {
                            showRisk = true
                            return
                        }
                        run()
                    } label: {
                        Label(busy ? "处理中…" : "强制开启 Siri AI", systemImage: "sparkles")
                            .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 18)
                            .background(brand, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain).disabled(busy)
                    Text("仅写入已知机型。请先完成整机备份。")
                        .font(.footnote).foregroundStyle(.white.opacity(0.5))
                }
                .foregroundStyle(.white).padding(.horizontal, 24).padding(.top, 56)
                .frame(maxWidth: 600).frame(maxWidth: .infinity).padding(.bottom, 40)
            }
        }
        .fullScreenCover(isPresented: $showRisk) {
            ZStack {
                Color(red: 0.34, green: 0.02, blue: 0.04).ignoresSafeArea()
                VStack(spacing: 22) {
                    Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 70))
                    Text("高风险：设备身份伪装").font(.largeTitle.bold()).multilineTextAlignment(.center)
                    Text("将产品、硬件与 CPU 型号伪装为 \(RegionWriter.spoofProfiles.first(where: { $0.product == spoofProduct })?.name ?? "所选机型")，并把 SiriMode 设为 2。可能暂时破坏 Face ID、导致系统不稳定或循环重启，甚至需要恢复设备。效果未经验证。")
                        .font(.body).multilineTextAlignment(.center)
                    Button("我了解风险，继续写入") {
                        showRisk = false
                        run()
                    }
                    .font(.headline).padding(18).frame(maxWidth: .infinity)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.red)
                    Button("取消") { showRisk = false }.foregroundStyle(.white)
                }
                .padding(28).frame(maxWidth: 600)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func run() {
        busy = true
        status = "正在备份、写入并校验…"
        let oldDevice = experimental
        let selectedSpoof = spoofProduct
        Task.detached {
            let result = RegionWriter.apply(experimental: oldDevice, spoofProduct: selectedSpoof)
            await MainActor.run {
                busy = false
                success = result.0
                status = result.1
            }
        }
    }
}

nonisolated private enum RegionWriter {
    struct SpoofProfile: Identifiable, Sendable {
        let name: String
        let product: String
        let board: String
        let cpu: String
        let regulatory: String
        var id: String { product }
    }
    static let spoofProfiles: [SpoofProfile] = [
        .init(name: "iPhone 15 Pro", product: "iPhone16,1", board: "D83AP", cpu: "t8130", regulatory: "A2848"),
        .init(name: "iPhone 15 Pro Max", product: "iPhone16,2", board: "D84AP", cpu: "t8130", regulatory: "A2849"),
        .init(name: "iPhone 16", product: "iPhone17,3", board: "D47AP", cpu: "t8140", regulatory: "A3081"),
        .init(name: "iPhone 16 Plus", product: "iPhone17,4", board: "D48AP", cpu: "t8140", regulatory: "A3082"),
        .init(name: "iPhone 16 Pro", product: "iPhone17,1", board: "D93AP", cpu: "t8140", regulatory: "A3083"),
        .init(name: "iPhone 16 Pro Max", product: "iPhone17,2", board: "D94AP", cpu: "t8140", regulatory: "A3084"),
        .init(name: "iPhone 16e", product: "iPhone17,5", board: "V59AP", cpu: "t8140", regulatory: "A3212"),
        .init(name: "iPhone 17", product: "iPhone18,3", board: "V57AP", cpu: "t8150", regulatory: "A3258"),
        .init(name: "iPhone 17 Pro", product: "iPhone18,1", board: "V53AP", cpu: "t8150", regulatory: "A3256"),
        .init(name: "iPhone 17 Pro Max", product: "iPhone18,2", board: "V54AP", cpu: "t8150", regulatory: "A3257"),
        .init(name: "iPhone Air", product: "iPhone18,4", board: "D23AP", cpu: "t8150", regulatory: "A3260"),
        .init(name: "iPhone 17e", product: "iPhone18,5", board: "V159AP", cpu: "t8150", regulatory: "A3575")
    ]
    private static let dir = "/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches"
    private static let country = "h63QSdBCiT/z0WU6rdQv6Q"
    private static let region = "yK+xavymRGZ3xWc1tb8XDg"
    private static let regulatory = "97JDvERpVwO+GHtthIh7hA"
    private static let products: [String: String] = [
        "iPhone16,1": "A2848", "iPhone16,2": "A2849",
        "iPhone17,1": "A3083", "iPhone17,2": "A3084",
        "iPhone17,3": "A3081", "iPhone17,4": "A3082", "iPhone17,5": "A3212"
    ]
    private static let names: [String: String] = [
        "iPhone 15 Pro": "A2848", "iPhone 15 Pro Max": "A2849",
        "iPhone 16": "A3081", "iPhone 16 Plus": "A3082", "iPhone 16 Pro": "A3083",
        "iPhone 16 Pro Max": "A3084", "iPhone 16e": "A3212",
        "iPhone 17": "A3258", "iPhone 17 Pro": "A3256",
        "iPhone 17 Pro Max": "A3257", "iPhone 17e": "A3575", "iPhone Air": "A3260"
    ]

    nonisolated static func apply(experimental: Bool, spoofProduct: String) -> (Bool, String) {
        let signedGroups = YumEditSigningGroups() ?? []
        guard !signedGroups.isEmpty else {
            return (false, "当前签名没有 App Group。P12 证书本身不授予此权限；请使用包含 App Group 的 provisioning profile 重新签名。")
        }
        guard let group = signedGroups.first(where: {
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: $0) != nil
        }) else {
            return (false, "签名含 App Group，但其容器不可访问：\(signedGroups.joined(separator: ", "))")
        }
        let handle = worse_query(dir, group, false, false)
        guard handle >= 0 else { return (false, "无法访问 MobileGestalt（错误码：\(handle)）") }
        defer { worse_query_release(handle) }
        let target = URL(fileURLWithPath: dir).appendingPathComponent("com.apple.MobileGestalt.plist")
        do {
            let original = try Data(contentsOf: target)
            guard let root = try PropertyListSerialization.propertyList(from: original, format: nil) as? [String: Any],
                  var extra = root["CacheExtra"] as? [String: Any] else {
                return (false, "plist 结构不符合预期，未写入")
            }
            let machine = deviceIdentifier()
            let family = Int(machine.dropFirst(6).prefix(while: { $0.isNumber })) ?? 0
            let nameKeys = ["Z/dqyWS6OZTRy10UcmUAhw", "bbtR9jQx50Fv5Af/affNtA"]
            let name = nameKeys.compactMap { extra[$0] as? String }.first { names[$0] != nil }
            let nativeModel = products[machine] ?? (family >= 18 ? name.flatMap({ names[$0] }) : nil)
            let oldDevice = experimental && nativeModel == nil && (12...17).contains(family)
            guard let spoof = spoofProfiles.first(where: { $0.product == spoofProduct }) else {
                return (false, "未知伪装机型，未写入")
            }
            guard let model = oldDevice ? spoof.regulatory : nativeModel else {
                return (false, "未知机型 \(machine)，未写入")
            }
            if experimental && !oldDevice { return (false, "实验模式仅用于 iPhone 11 起的非原生 AI 机型") }
            if oldDevice && ProcessInfo.processInfo.operatingSystemVersion.majorVersion < 27 {
                return (false, "SiriMode 实验字段仅在 iOS 27 及以上启用")
            }
            guard let oldCountry = extra[country] as? String, ["CH", "LL"].contains(oldCountry),
                  let oldRegion = extra[region] as? String, ["CH/A", "LL/A"].contains(oldRegion),
                  extra[regulatory] is String else {
                return (false, "区域字段不是预期的 CH/A 或 LL/A，未写入")
            }
            if !oldDevice, oldCountry == "LL", oldRegion == "LL/A", extra[regulatory] as? String == model {
                return (true, "已经是美版目标值，无需写入")
            }
            let backups = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("GestaltBackups", isDirectory: true)
            try FileManager.default.createDirectory(at: backups, withIntermediateDirectories: true)
            let backup = backups.appendingPathComponent("MobileGestalt-\(UUID().uuidString).plist")
            try original.write(to: backup, options: .atomic)
            guard try Data(contentsOf: backup) == original else { return (false, "备份校验失败，未写入") }
            extra[country] = "LL"
            extra[region] = "LL/A"
            extra[regulatory] = model
            if oldDevice {
                extra["A62OafQ85EJAiiqKn4agtg"] = 1
                extra["h9jDsbgj7xIVeIQ8S3/X3Q"] = spoof.product
                extra["oYicEKzVTz4/CxxE05pEgQ"] = spoof.board
                extra["5pYKlGnYYBzGvAlIU8RjEQ"] = spoof.cpu
                extra["a3n5T9sFtlyQ74NEp9ESxg"] = 2
            }
            var modified = root
            modified["CacheExtra"] = extra
            let data = try PropertyListSerialization.data(fromPropertyList: modified, format: .binary, options: 0)
            do {
                try overwriteInPlace(data, at: target)
                let written = try Data(contentsOf: target)
                guard written == data else { throw WriteError.verify }
                let verifyRoot = try PropertyListSerialization.propertyList(from: written, format: nil) as? [String: Any]
                let verify = verifyRoot?["CacheExtra"] as? [String: Any]
                guard verify?[country] as? String == "LL", verify?[region] as? String == "LL/A",
                      verify?[regulatory] as? String == model else { throw WriteError.verify }
                if oldDevice {
                    guard verify?["a3n5T9sFtlyQ74NEp9ESxg"] as? Int == 2,
                          verify?["A62OafQ85EJAiiqKn4agtg"] as? Int == 1,
                          verify?["h9jDsbgj7xIVeIQ8S3/X3Q"] as? String == spoof.product,
                          verify?["oYicEKzVTz4/CxxE05pEgQ"] as? String == spoof.board,
                          verify?["5pYKlGnYYBzGvAlIU8RjEQ"] as? String == spoof.cpu else { throw WriteError.verify }
                }
            } catch {
                do {
                    try overwriteInPlace(original, at: target)
                    guard try Data(contentsOf: target) == original else { throw WriteError.restore }
                    return (false, "写入失败：\(error.localizedDescription)。已恢复并校验原始文件；备份位于 GestaltBackups。")
                } catch {
                    return (false, "严重错误：写入后恢复未能校验。请勿重启，使用 GestaltBackups 中的备份恢复。\(error.localizedDescription)")
                }
            }
            let profileText = oldDevice ? "；伪装为 \(spoof.name)" : ""
            return (true, "已写入 LL、LL/A、\(model)\(profileText) 并读回校验。请重启设备再检查 Siri AI；本结果只证明缓存文件已修改，不代表系统功能已启用。备份在“文件”App 的 GestaltBackups。")
        } catch {
            return (false, "操作失败：\(error.localizedDescription)。请检查 GestaltBackups。")
        }
    }

    private enum WriteError: LocalizedError {
        case verify, restore
        var errorDescription: String? { self == .verify ? "写后校验失败" : "恢复后校验失败" }
    }
    private static func overwriteInPlace(_ data: Data, at url: URL) throws {
        let fd = open(url.path, O_WRONLY | O_CLOEXEC)
        guard fd >= 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        defer { close(fd) }
        try data.withUnsafeBytes { raw in
            guard let base = raw.baseAddress else { throw POSIXError(.EINVAL) }
            var offset = 0
            while offset < raw.count {
                let count = pwrite(fd, base.advanced(by: offset), raw.count - offset, off_t(offset))
                if count < 0 && errno == EINTR { continue }
                guard count > 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
                offset += count
            }
        }
        guard ftruncate(fd, off_t(data.count)) == 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
        guard fsync(fd) == 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
    }
    private static func deviceIdentifier() -> String {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var bytes = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &bytes, &size, nil, 0)
        return String(cString: bytes)
    }
}
