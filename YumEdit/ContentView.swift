import SwiftUI
import Darwin
import UniformTypeIdentifiers
import CoreFoundation

private let accent = Color(red: 0.13, green: 0.44, blue: 0.96)
private let accent2 = Color(red: 0.30, green: 0.68, blue: 1)
private let brand = LinearGradient(colors: [accent, accent2], startPoint: .topLeading, endPoint: .bottomTrailing)

struct ContentView: View {
    @ObservedObject private var quickAction = QuickActionState.shared
    @State private var busy = false
    @State private var success = false
    @State private var salesSource: RegionWriter.SalesSource = .china
    @State private var choseSalesSource = false
    @State private var deviceSnapshot: RegionWriter.DeviceSnapshot?
    @State private var snapshotError: String?
    @State private var readingSnapshot = true
    @State private var showRisk = false
    @State private var showExperimentsRisk = false
    @State private var showEuropeanRisk = false
    @State private var showIslandRisk = false
    @State private var showEditorRisk = false
    @State private var showRespringRisk = false
    @State private var respringActive = false
    @State private var showEditor = false
    @State private var showPresets = false
    @State private var showExperiments = false
    @State private var showOlderFlow = false
    @State private var showAbout = false
    @State private var showRestoreConfirm = false
    @State private var showImportPicker = false
    @State private var restoreURL: URL?
    @State private var restoreDescription = ""
    @State private var status = "备份 MobileGestalt 后，将已知机型的区域切换为美版。"

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            RadialGradient(colors: [accent.opacity(0.33), .black], center: .topLeading, startRadius: 20, endRadius: 680).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {
                    VStack(spacing: 8) {
                        Text("Siri AI · US").font(.system(size: 34, weight: .bold, design: .rounded))
                        Text("一键切换美版设备区域").font(.subheadline).foregroundStyle(.white.opacity(0.65))
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Label {
                            Text(YumLocalization.text(success ? "缓存文件已写入并校验" : "设备状态"))
                        } icon: {
                            Image(systemName: success ? "checkmark.seal.fill" : "iphone.gen3")
                        }
                            .font(.headline)
                        Text(YumLocalization.text(status)).font(.subheadline).foregroundStyle(.white.opacity(0.72))
                        if readingSnapshot {
                            Text("正在读取 MobileGestalt…").font(.footnote).foregroundStyle(.white.opacity(0.58))
                        } else if let deviceSnapshot {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(YumLocalization.text("机型：\(deviceSnapshot.physicalModel)"))
                                if deviceSnapshot.isSpoofed {
                                    Text(YumLocalization.text("缓存机型：\(deviceSnapshot.cachedModel)"))
                                        .foregroundStyle(.orange)
                                    Text("当前缓存的机型与真实设备不符")
                                        .foregroundStyle(.orange)
                                }
                                Text(YumLocalization.text("监管型号：\(deviceSnapshot.regulatoryModel)"))
                                Text(YumLocalization.text("销售地区：\(deviceSnapshot.country) / \(deviceSnapshot.region)"))
                                if deviceSnapshot.showsExperimentalAIFields {
                                    Text(YumLocalization.text(deviceSnapshot.siriMode.map { "SiriMode：\($0)" } ?? "SiriMode：缓存中无此键"))
                                    Text(YumLocalization.text(deviceSnapshot.generativeCapability.map { "生成式模型能力：\($0)" } ?? "生成式模型能力：缓存中无此键"))
                                }
                            }
                            .font(.footnote.monospacedDigit())
                            .foregroundStyle(.white.opacity(0.75))
                        } else if let snapshotError {
                            Text(YumLocalization.text("读取失败：\(snapshotError)"))
                                .font(.footnote).foregroundStyle(.orange)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(16)
                    .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 22))
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.12)))
                    Picker("销售地区", selection: $salesSource) {
                        Text("国行").tag(RegionWriter.SalesSource.china)
                        Text("欧版").tag(RegionWriter.SalesSource.europe)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: salesSource) { _, _ in choseSalesSource = true; TapSound.play(.confirm) }
                    .padding(12)
                    .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
                    Button {
                        if deviceSnapshot?.isOlderDevice == true {
                            TapSound.play(.warning)
                            showOlderFlow = true
                            return
                        }
                        if deviceSnapshot?.isSpoofed == true {
                            TapSound.play(.warning)
                            showRisk = true
                            return
                        }
                        if salesSource == .europe {
                            TapSound.play(.warning)
                            showEuropeanRisk = true
                            return
                        }
                        TapSound.play()
                        run()
                    } label: {
                        Label {
                            Text(deviceSnapshot?.isOlderDevice == true && !busy
                                ? YumLocalization.text("旧机型两阶段") + " · " + YumLocalization.text("实验性选项")
                                : YumLocalization.text(busy ? "处理中…" : (deviceSnapshot?.isComplete == true ? "已完成，无需再次写入" : (deviceSnapshot?.isSpoofed == true ? "恢复真实机型并启动 Apple Intelligence" : "更改销售地区并启动 Apple Intelligence"))))
                        } icon: {
                            Image(systemName: "sparkles")
                        }
                            .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 18)
                            .background(brand, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain).disabled(busy || readingSnapshot || deviceSnapshot == nil || deviceSnapshot?.isComplete == true)
                    if RegionWriter.hasSmallNotch {
                        Button {
                            TapSound.play(.warning)
                            showIslandRisk = true
                        } label: {
                            Label("实验：灵动岛布局", systemImage: "capsule")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain).disabled(busy)
                    }
                    HStack(spacing: 10) {
                        Button {
                        TapSound.play()
                        do {
                            let candidate = try RegionWriter.latestBackup()
                            restoreURL = candidate.url
                            restoreDescription = candidate.description
                            showRestoreConfirm = true
                        } catch RegionWriter.RestoreError.noBackup {
                            TapSound.play(.warning)
                            showImportPicker = true
                        } catch {
                            success = false
                            status = "无法准备恢复：\(error.localizedDescription)"
                            TapSound.play(.failure)
                        }
                        } label: {
                        Label("恢复最近一次 plist 备份", systemImage: "arrow.uturn.backward")
                            .font(.footnote.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain).disabled(busy)
                        .contextMenu {
                        Button {
                            guard !busy else { return }
                            TapSound.play(.warning)
                            showImportPicker = true
                        } label: {
                            Label("从「文件」选择 plist", systemImage: "doc.badge.arrow.up")
                        }
                        }
                        Button {
                        TapSound.play(.warning)
                        showRespringRisk = true
                        } label: {
                        Label("Respring", systemImage: "arrow.clockwise")
                            .font(.footnote.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                        }
                        .accessibilityLabel("Respring（重启 SpringBoard）")
                        .buttonStyle(.plain).disabled(busy)
                    }
                    Text("长按恢复按钮，可从「文件」选择同一设备的 MobileGestalt plist。")
                        .font(.caption).foregroundStyle(.white.opacity(0.5))
                    HStack(spacing: 10) {
                        Button {
                            TapSound.play(.warning)
                            showEditorRisk = true
                        } label: {
                            Label("字段编辑", systemImage: "slider.horizontal.3")
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                        }
                        Button {
                            TapSound.play()
                            showPresets = true
                        } label: {
                            Label("预设修改", systemImage: "switch.2")
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .font(.footnote.weight(.medium)).buttonStyle(.plain).disabled(busy)
                    Button {
                        TapSound.play(.warning)
                        showExperimentsRisk = true
                    } label: {
                        Label("实验性选项", systemImage: "flask")
                            .font(.footnote.weight(.semibold))
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain).disabled(busy)
                    Text("仅写入已知机型。请先完成整机备份。")
                        .font(.footnote).foregroundStyle(.white.opacity(0.5))
                    Button {
                        TapSound.play()
                        showAbout = true
                    } label: {
                        Image(systemName: "info.circle").font(.title3)
                            .foregroundStyle(.white.opacity(0.65))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("贡献者与仓库")
                    .buttonStyle(.plain)
                }
                .foregroundStyle(.white).padding(.horizontal, 20).padding(.top, 16)
                .frame(maxWidth: 600).frame(maxWidth: .infinity).padding(.bottom, 20)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .fullScreenCover(isPresented: $showRisk) {
            ZStack {
                Color(red: 0.34, green: 0.02, blue: 0.04).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 22) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 70))
                        Text("高风险：恢复真实机型").font(.largeTitle.bold()).multilineTextAlignment(.center)
                        Text(YumLocalization.text("检测到旧版机型伪装。将从同设备、同 CacheData 的历史备份恢复真实身份，再修改销售区域、监管型号与 SiriMode。找不到可信备份则不写入。请先备份整机。"))
                            .font(.body).multilineTextAlignment(.center)
                        Button("我了解风险，继续写入") {
                            TapSound.play(.confirm)
                            showRisk = false
                            run()
                        }
                        .font(.headline).padding(18).frame(maxWidth: .infinity)
                        .background(.white, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.red)
                        Button("取消") { TapSound.play(); showRisk = false }.foregroundStyle(.white)
                    }
                    .padding(28).frame(maxWidth: 600).frame(maxWidth: .infinity)
                }
            }
        }
        .fullScreenCover(isPresented: $showExperimentsRisk) {
            RiskScreen(title: "高风险：实验性选项", detail: "外接屏与硬件身份恢复均未经当前设备验证，可能影响音频、Face ID 或系统稳定性。请先备份整机。各项写入仍会再次确认。", action: "我了解风险，进入实验性选项") {
                showExperimentsRisk = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showExperiments = true }
            } cancel: { showExperimentsRisk = false }
        }
        .fullScreenCover(isPresented: $showIslandRisk) {
            RiskScreen(title: "高风险：灵动岛布局", detail: "参考 BQTool 修改 Dynamic Island 与 ArtworkDeviceSubType。iPhone 18 Pro 专用值尚未核实，本选项使用已知 16 Pro 布局值 2622 试验；可能错位、遮挡状态栏或影响 Face ID。写入前会备份；重启或 respring 后观察。", action: "我了解风险，继续写入") {
                showIslandRisk = false
                runIsland()
            } cancel: { showIslandRisk = false }
        }
        .fullScreenCover(isPresented: $showEuropeanRisk) {
            RiskScreen(title: "高风险：欧洲设备区域修改", detail: "仅接受已知欧洲销售代码与匹配的监管型号。写入将把销售区域改为 LL/A，并为已知机型写入对应美版监管型号。修改设备身份可能影响系统功能；请先备份。", action: "我了解风险，继续写入") {
                showEuropeanRisk = false
                run()
            } cancel: { showEuropeanRisk = false }
        }
        .fullScreenCover(isPresented: $showEditorRisk) {
            RiskScreen(title: "高风险：字段编辑器", detail: "此页面可直接新增、删除和改写 MobileGestalt 的 CacheExtra 字段。错误的键、类型或值可能导致系统功能失效、循环重启，甚至需要恢复设备。请先备份整机；每次写入前仍会再次确认。", action: "我了解风险，进入编辑器") {
                showEditorRisk = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showEditor = true }
            } cancel: { showEditorRisk = false }
        }
        .fullScreenCover(isPresented: $showRespringRisk) {
            RiskScreen(title: "高风险：Respring", detail: "参考 BQTool 的 NeoSpring 方式触发 SpringBoard 重启。所有打开的 App 会关闭，未保存内容可能丢失；此方式在不同 iPadOS / iOS 版本上不保证成功。", action: "我了解风险，Respring") {
                showRespringRisk = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { respringActive = true }
            } cancel: { showRespringRisk = false }
        }
        .fullScreenCover(isPresented: $respringActive) { NeoSpringView() }
        .sheet(isPresented: $showEditor) { GestaltEditorView() }
        .sheet(isPresented: $showPresets) { PresetsView() }
        .sheet(isPresented: $showExperiments) { ExperimentsView() }
        .sheet(isPresented: $showOlderFlow) { OlderDeviceFlowView(source: salesSource) }
        .sheet(isPresented: $showAbout) { AboutView().presentationDetents([.medium]) }
        .alert("恢复 MobileGestalt 备份", isPresented: $showRestoreConfirm) {
            Button("恢复所示备份", role: .destructive) {
                guard let restoreURL else { return }
                TapSound.play(.confirm)
                runRestore(restoreURL)
            }
            Button("取消", role: .cancel) { TapSound.play() }
        } message: {
            Text(restoreDescription + "\n\n" + YumLocalization.text("仅恢复同一设备的 plist。文件可能已被其他工具修改；恢复结果取决于文件内容。当前缓存会另存为 PreRestore 备份。恢复后需重启。"))
        }
        .fileImporter(isPresented: $showImportPicker, allowedContentTypes: [.item]) { result in
            do {
                let url = try result.get()
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                let candidate = try RegionWriter.importBackup(from: url)
                restoreURL = candidate.url
                restoreDescription = candidate.description
                showRestoreConfirm = true
                TapSound.play(.confirm)
            } catch {
                let nsError = error as NSError
                if nsError.domain == NSCocoaErrorDomain && nsError.code == NSUserCancelledError { return }
                success = false
                status = "导入备份失败：\(error.localizedDescription)"
                TapSound.play(.failure)
            }
        }
        .onAppear {
            TapSound.prepare()
            refreshSnapshot()
            presentRespringShortcutIfNeeded()
        }
        .onChange(of: quickAction.respringRequested) { _, _ in presentRespringShortcutIfNeeded() }
        .onChange(of: showExperiments) { _, visible in if !visible { refreshSnapshot() } }
        .onChange(of: showOlderFlow) { _, visible in if !visible { refreshSnapshot() } }
        .onChange(of: showEditor) { _, visible in if !visible { refreshSnapshot() } }
        .onChange(of: showPresets) { _, visible in if !visible { refreshSnapshot() } }
        .preferredColorScheme(.dark)
    }

    private func presentRespringShortcutIfNeeded() {
        guard quickAction.respringRequested else { return }
        quickAction.respringRequested = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showRespringRisk = true }
    }

    private func refreshSnapshot() {
        readingSnapshot = true
        Task.detached {
            let result = RegionWriter.readDeviceSnapshot()
            await MainActor.run {
                deviceSnapshot = result.0
                snapshotError = result.1
                readingSnapshot = false
                if let snapshot = result.0, !choseSalesSource,
                   RegionWriter.isEuropeanSalesCode(snapshot.country) {
                    salesSource = .europe
                }
            }
        }
    }

    private func run() {
        busy = true
        status = "正在备份、写入并校验…"
        let selectedSource = salesSource
        Task.detached {
            let result = RegionWriter.apply(source: selectedSource)
            await MainActor.run {
                busy = false
                success = result.0
                status = result.1
                TapSound.play(result.0 ? .success : .failure)
                refreshSnapshot()
            }
        }
    }
    private func runRestore(_ backup: URL) {
        busy = true
        status = "正在保存当前缓存并恢复备份…"
        Task.detached {
            let result = RegionWriter.restore(from: backup)
            await MainActor.run {
                busy = false
                success = result.0
                status = result.1
                TapSound.play(result.0 ? .success : .failure)
                refreshSnapshot()
            }
        }
    }
    private func runIsland() {
        busy = true
        status = "正在备份并写入灵动岛字段…"
        Task.detached {
            let result = RegionWriter.applyIsland()
            await MainActor.run { busy = false; success = result.0; status = result.1; TapSound.play(result.0 ? .success : .failure) }
        }
    }
}

nonisolated enum RegionWriter {
    enum SalesSource: String, Sendable { case china, europe }
    struct DeviceSnapshot: Sendable {
        let physicalModel: String
        let cachedModel: String
        let regulatoryModel: String
        let country: String
        let region: String
        let siriMode: Int?
        let generativeCapability: Int?
        let isSpoofed: Bool
        let showsExperimentalAIFields: Bool
        let isComplete: Bool
        let isOlderDevice: Bool
    }
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
    static let padSpoofProfiles: [SpoofProfile] = [
        .init(name: "iPad Pro 11 英寸 M4 Wi-Fi", product: "iPad16,3", board: "J717AP", cpu: "t8132", regulatory: "A2836"),
        .init(name: "iPad Pro 11 英寸 M4 蜂窝", product: "iPad16,4", board: "J718AP", cpu: "t8132", regulatory: "A2837")
    ]
    static var isPad: Bool { deviceIdentifier().hasPrefix("iPad") }
    static var isOlderPhysicalDevice: Bool { olderUSModels[deviceIdentifier()] != nil }
    static var hasSmallNotch: Bool {
        ["iPhone14,2", "iPhone14,3", "iPhone14,4", "iPhone14,5", "iPhone14,7", "iPhone14,8"].contains(deviceIdentifier())
    }
    private static let dir = "/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches"
    private static let country = "h63QSdBCiT/z0WU6rdQv6Q"
    private static let region = "yK+xavymRGZ3xWc1tb8XDg"
    private static let regulatory = "97JDvERpVwO+GHtthIh7hA"
    private static let productKey = "h9jDsbgj7xIVeIQ8S3/X3Q"
    private static let boardKey = "oYicEKzVTz4/CxxE05pEgQ"
    private static let cpuKey = "5pYKlGnYYBzGvAlIU8RjEQ"
    private static let siriModeKey = "a3n5T9sFtlyQ74NEp9ESxg"
    private static let generativeKey = "A62OafQ85EJAiiqKn4agtg"
    // Physical model identifiers and exact regulatory models from Apple's iPhone model list.
    // The older family is experimental; unknown variants are never guessed.
    private static let olderUSModels: [String: String] = [
        "iPhone12,1": "A2111", "iPhone12,3": "A2160", "iPhone12,5": "A2161", "iPhone12,8": "A2275",
        "iPhone13,1": "A2176", "iPhone13,2": "A2172", "iPhone13,3": "A2341", "iPhone13,4": "A2342",
        "iPhone14,2": "A2483", "iPhone14,3": "A2484", "iPhone14,4": "A2481", "iPhone14,5": "A2482",
        "iPhone14,6": "A2595", "iPhone14,7": "A2649", "iPhone14,8": "A2632",
        "iPhone15,2": "A2650", "iPhone15,3": "A2651", "iPhone15,4": "A2846", "iPhone15,5": "A2847"
    ]
    private static let chinaIPhoneModels: [String: String] = [
        "iPhone12,1": "A2223", "iPhone12,3": "A2217", "iPhone12,5": "A2220", "iPhone12,8": "A2298",
        "iPhone13,1": "A2400", "iPhone13,2": "A2404", "iPhone13,3": "A2408", "iPhone13,4": "A2412",
        "iPhone14,2": "A2639", "iPhone14,3": "A2644", "iPhone14,4": "A2629", "iPhone14,5": "A2634",
        "iPhone14,6": "A2785", "iPhone14,7": "A2884", "iPhone14,8": "A2888",
        "iPhone15,2": "A2892", "iPhone15,3": "A2896", "iPhone15,4": "A3092", "iPhone15,5": "A3096",
        "iPhone16,1": "A3104", "iPhone16,2": "A3108",
        "iPhone17,1": "A3294", "iPhone17,2": "A3297", "iPhone17,3": "A3288", "iPhone17,4": "A3291", "iPhone17,5": "A3410",
        "iPhone18,1": "A3524", "iPhone18,2": "A3527", "iPhone18,3": "A3521", "iPhone18,4": "A3518", "iPhone18,5": "A3635",
        "iPhone19,2": "A3715", "iPhone19,7": "A3718", "iPhone19,4": "A3721"
    ]
    // libirecovery's physical board identifiers. Historical backups must match
    // these before restoring identity; a ProductType-only partial restore is unsafe.
    private static let physicalBoards: [String: String] = [
        "iPhone12,1":"N104AP", "iPhone12,3":"D421AP", "iPhone12,5":"D431AP", "iPhone12,8":"D79AP",
        "iPhone13,1":"D52GAP", "iPhone13,2":"D53GAP", "iPhone13,3":"D53PAP", "iPhone13,4":"D54PAP",
        "iPhone14,2":"D63AP", "iPhone14,3":"D64AP", "iPhone14,4":"D16AP", "iPhone14,5":"D17AP",
        "iPhone14,6":"D49AP", "iPhone14,7":"D27AP", "iPhone14,8":"D28AP",
        "iPhone15,2":"D73AP", "iPhone15,3":"D74AP", "iPhone15,4":"D37AP", "iPhone15,5":"D38AP",
        "iPhone16,1":"D83AP", "iPhone16,2":"D84AP",
        "iPhone17,1":"D93AP", "iPhone17,2":"D94AP", "iPhone17,3":"D47AP", "iPhone17,4":"D48AP", "iPhone17,5":"V59AP",
        "iPhone18,1":"V53AP", "iPhone18,2":"V54AP", "iPhone18,3":"V57AP", "iPhone18,4":"D23AP", "iPhone18,5":"V159AP",
        "iPhone19,2":"V63AP", "iPhone19,3":"V64AP", "iPhone19,4":"V68AP", "iPhone19,7":"V64SAP",
        "iPad13,4":"J517AP", "iPad13,5":"J517XAP", "iPad13,6":"J518AP", "iPad13,7":"J518XAP",
        "iPad13,8":"J522AP", "iPad13,9":"J522XAP", "iPad13,10":"J523AP", "iPad13,11":"J523XAP",
        "iPad13,16":"J407AP", "iPad13,17":"J408AP",
        "iPad14,3":"J617AP", "iPad14,4":"J618AP", "iPad14,5":"J620AP", "iPad14,6":"J621AP",
        "iPad14,8":"J507AP", "iPad14,9":"J508AP", "iPad14,10":"J537AP", "iPad14,11":"J538AP",
        "iPad15,3":"J607AP", "iPad15,4":"J608AP", "iPad15,5":"J637AP", "iPad15,6":"J638AP",
        "iPad16,1":"J410AP", "iPad16,2":"J411AP", "iPad16,3":"J717AP", "iPad16,4":"J718AP",
        "iPad16,5":"J720AP", "iPad16,6":"J721AP", "iPad16,8":"J707AP", "iPad16,9":"J708AP",
        "iPad16,10":"J737AP", "iPad16,11":"J738AP",
        "iPad17,1":"J817AP", "iPad17,2":"J818AP", "iPad17,3":"J820AP", "iPad17,4":"J821AP",
        "iPad19,1":"J510AP", "iPad19,2":"J511AP"
    ]
    private static func physicalCPU(for machine: String) -> String? {
        let family = Int(machine.drop(while: { !$0.isNumber }).prefix(while: { $0.isNumber }))
        if machine.hasPrefix("iPhone") {
            switch family {
            case 12: return "t8030"
            case 13: return "t8101"
            case 14: return "t8110"
            case 15: return "t8120"
            case 16: return "t8130"
            case 17: return "t8140"
            case 18: return "t8150"
            case 19: return "t8160"
            default: return nil
            }
        }
        if machine.hasPrefix("iPad") {
            switch family {
            case 13: return "t8103"
            case 14: return "t8112"
            case 15: return "t8122"
            case 16: return ["iPad16,1", "iPad16,2"].contains(machine) ? "t8130" : "t8132"
            case 17: return "t8142"
            case 19: return "t8160"
            default: return nil
            }
        }
        return nil
    }
    // Sales suffixes reported for European markets. Require both fields to match exactly.
    private static let europeanSalesCodes: Set<String> = [
        "B", "CZ", "D", "DN", "EE", "FB", "FD", "GR", "IP", "KN", "KS",
        "MG", "NF", "PL", "PO", "RO", "SL", "T", "TY", "ZD"
    ]
    static func isEuropeanSalesCode(_ code: String) -> Bool { europeanSalesCodes.contains(code) }
    static func readDeviceSnapshot() -> (DeviceSnapshot?, String?) {
        do {
            let handle = try accessHandle()
            defer { worse_query_release(handle) }
            let root = try readRoot()
            guard let extra = root["CacheExtra"] as? [String: Any] else { throw WriteError.verify }
            let physical = deviceIdentifier()
            let cached = extra[productKey] as? String ?? "—"
            let expectedBoard = physicalBoards[physical]
            let expectedCPU = physicalCPU(for: physical)
            let countryValue = extra[country] as? String ?? "—"
            let regionValue = extra[region] as? String ?? "—"
            let regulatoryValue = extra[regulatory] as? String ?? "—"
            let siriModeValue = extra[siriModeKey] as? Int
            let generativeValue = extra[generativeKey] as? Int
            let changedIdentity = cached != "—" && (
                cached != physical ||
                (expectedBoard != nil && extra[boardKey] as? String != expectedBoard) ||
                (expectedCPU != nil && extra[cpuKey] as? String != expectedCPU))
            let nativeAI = products[physical] != nil || padModels[physical] != nil
            let targetModelMatches = products[physical].map { $0 == regulatoryValue }
                ?? (padModels[physical]?.values.contains(regulatoryValue) == true)
            let isComplete = nativeAI && !changedIdentity && cached == physical &&
                countryValue == "LL" && regionValue == "LL/A" && targetModelMatches
            let snapshot = DeviceSnapshot(
                physicalModel: physical,
                cachedModel: cached,
                regulatoryModel: regulatoryValue,
                country: countryValue,
                region: regionValue,
                siriMode: siriModeValue,
                generativeCapability: generativeValue,
                isSpoofed: changedIdentity,
                showsExperimentalAIFields: !nativeAI,
                isComplete: isComplete,
                isOlderDevice: olderUSModels[physical] != nil)
            return (snapshot, nil)
        } catch {
            return (nil, error.localizedDescription)
        }
    }
    // Apple lists these as the "other countries and regions" regulatory models.
    private static let europeanIPhoneModels: [String: String] = [
        "iPhone12,1": "A2221", "iPhone12,3": "A2215", "iPhone12,5": "A2218", "iPhone12,8": "A2296",
        "iPhone13,1": "A2399", "iPhone13,2": "A2403", "iPhone13,3": "A2407", "iPhone13,4": "A2411",
        "iPhone14,2": "A2638", "iPhone14,3": "A2643", "iPhone14,4": "A2628", "iPhone14,5": "A2633",
        "iPhone14,6": "A2783", "iPhone14,7": "A2882", "iPhone14,8": "A2886",
        "iPhone15,2": "A2890", "iPhone15,3": "A2894", "iPhone15,4": "A3090", "iPhone15,5": "A3094",
        "iPhone16,1": "A3102", "iPhone16,2": "A3106",
        "iPhone17,1": "A3293", "iPhone17,2": "A3296",
        "iPhone17,3": "A3287", "iPhone17,4": "A3290", "iPhone17,5": "A3409",
        "iPhone18,1": "A3523", "iPhone18,2": "A3526", "iPhone18,3": "A3520",
        "iPhone18,4": "A3517", "iPhone18,5": "A3634",
        "iPhone19,2": "A3714", "iPhone19,7": "A3717", "iPhone19,4": "A3720"
    ]
    private static let products: [String: String] = [
        "iPhone16,1": "A2848", "iPhone16,2": "A2849",
        "iPhone17,1": "A3083", "iPhone17,2": "A3084", "iPhone17,3": "A3081",
        "iPhone17,4": "A3082", "iPhone17,5": "A3212",
        "iPhone18,1": "A3256", "iPhone18,2": "A3257", "iPhone18,3": "A3258",
        "iPhone18,4": "A3260", "iPhone18,5": "A3575",
        "iPhone19,2": "A3472", "iPhone19,3": "A3473", "iPhone19,7": "A3473", "iPhone19,4": "A3447"
    ]
    private static let names: [String: String] = [
        "iPhone 15 Pro": "A2848", "iPhone 15 Pro Max": "A2849",
        "iPhone 16": "A3081", "iPhone 16 Plus": "A3082", "iPhone 16 Pro": "A3083",
        "iPhone 16 Pro Max": "A3084", "iPhone 16e": "A3212",
        "iPhone 17": "A3258", "iPhone 17 Pro": "A3256",
        "iPhone 17 Pro Max": "A3257", "iPhone 17e": "A3575", "iPhone Air": "A3260",
        "iPhone Duo": "A3447"
    ]
    // Each pair is the exact physical identifier and regulatory model from Apple's model list.
    // Unknown combinations are refused instead of guessing a US model.
    private static let padModels: [String: [String: String]] = [
        "iPad13,4": ["A2377":"A2377"], "iPad13,5": ["A2377":"A2377"],
        "iPad13,6": ["A2460":"A2459"], "iPad13,7": ["A2460":"A2459"],
        "iPad13,8": ["A2378":"A2378"], "iPad13,9": ["A2378":"A2378"],
        "iPad13,10": ["A2462":"A2461"], "iPad13,11": ["A2462":"A2461"],
        "iPad13,16": ["A2588":"A2588"], "iPad13,17": ["A2589":"A2589", "A2591":"A2591"],
        "iPad14,3": ["A2759":"A2759"], "iPad14,4": ["A2762":"A2761"],
        "iPad14,5": ["A2436":"A2436"], "iPad14,6": ["A2766":"A2437"],
        "iPad14,8": ["A2902":"A2902"], "iPad14,9": ["A2904":"A2903"],
        "iPad14,10": ["A2898":"A2898"], "iPad14,11": ["A2900":"A2899"],
        "iPad15,3": ["A3266":"A3266"], "iPad15,4": ["A3270":"A3267"],
        "iPad15,5": ["A3268":"A3268"], "iPad15,6": ["A3271":"A3269"],
        "iPad16,1": ["A2993":"A2993"], "iPad16,2": ["A2996":"A2995"],
        "iPad16,3": ["A2836":"A2836"], "iPad16,4": ["A3006":"A2837"],
        "iPad16,5": ["A2925":"A2925"], "iPad16,6": ["A3007":"A2926"],
        "iPad16,8": ["A3459":"A3459"], "iPad16,9": ["A3463":"A3460"],
        "iPad16,10": ["A3461":"A3461"], "iPad16,11": ["A3464":"A3462"],
        "iPad17,1": ["A3357":"A3357"], "iPad17,2": ["A3359":"A3358"],
        "iPad17,3": ["A3360":"A3360"], "iPad17,4": ["A3362":"A3361"],
        "iPad19,1": ["A3595":"A3595"], "iPad19,2": ["A3597":"A3596"]
    ]
    private static var backupDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("GestaltBackups", isDirectory: true)
    }

    struct BackupChoice: Sendable {
        let url: URL
        let description: String
    }
    static func latestBackup() throws -> BackupChoice {
        guard FileManager.default.fileExists(atPath: backupDirectory.path) else {
            throw RestoreError.noBackup
        }
        let files = try FileManager.default.contentsOfDirectory(
            at: backupDirectory, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles)
            .filter { $0.lastPathComponent.hasPrefix("MobileGestalt-") && $0.pathExtension == "plist" }
        guard let url = files.max(by: {
            let a = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let b = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            return a < b
        }) else { throw RestoreError.noBackup }
        let data = try Data(contentsOf: url)
        guard let root = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let extra = root["CacheExtra"] as? [String: Any] else { throw RestoreError.invalidBackup }
        let area = extra[region] as? String ?? "未知区域"
        let model = extra[regulatory] as? String ?? "未知型号"
        return BackupChoice(url: url, description: "\(url.lastPathComponent)\n\(area) · \(model)")
    }

    static func importBackup(from source: URL) throws -> BackupChoice {
        let data = try Data(contentsOf: source)
        guard let root = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let extra = root["CacheExtra"] as? [String: Any],
              extra[country] is String, extra[region] is String, extra[regulatory] is String else {
            throw RestoreError.invalidBackup
        }
        try FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        let stored = backupDirectory.appendingPathComponent("MobileGestalt-Imported-\(UUID().uuidString).plist")
        try data.write(to: stored, options: .atomic)
        guard try Data(contentsOf: stored) == data else { throw RestoreError.invalidBackup }
        return BackupChoice(url: stored, description: "\(source.lastPathComponent)\n\(extra[region] as? String ?? "未知区域") · \(extra[regulatory] as? String ?? "未知型号")")
    }

    static func restore(from backup: URL) -> (Bool, String) {
        guard backup.deletingLastPathComponent().standardizedFileURL == backupDirectory.standardizedFileURL,
              backup.lastPathComponent.hasPrefix("MobileGestalt-"), backup.pathExtension == "plist" else {
            return (false, "备份路径无效，未恢复")
        }
        do {
            let original = try Data(contentsOf: backup)
            guard let root = try PropertyListSerialization.propertyList(from: original, format: nil) as? [String: Any],
                  root["CacheExtra"] is [String: Any] else { return (false, "备份 plist 无效，未恢复") }
            let signedGroups = YumEditSigningGroups() ?? []
            guard let group = signedGroups.first(where: {
                FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: $0) != nil
            }) else { return (false, "当前签名没有可用 App Group，无法恢复") }
            let handle = worse_query(dir, group, false, false)
            guard handle >= 0 else { return (false, "无法访问 MobileGestalt（错误码：\(handle)）") }
            defer { worse_query_release(handle) }
            let target = URL(fileURLWithPath: dir).appendingPathComponent("com.apple.MobileGestalt.plist")
            let current = try Data(contentsOf: target)
            if current == original { return (true, "当前缓存已与所选备份一致，无需恢复。") }
            let safety = backupDirectory.appendingPathComponent("PreRestore-\(UUID().uuidString).plist")
            try current.write(to: safety, options: .atomic)
            guard try Data(contentsOf: safety) == current else { return (false, "恢复前安全备份校验失败，未写入") }
            do {
                try overwriteInPlace(original, at: target)
                guard try Data(contentsOf: target) == original else { throw WriteError.verify }
            } catch {
                do {
                    try overwriteInPlace(current, at: target)
                    guard try Data(contentsOf: target) == current else { throw WriteError.restore }
                    return (false, "恢复失败，已重新写回并校验操作前缓存：\(error.localizedDescription)")
                } catch {
                    return (false, "严重错误：恢复失败且无法校验操作前缓存。请勿重启，使用 GestaltBackups 手动恢复。")
                }
            }
            return (true, "已原位恢复 \(backup.lastPathComponent) 并校验。操作前缓存另存为 \(safety.lastPathComponent)。请重启设备。")
        } catch {
            return (false, "恢复失败：\(error.localizedDescription)")
        }
    }

    enum EditorMutation: Sendable {
        case remove, string(String), integer(Int), boolean(Bool), data(Data)
        var value: Any? {
            switch self {
            case .remove: nil
            case .string(let s): s
            case .integer(let n): n
            case .boolean(let b): b
            case .data(let d): d
            }
        }
    }
    struct EditorField: Identifiable, Sendable {
        let key: String
        let type: String
        let value: String
        var id: String { key }
    }
    static func readFields() throws -> [EditorField] {
        let handle = try accessHandle()
        defer { worse_query_release(handle) }
        let root = try readRoot()
        guard let extra = root["CacheExtra"] as? [String: Any] else { throw WriteError.verify }
        return extra.keys.sorted().map { key in
            let value = extra[key]!
            if let s = value as? String { return EditorField(key: key, type: "String", value: s) }
            if let n = value as? NSNumber {
                let bool = CFGetTypeID(n) == CFBooleanGetTypeID()
                return EditorField(key: key, type: bool ? "Boolean" : "Integer", value: bool ? (n.boolValue ? "true" : "false") : n.stringValue)
            }
            if let d = value as? Data { return EditorField(key: key, type: "Data", value: d.base64EncodedString()) }
            return EditorField(key: key, type: "Collection", value: String(describing: value))
        }
    }
    static func edit(_ changes: [String: EditorMutation]) -> (Bool, String) {
        mutate { extra in
            var result = extra
            for (key, change) in changes {
                guard !key.isEmpty, key.count <= 100 else { throw WriteError.verify }
                result[key] = change.value
            }
            return result
        }
    }
    static func applyIsland() -> (Bool, String) {
        guard hasSmallNotch else { return (false, "当前机型没有此实验预设") }
        return applyIsland(subtype: 2622)
    }
    static func applyIsland(subtype: Int) -> (Bool, String) {
        guard deviceIdentifier().hasPrefix("iPhone"), [2556, 2796, 2976, 2622, 2868, 2736].contains(subtype) else {
            return (false, "当前设备或灵动岛布局值不受支持")
        }
        return mutate { extra in
            var result = extra
            var art = result["oPeik/9e8lQWMszEjbPzng"] as? [String: Any] ?? [:]
            art["ArtworkDeviceSubType"] = subtype // BQTool's known layout values; 18 Pro's own value is unverified.
            result["oPeik/9e8lQWMszEjbPzng"] = art
            result["YlEtTtHlNesRBMal1CqRaA"] = true
            return result
        }
    }
    private static func accessHandle() throws -> Int64 {
        let groups = YumEditSigningGroups() ?? []
        guard let group = groups.first(where: { FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: $0) != nil }) else { throw AccessError.noGroup }
        let handle = worse_query(dir, group, false, false)
        guard handle >= 0 else { throw AccessError.exploit(handle) }
        return handle
    }
    private static func readRoot() throws -> [String: Any] {
        let url = URL(fileURLWithPath: dir).appendingPathComponent("com.apple.MobileGestalt.plist")
        guard let root = try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil) as? [String: Any] else { throw WriteError.verify }
        return root
    }
    private enum AccessError: LocalizedError {
        case noGroup, exploit(Int64)
        var errorDescription: String? {
            switch self {
            case .noGroup: YumLocalization.text("签名没有可用 App Group")
            case .exploit(let code): YumLocalization.text("无法访问 MobileGestalt（错误码：\(code)）")
            }
        }
    }
    private static func mutate(_ transform: ([String: Any]) throws -> [String: Any]) -> (Bool, String) {
        mutateRoot { root in
            var result = root
            guard let extra = root["CacheExtra"] as? [String: Any] else { throw WriteError.verify }
            result["CacheExtra"] = try transform(extra)
            return result
        }
    }
    static func applyIPadOSMode() -> (Bool, String) {
        guard deviceIdentifier().hasPrefix("iPhone") else { return (false, "iPadOS 模式仅用于 iPhone 实验") }
        return mutateRoot { root in
            guard let cacheData = root["CacheData"] as? Data,
                  var extra = root["CacheExtra"] as? [String: Any] else { throw WriteError.verify }
            var result = root
            result["CacheData"] = try patchIPadOSCacheData(cacheData)
            for key in ["mG0AnH/Vy1veoqoLRAIgTA", "UCG5MkVahJxG1YULbbd5Bg", "ZYqko/XM5zD3XBfN5RmaXA", "nVh/gwNpy7Jv1NOk00CMrw", "uKc7FPnEO++lVhHWHFlGbQ"] {
                extra[key] = 1
            }
            result["CacheExtra"] = extra
            return result
        }
    }
    private static let iPadOSModeKeys = ["mG0AnH/Vy1veoqoLRAIgTA", "UCG5MkVahJxG1YULbbd5Bg", "ZYqko/XM5zD3XBfN5RmaXA", "nVh/gwNpy7Jv1NOk00CMrw", "uKc7FPnEO++lVhHWHFlGbQ"]
    private static let externalStageManagerKey = "qeaj75wk3HF4DwQ8qbIi7g"
    private static let externalIPadAppsKey = "9MZ5AdH43csAUajl/dU+IQ"
    private static var externalDisplayBaselineURL: URL {
        backupDirectory.appendingPathComponent("ExternalDisplayBaseline-\(deviceIdentifier()).plist")
    }
    static var hasExternalDisplayBaseline: Bool {
        FileManager.default.fileExists(atPath: externalDisplayBaselineURL.path)
    }
    private static func externalDisplayCandidateValues() -> [String: Any] {
        var values: [String: Any] = [
            externalStageManagerKey: 1,
            externalIPadAppsKey: [1, 2]
        ]
        for key in iPadOSModeKeys { values[key] = 1 }
        return values
    }
    private static func externalDisplayEligible() -> Bool {
        deviceIdentifier().hasPrefix("iPhone") && ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 27
    }
    static func applyExternalDisplayCandidate() -> (Bool, String) {
        guard externalDisplayEligible() else { return (false, "外接屏实验仅支持 iOS 27 及以上的 iPhone") }
        let outcome = mutateRoot { root in
            guard var extra = root["CacheExtra"] as? [String: Any], root["CacheData"] is Data else { throw WriteError.verify }
            try FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
            let baseline = externalDisplayBaselineURL
            if !FileManager.default.fileExists(atPath: baseline.path) {
                let bytes = try PropertyListSerialization.data(fromPropertyList: root, format: .binary, options: 0)
                try bytes.write(to: baseline, options: .atomic)
                guard try Data(contentsOf: baseline) == bytes else { throw WriteError.verify }
            }
            for (key, value) in externalDisplayCandidateValues() { extra[key] = value }
            var result = root
            result["CacheExtra"] = extra
            return result
        }
        return outcome.0
            ? (true, "候选字段已写入并校验。重启后连接外接屏测试；目前没有证明扩展桌面已启用。原始状态另存为 ExternalDisplayBaseline。")
            : outcome
    }
    static func applyExternalDisplayDeviceClass() -> (Bool, String) {
        guard externalDisplayEligible() else { return (false, "外接屏实验仅支持 iOS 27 及以上的 iPhone") }
        guard hasExternalDisplayBaseline else { return (false, "请先执行候选字段阶段，保存实验前基线") }
        let outcome = mutateRoot { root in
            guard let data = root["CacheData"] as? Data,
                  let extra = root["CacheExtra"] as? [String: Any] else { throw WriteError.verify }
            for (key, value) in externalDisplayCandidateValues() {
                guard propertyListValuesEqual(extra[key], value) else { throw ExternalDisplayError.candidateChanged }
            }
            var result = root
            result["CacheData"] = try patchIPadOSCacheData(data)
            return result
        }
        return outcome.0
            ? (true, "iPadOS 设备类别已写入并校验。重启后测试外接屏与音频、麦克风、电话和相机；扩展桌面不保证成功。")
            : outcome
    }
    static func restoreExternalDisplayBaseline() -> (Bool, String) {
        guard deviceIdentifier().hasPrefix("iPhone") else { return (false, "外接屏实验恢复仅支持 iPhone") }
        let baselineURL = externalDisplayBaselineURL
        guard let bytes = try? Data(contentsOf: baselineURL),
              let baseline = try? PropertyListSerialization.propertyList(from: bytes, format: nil) as? [String: Any],
              let originalExtra = baseline["CacheExtra"] as? [String: Any],
              let originalData = baseline["CacheData"] as? Data else {
            return (false, "找不到本机外接屏实验基线；请从 GestaltBackups 选择同一设备的完整备份恢复")
        }
        let outcome = mutateRoot { root in
            guard var extra = root["CacheExtra"] as? [String: Any],
                  let currentData = root["CacheData"] as? Data else { throw WriteError.verify }
            let candidate = externalDisplayCandidateValues()
            for (key, value) in candidate {
                guard propertyListValuesEqual(extra[key], value) || propertyListValuesEqual(extra[key], originalExtra[key]) else {
                    throw ExternalDisplayError.candidateChanged
                }
            }
            if currentData != originalData {
                guard let patched = try? patchIPadOSCacheData(originalData), currentData == patched else {
                    throw ExternalDisplayError.cacheChanged
                }
            }
            for key in candidate.keys { extra[key] = originalExtra[key] }
            var result = root
            result["CacheExtra"] = extra
            result["CacheData"] = originalData
            return result
        }
        if outcome.0 {
            try? FileManager.default.removeItem(at: baselineURL)
            return (true, "已恢复外接屏实验前的相关字段与设备类别，并保留其他当前修改。请重启设备。")
        }
        return outcome
    }
    private static func propertyListValuesEqual(_ lhs: Any?, _ rhs: Any?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil): return true
        case (let a?, let b?): return NSDictionary(dictionary: ["value": a]).isEqual(to: ["value": b])
        default: return false
        }
    }
    private enum ExternalDisplayError: LocalizedError {
        case candidateChanged, cacheChanged
        var errorDescription: String? {
            switch self {
            case .candidateChanged: "外接屏实验字段已被其他操作改动；为避免覆盖，已拒绝写入或恢复"
            case .cacheChanged: "CacheData 与实验前基线不匹配；已拒绝覆盖，请使用完整备份检查"
            }
        }
    }
    static func disableIPadOSMode() -> (Bool, String) {
        guard deviceIdentifier().hasPrefix("iPhone") else { return (false, "iPadOS 模式恢复仅用于 iPhone") }
        return mutateRoot { root in
            guard let currentData = root["CacheData"] as? Data,
                  var currentExtra = root["CacheExtra"] as? [String: Any] else { throw WriteError.verify }
            guard FileManager.default.fileExists(atPath: backupDirectory.path) else { throw PatchError.originalBackup }
            let files = try FileManager.default.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles)
                .filter { $0.lastPathComponent.hasPrefix("MobileGestalt-") && $0.pathExtension == "plist" }
                .sorted {
                    let a = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                    let b = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                    return a > b
                }
            for file in files {
                guard let bytes = try? Data(contentsOf: file),
                      let backup = try? PropertyListSerialization.propertyList(from: bytes, format: nil) as? [String: Any],
                      let originalData = backup["CacheData"] as? Data,
                      let originalExtra = backup["CacheExtra"] as? [String: Any],
                      originalData != currentData,
                      (try? patchIPadOSCacheData(originalData)) == currentData else { continue }
                for key in iPadOSModeKeys {
                    currentExtra[key] = originalExtra[key]
                }
                var result = root
                result["CacheData"] = originalData
                result["CacheExtra"] = currentExtra
                return result
            }
            throw PatchError.originalBackup
        }
    }
    private static func patchIPadOSCacheData(_ data: Data) throws -> Data {
        let hex = data.map { String(format: "%02x", $0) }.joined()
        guard hex.utf16.count > 1616 else { throw PatchError.marker }
        let ns = hex as NSString
        let slice = ns.substring(with: NSRange(location: 1616, length: min(200, ns.length - 1616)))
        let regex = try NSRegularExpression(pattern: "0+(?:5555)*([0-9a-f]{4})")
        var marker: Int?
        for match in regex.matches(in: slice, range: NSRange(location: 0, length: (slice as NSString).length)) {
            let range = match.range(at: 1)
            guard range.location != NSNotFound else { continue }
            let value = (slice as NSString).substring(with: range)
            if value.filter({ $0 != "0" }).count >= 3 { marker = 1616 + range.location; break }
        }
        guard let marker else { throw PatchError.marker }
        let left = marker - 67, right = marker + 13
        guard left > 0, right < ns.length - 1 else { throw PatchError.marker }
        for p in [left, right] {
            guard ["1", "3"].contains(ns.substring(with: NSRange(location: p, length: 1))),
                  ns.substring(with: NSRange(location: p - 1, length: 1)) == "0",
                  ns.substring(with: NSRange(location: p + 1, length: 1)) == "0" else { throw PatchError.marker }
        }
        let patched = (hex as NSString).replacingCharacters(in: NSRange(location: left, length: 1), with: "3")
        let chars = Array(patched.utf8)
        guard chars.count == data.count * 2 else { throw PatchError.marker }
        var bytes = Data(capacity: data.count)
        for i in stride(from: 0, to: chars.count, by: 2) {
            guard let byte = UInt8(String(decoding: chars[i...i+1], as: UTF8.self), radix: 16) else { throw PatchError.marker }
            bytes.append(byte)
        }
        return bytes
    }
    private enum PatchError: LocalizedError {
        case marker, originalBackup
        var errorDescription: String? {
            switch self {
            case .marker: YumLocalization.text("未找到或无法验证 iPadOS CacheData 标记，未写入")
            case .originalBackup: YumLocalization.text("找不到与当前 iPadOS CacheData 匹配的启用前备份，未写入。请使用同一设备的原始 plist 完整恢复。")
            }
        }
    }
    private static func mutateRoot(_ transform: ([String: Any]) throws -> [String: Any]) -> (Bool, String) {
        do {
            let handle = try accessHandle()
            defer { worse_query_release(handle) }
            let target = URL(fileURLWithPath: dir).appendingPathComponent("com.apple.MobileGestalt.plist")
            let original = try Data(contentsOf: target)
            guard let root = try PropertyListSerialization.propertyList(from: original, format: nil) as? [String: Any] else { throw WriteError.verify }
            let changed = try transform(root)
            let modified = try PropertyListSerialization.data(fromPropertyList: changed, format: .binary, options: 0)
            if modified == original { return (true, "字段没有变化，无需写入") }
            try FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
            let backup = backupDirectory.appendingPathComponent("MobileGestalt-\(UUID().uuidString).plist")
            try original.write(to: backup, options: .atomic)
            guard try Data(contentsOf: backup) == original else { throw WriteError.verify }
            do {
                try overwriteInPlace(modified, at: target)
                guard try Data(contentsOf: target) == modified else { throw WriteError.verify }
            } catch {
                do {
                    try overwriteInPlace(original, at: target)
                    guard try Data(contentsOf: target) == original else { throw WriteError.restore }
                    return (false, "写入失败；已恢复并校验操作前缓存。备份：\(backup.lastPathComponent)。\(error.localizedDescription)")
                } catch {
                    return (false, "严重错误：写入与回滚均未通过校验。请勿重启，使用 \(backup.lastPathComponent) 手动恢复。")
                }
            }
            return (true, "已原位写入并校验。操作前备份：\(backup.lastPathComponent)。请 respring 或重启。")
        } catch { return (false, "操作失败：\(error.localizedDescription)") }
    }

    enum RestoreError: LocalizedError {
        case noBackup, invalidBackup
        var errorDescription: String? {
            self == .noBackup ? YumLocalization.text("没有找到本 App 创建的 MobileGestalt 备份") : YumLocalization.text("最近一次备份不是有效的 MobileGestalt plist")
        }
    }

    private enum SalesError: LocalizedError {
        case unknownModel, invalidSalesModel, unknownSpoof, noOriginalBackup, alreadyReal
        var errorDescription: String? {
            switch self {
            case .unknownModel: YumLocalization.text("未知机型或缺少经核实的美版监管型号，未写入")
            case .invalidSalesModel: YumLocalization.text("销售区域与真实机型的监管型号不匹配，未写入")
            case .unknownSpoof: YumLocalization.text("当前缓存的机型与真实设备不符，且不属于 YumEdit 已知伪装，未写入")
            case .noOriginalBackup: YumLocalization.text("找不到与当前设备匹配的原始身份备份，未写入")
            case .alreadyReal: YumLocalization.text("当前缓存的机型已是真实设备，无需执行历史身份恢复")
            }
        }
    }
    private static func validatedUSModel(machine: String, source: SalesSource, extra: [String: Any]) throws -> String {
        guard let oldCountry = extra[country] as? String,
              let oldRegion = extra[region] as? String,
              let oldModel = extra[regulatory] as? String else { throw SalesError.invalidSalesModel }
        let isUS = oldCountry == "LL" && oldRegion == "LL/A"
        let sourceRegionOK: Bool
        switch source {
        case .china: sourceRegionOK = oldCountry == "CH" && oldRegion == "CH/A"
        case .europe: sourceRegionOK = europeanSalesCodes.contains(oldCountry) && oldRegion == "\(oldCountry)/A"
        }
        guard isUS || sourceRegionOK else { throw SalesError.invalidSalesModel }
        if machine.hasPrefix("iPad") {
            guard let mapping = padModels[machine] else { throw SalesError.unknownModel }
            if isUS && mapping.values.contains(oldModel) { return oldModel }
            switch source {
            case .china:
                guard let us = mapping[oldModel] else { throw SalesError.invalidSalesModel }
                return us
            case .europe:
                guard mapping.values.contains(oldModel) else { throw SalesError.invalidSalesModel }
                return oldModel
            }
        }
        guard let us = products[machine] ?? olderUSModels[machine] else { throw SalesError.unknownModel }
        if isUS && oldModel == us { return us }
        let expected = source == .china ? chinaIPhoneModels[machine] : europeanIPhoneModels[machine]
        guard oldModel == expected else { throw SalesError.invalidSalesModel }
        return us
    }
    private static func historicalIdentity(
        current: [String: Any], machine: String, selectedSource: SalesSource?
    ) throws -> ([String: Any], SalesSource, String) {
        guard let cacheData = current["CacheData"] as? Data,
              let currentUUID = current["CacheUUID"] as? String,
              let expectedBoard = physicalBoards[machine],
              let expectedCPU = physicalCPU(for: machine) else { throw SalesError.noOriginalBackup }
        let currentExtra = current["CacheExtra"] as? [String: Any] ?? [:]
        let profiles = machine.hasPrefix("iPad") ? padSpoofProfiles : spoofProfiles
        guard profiles.contains(where: {
            ($0.product == currentExtra[productKey] as? String ||
             machine == currentExtra[productKey] as? String) &&
            $0.board == currentExtra[boardKey] as? String &&
            $0.cpu == currentExtra[cpuKey] as? String &&
            $0.regulatory == currentExtra[regulatory] as? String
        }) else { throw SalesError.unknownSpoof }
        guard FileManager.default.fileExists(atPath: backupDirectory.path) else { throw SalesError.noOriginalBackup }
        let files = try FileManager.default.contentsOfDirectory(
            at: backupDirectory, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles)
            .filter { $0.lastPathComponent.hasPrefix("MobileGestalt-") && $0.pathExtension == "plist" }
            .sorted {
                let a = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                let b = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                return a > b
            }
        for file in files {
            guard let bytes = try? Data(contentsOf: file),
                  let backup = try? PropertyListSerialization.propertyList(from: bytes, format: nil) as? [String: Any],
                  backup["CacheData"] as? Data == cacheData,
                  backup["CacheUUID"] as? String == currentUUID,
                  let original = backup["CacheExtra"] as? [String: Any],
                  original[productKey] as? String == machine,
                  original[boardKey] as? String == expectedBoard,
                  original[cpuKey] as? String == expectedCPU else { continue }
            let candidates: [SalesSource] = selectedSource.map { [$0] } ?? [.china, .europe]
            for source in candidates {
                guard let us = try? validatedUSModel(machine: machine, source: source, extra: original) else { continue }
                return (original, source, us)
            }
        }
        throw SalesError.noOriginalBackup
    }

    static func apply(source: SalesSource) -> (Bool, String) {
        applyConfigured(source: source, requireSpoof: false)
    }
    static func restoreAndApplyUS() -> (Bool, String) {
        if olderUSModels[deviceIdentifier()] != nil { return (false, "旧机型请使用两阶段流程") }
        return applyConfigured(source: nil, requireSpoof: true)
    }
    static func beginOlderDownloadStage(profileProduct: String, source: SalesSource) -> (Bool, String) {
        let machine = deviceIdentifier()
        guard olderUSModels[machine] != nil else { return (false, "当前机型不属于旧机型两阶段支持范围") }
        guard ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 27 else {
            return (false, "旧机型两阶段仅适用于 iOS 27 及以上")
        }
        guard let profile = spoofProfiles.first(where: { $0.product == profileProduct }) else {
            return (false, "未知临时伪装机型，未写入")
        }
        let result = mutateRoot { root in
            guard var extra = root["CacheExtra"] as? [String: Any],
                  extra[productKey] as? String == machine,
                  extra[boardKey] as? String == physicalBoards[machine],
                  extra[cpuKey] as? String == physicalCPU(for: machine) else {
                throw SalesError.unknownSpoof
            }
            _ = try validatedUSModel(machine: machine, source: source, extra: extra)
            extra[country] = "LL"
            extra[region] = "LL/A"
            extra[regulatory] = profile.regulatory
            extra[productKey] = profile.product
            extra[boardKey] = profile.board
            extra[cpuKey] = profile.cpu
            extra[siriModeKey] = 2
            var changed = root
            changed["CacheExtra"] = extra
            return changed
        }
        return result.0
            ? (true, "第一阶段已写入并校验。请完整重启，等待资源下载完成；确认后再执行第二阶段。")
            : result
    }

    static func finishOlderDownloadStage() -> (Bool, String) {
        let machine = deviceIdentifier()
        guard olderUSModels[machine] != nil else { return (false, "当前机型不属于旧机型两阶段支持范围") }
        let result = mutateRoot { root in
            guard var extra = root["CacheExtra"] as? [String: Any],
                  let cachedProduct = extra[productKey] as? String,
                  cachedProduct != machine,
                  extra[country] as? String == "LL",
                  extra[region] as? String == "LL/A" else {
                throw SalesError.alreadyReal
            }
            let (originalIdentity, _, _) = try historicalIdentity(
                current: root, machine: machine, selectedSource: nil)
            for key in [productKey, boardKey, cpuKey, regulatory] {
                guard let value = originalIdentity[key] as? String else { throw SalesError.noOriginalBackup }
                extra[key] = value
            }
            // Keep sales region, SiriMode and generative capability exactly as currently cached.
            var changed = root
            changed["CacheExtra"] = extra
            return changed
        }
        return result.0
            ? (true, "第二阶段已恢复真实机型并校验。请完整重启，再测试 Face ID、听写和 Apple Intelligence。")
            : result
    }
    private static func applyConfigured(source: SalesSource?, requireSpoof: Bool) -> (Bool, String) {
        if olderUSModels[deviceIdentifier()] != nil { return (false, "旧机型请使用两阶段流程") }
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
            let cachedProduct = extra[productKey] as? String
            guard let expectedBoard = physicalBoards[machine],
                  let expectedCPU = physicalCPU(for: machine) else { throw SalesError.unknownModel }
            let isSpoofed = cachedProduct != nil && (
                cachedProduct != machine || extra[boardKey] as? String != expectedBoard ||
                extra[cpuKey] as? String != expectedCPU)
            if requireSpoof && !isSpoofed { throw SalesError.alreadyReal }
            let model: String
            if isSpoofed {
                let (originalIdentity, _, recoveredModel) = try historicalIdentity(
                    current: root, machine: machine, selectedSource: source)
                model = recoveredModel
                extra[productKey] = originalIdentity[productKey]
                extra[boardKey] = originalIdentity[boardKey]
                extra[cpuKey] = originalIdentity[cpuKey]
            } else {
                guard cachedProduct == machine else { throw SalesError.invalidSalesModel }
                guard let source else { throw SalesError.alreadyReal }
                model = try validatedUSModel(machine: machine, source: source, extra: extra)
            }
            let alreadyUS = extra[country] as? String == "LL" && extra[region] as? String == "LL/A"
            let alreadyModel = extra[regulatory] as? String == model
            if !isSpoofed && alreadyUS && alreadyModel {
                return (true, YumLocalization.text("已是目标值。请完整重启设备后检查 Apple Intelligence。"))
            }
            let backups = backupDirectory
            try FileManager.default.createDirectory(at: backups, withIntermediateDirectories: true)
            let backup = backups.appendingPathComponent("MobileGestalt-\(UUID().uuidString).plist")
            try original.write(to: backup, options: .atomic)
            guard try Data(contentsOf: backup) == original else { return (false, "备份校验失败，未写入") }
            extra[country] = "LL"
            extra[region] = "LL/A"
            extra[regulatory] = model
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
                guard verify?[productKey] as? String == machine else { throw WriteError.verify }
                guard verify?[boardKey] as? String == expectedBoard,
                      verify?[cpuKey] as? String == expectedCPU else { throw WriteError.verify }
            } catch {
                do {
                    try overwriteInPlace(original, at: target)
                    guard try Data(contentsOf: target) == original else { throw WriteError.restore }
                    return (false, "写入失败：\(error.localizedDescription)。已恢复并校验原始文件；备份位于 GestaltBackups。")
                } catch {
                    return (false, "严重错误：写入后恢复未能校验。请勿重启，使用 GestaltBackups 中的备份恢复。\(error.localizedDescription)")
                }
            }
            return (true, YumLocalization.text(isSpoofed
                ? "旧版伪装身份已恢复；销售地区和 SiriMode 已写入。请完整重启设备。"
                : "已写入 LL、LL/A、\(model) 并读回校验。请完整重启设备后检查 Apple Intelligence；缓存写入不代表系统功能已启用。备份在“文件”App 的 GestaltBackups。"))
        } catch {
            return (false, YumLocalization.text("操作失败：\(error.localizedDescription)。请检查 GestaltBackups。"))
        }
    }

    static func restoreRealHardwareIdentity() -> (Bool, String) {
        let machine = deviceIdentifier()
        guard machine.hasPrefix("iPhone") || machine.hasPrefix("iPad") else {
            return (false, "仅支持 iPhone 与 iPad 的硬件身份恢复")
        }
        let productKey = "h9jDsbgj7xIVeIQ8S3/X3Q"
        let boardKey = "oYicEKzVTz4/CxxE05pEgQ"
        let cpuKey = "5pYKlGnYYBzGvAlIU8RjEQ"
        let outcome = mutateRoot { root in
            guard var extra = root["CacheExtra"] as? [String: Any],
                  let currentData = root["CacheData"] as? Data,
                  let currentProduct = extra[productKey] as? String,
                  let currentBoard = extra[boardKey] as? String,
                  let currentCPU = extra[cpuKey] as? String,
                  let currentModel = extra[regulatory] as? String else { throw IdentityRestoreError.invalidCache }
            guard currentProduct != machine else { throw IdentityRestoreError.alreadyOriginal }
            let profiles = machine.hasPrefix("iPad") ? padSpoofProfiles : spoofProfiles
            guard profiles.contains(where: {
                $0.product == currentProduct && $0.board == currentBoard &&
                $0.cpu == currentCPU && $0.regulatory == currentModel
            }) else { throw IdentityRestoreError.unknownSpoof }
            guard FileManager.default.fileExists(atPath: backupDirectory.path) else { throw IdentityRestoreError.noBackup }
            let files = try FileManager.default.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles)
                .filter { $0.lastPathComponent.hasPrefix("MobileGestalt-") && $0.pathExtension == "plist" }
                .sorted {
                    let a = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                    let b = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                    return a > b
                }
            for file in files {
                guard let bytes = try? Data(contentsOf: file),
                      let backup = try? PropertyListSerialization.propertyList(from: bytes, format: nil) as? [String: Any],
                      let originalData = backup["CacheData"] as? Data,
                      originalData == currentData,
                      let original = backup["CacheExtra"] as? [String: Any],
                      original[productKey] as? String == machine,
                      let board = original[boardKey] as? String, !board.isEmpty,
                      let cpu = original[cpuKey] as? String, !cpu.isEmpty,
                      let model = original[regulatory] as? String, !model.isEmpty else { continue }
                extra[productKey] = machine
                extra[boardKey] = board
                extra[cpuKey] = cpu
                extra[regulatory] = model
                var result = root
                result["CacheExtra"] = extra
                return result
            }
            throw IdentityRestoreError.noBackup
        }
        return outcome.0
            ? (true, "已从历史备份恢复真实硬件身份，保留当前区域、AI 能力与 SiriMode，并读回校验。请重启后检查 Face ID 与 Siri AI；两者是否可同时使用仍未经验证。")
            : outcome
    }

    private static var siriModeBaselineURL: URL {
        backupDirectory.appendingPathComponent("SiriModeBaseline-\(deviceIdentifier()).plist")
    }
    static func applySiriModeOnly() -> (Bool, String) {
        let machine = deviceIdentifier()
        let family = Int(machine.dropFirst(6).prefix(while: { $0.isNumber })) ?? 0
        guard machine.hasPrefix("iPhone"), (12...17).contains(family), products[machine] == nil,
              ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 27 else {
            return (false, "仅支持 iOS 27 及以上的非原生 Siri AI iPhone")
        }
        let outcome = mutateRoot { root in
            guard var extra = root["CacheExtra"] as? [String: Any] else { throw WriteError.verify }
            try FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
            let baseline = siriModeBaselineURL
            if !FileManager.default.fileExists(atPath: baseline.path) {
                let bytes = try PropertyListSerialization.data(fromPropertyList: root, format: .binary, options: 0)
                try bytes.write(to: baseline, options: .atomic)
                guard try Data(contentsOf: baseline) == bytes else { throw WriteError.verify }
            }
            extra[siriModeKey] = 2
            var result = root
            result["CacheExtra"] = extra
            return result
        }
        return outcome.0
            ? (true, "已在 CacheExtra 新增或设置 SiriMode=2，并读回校验；未伪装机型。重启后检查 Siri AI、听写和 Face ID。文件可读不代表系统采用此值。")
            : outcome
    }
    static func restoreSiriModeOnly() -> (Bool, String) {
        let baselineURL = siriModeBaselineURL
        guard let data = try? Data(contentsOf: baselineURL),
              let baseline = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let original = baseline["CacheExtra"] as? [String: Any],
              let originalData = baseline["CacheData"] as? Data else {
            return (false, "找不到本机 SiriMode 实验基线，未写入")
        }
        let outcome = mutateRoot { root in
            guard var extra = root["CacheExtra"] as? [String: Any],
                  let currentData = root["CacheData"] as? Data,
                  currentData == originalData,
                  extra[siriModeKey] as? Int == 2 else { throw WriteError.verify }
            extra[siriModeKey] = original[siriModeKey]
            var result = root
            result["CacheExtra"] = extra
            return result
        }
        if outcome.0 { try? FileManager.default.removeItem(at: baselineURL) }
        return outcome.0
            ? (true, "已恢复 SiriMode 实验前的原值，其他字段未改动。请重启设备。")
            : outcome
    }

    private enum IdentityRestoreError: LocalizedError {
        case invalidCache, alreadyOriginal, unknownSpoof, noBackup
        var errorDescription: String? {
            switch self {
            case .invalidCache: "当前硬件身份字段不完整，未写入"
            case .alreadyOriginal: "产品型号已是真实机型，无需恢复"
            case .unknownSpoof: "当前身份与 YumEdit 已知伪装配置不一致，未写入"
            case .noBackup: "找不到同设备且 CacheData 一致的伪装前备份，未写入"
            }
        }
    }

    private enum WriteError: LocalizedError {
        case verify, restore
        var errorDescription: String? { self == .verify ? YumLocalization.text("写后校验失败") : YumLocalization.text("恢复后校验失败") }
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
