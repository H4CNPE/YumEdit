import SwiftUI

private struct GestaltPreset: Identifiable {
    let id: String
    let title: String
    let note: String
    let keys: [String]
    let value: Bool
    let advanced: Bool
    static let all: [GestaltPreset] = [
        .init(id: "aod", title: "全天候显示", note: "Always-On Display", keys: ["2OOJf1VhaM7NxfRok3HbWQ", "j8/Omm6s1lsmTDFsXjsBfA"], value: true, advanced: false),
        .init(id: "aodVibrancy", title: "AOD 色彩", note: "AOD Vibrancy", keys: ["ykpu7qyhqFweVMKtxNylWA"], value: true, advanced: false),
        .init(id: "bootChime", title: "开机提示音", note: "Boot Chime", keys: ["QHxt+hGLaBPbQJbXiUJX3w"], value: true, advanced: false),
        .init(id: "charge80", title: "80% 充电上限", note: "80% Charge Limit", keys: ["37NVydb//GP/GrhuTN+exg"], value: true, advanced: false),
        .init(id: "tapWake", title: "轻点唤醒", note: "Tap to Wake", keys: ["yZf3GTRMGTuwSV/lD7Cagw"], value: true, advanced: false),
        .init(id: "stageManager", title: "台前调度", note: "Stage Manager", keys: ["qeaj75wk3HF4DwQ8qbIi7g"], value: true, advanced: false),
        .init(id: "pencil", title: "Apple Pencil", note: "Apple Pencil", keys: ["yhHcB0iH0d1XzPO/CFd3ow"], value: true, advanced: false),
        .init(id: "actionButton", title: "操作按钮", note: "Action Button", keys: ["cT44WE1EohiwRzhsZ8xEsw"], value: true, advanced: false),
        .init(id: "collisionSOS", title: "车祸检测 SOS", note: "Collision SOS", keys: ["HCzWusHQwZDea6nNhaKndw"], value: true, advanced: false),
        .init(id: "parallax", title: "关闭视差效果", note: "Disable Parallax", keys: ["UIParallaxCapability"], value: false, advanced: false),
        .init(id: "ai", title: "Apple Intelligence", note: "设备能力标记", keys: ["A62OafQ85EJAiiqKn4agtg"], value: true, advanced: true),
        .init(id: "research", title: "安全研究设备", note: "ResearchFuse", keys: ["XYlJKKkj2hztRP1NWWnhlw"], value: true, advanced: true),
        .init(id: "demo", title: "商店展示模式", note: "Store Demo Mode", keys: ["aadL+4GFBDe6DdsUD2HGGw"], value: true, advanced: true)
    ]
}

struct PresetsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var fields: [RegionWriter.EditorField] = []
    @State private var states: [String: Bool] = [:]
    @State private var pending: [String: RegionWriter.EditorMutation] = [:]
    @State private var version = ""
    @State private var build = ""
    @State private var subtype = 2622
    @State private var status = "读取中…"
    @State private var busy = false
    @State private var showApplyRisk = false
    @State private var showIslandRisk = false
    @State private var showIPadOSRisk = false
    @State private var showDisableIPadOSRisk = false
    @State private var showExternalDisplayRisk = false
    @State private var showExternalDisplay = false
    @State private var showRespringRisk = false
    @State private var respringActive = false
    private let islandOptions = [
        ("14 / 15 Pro · 2556", 2556), ("14 Pro Max · 2796", 2796),
        ("15 Pro Max / 17 · 2976", 2976), ("16 / 17 Pro · 2622", 2622),
        ("16 / 17 Pro Max · 2868", 2868), ("Air · 2736", 2736)
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(YumLocalization.text(status)).font(.footnote).foregroundStyle(.secondary)
                    Text("预设来自 BQTool 的公开字段表。开关只暂存变更，点击应用后才写入。关闭预设会移除对应键；若需回到精确原值，请用 plist 备份恢复。")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("常用预设") {
                    ForEach(GestaltPreset.all.filter { !$0.advanced }) { preset in presetRow(preset) }
                }
                Section("设备与 AI · 高风险") {
                    ForEach(GestaltPreset.all.filter { $0.advanced }) { preset in presetRow(preset) }
                    Button("暂存 Siri AI 美区字段") {
                        pending["A62OafQ85EJAiiqKn4agtg"] = .boolean(true)
                        pending["h63QSdBCiT/z0WU6rdQv6Q"] = .string("LL")
                        pending["yK+xavymRGZ3xWc1tb8XDg"] = .string("LL/A")
                        status = "已暂存 Siri AI 美区字段；尚未写入"
                        TapSound.play(.warning)
                    }
                    Text("国行设备的监管型号仍需按主页面的机型适配流程处理。")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("系统版本伪装 · 高风险") {
                    TextField("版本，例如 27.2", text: $version).textInputAutocapitalization(.never)
                    TextField("构建号，例如 24B115", text: $build).textInputAutocapitalization(.never)
                    Button("暂存版本伪装") {
                        guard !version.isEmpty, !build.isEmpty else { status = "版本与构建号都必须填写"; return }
                        pending["qNNddlUK+B/YlooNoymwgA"] = .string(version)
                        pending["mZfUC7qo4pURNhyMHZ62RQ"] = .string(build)
                        pending["ToLFRidm+eJGWnpw6W4Wwg"] = .string(version)
                        pending["P5Go9WVVA604m7rKhbVndw"] = .remove
                        status = "已暂存版本伪装；尚未写入"
                        TapSound.play(.warning)
                    }
                    Button("暂存清除版本伪装", role: .destructive) {
                        for key in ["qNNddlUK+B/YlooNoymwgA", "mZfUC7qo4pURNhyMHZ62RQ", "ToLFRidm+eJGWnpw6W4Wwg", "P5Go9WVVA604m7rKhbVndw"] { pending[key] = .remove }
                        status = "已暂存清除版本字段；尚未写入"
                        TapSound.play(.warning)
                    }
                }
                if !RegionWriter.isPad {
                    Section("灵动岛布局 · 高风险") {
                        Picker("设备布局", selection: $subtype) {
                            ForEach(islandOptions, id: \.1) { option in Text(option.0).tag(option.1) }
                        }
                        .simultaneousGesture(TapGesture().onEnded { TapSound.play() })
                        .onChange(of: subtype) { _, _ in TapSound.play(.confirm) }
                        Button("应用所选灵动岛布局") { TapSound.play(.warning); showIslandRisk = true }
                            .disabled(busy)
                        Text("iPhone 18 Pro 专用值未核实；以上仅为 BQTool 已知布局。")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Section("iPadOS 模式 · 极高风险") {
                        Button("实验：启用 iPadOS 模式") { TapSound.play(.warning); showIPadOSRisk = true }
                            .disabled(busy)
                        Button("关闭 iPadOS 模式", role: .destructive) { TapSound.play(.warning); showDisableIPadOSRisk = true }
                            .disabled(busy)
                        Text("此项目会修改二进制 CacheData，标记校验失败时拒绝写入。请保留完整备份。")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Section("外接屏扩展 · 实验") {
                        Button("进入外接屏实验") { TapSound.play(.warning); showExternalDisplayRisk = true }
                            .disabled(busy)
                        Text("分阶段测试台前调度、iPad 能力和设备类别；尚未在 iOS 27 真机证明扩展桌面可用。")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Section {
                    Button(YumLocalization.text("应用暂存修改（\(pending.count) 个字段）")) { TapSound.play(.warning); showApplyRisk = true }
                        .disabled(pending.isEmpty || busy)
                    Button("Respring（重启 SpringBoard）") { TapSound.play(.warning); showRespringRisk = true }
                        .disabled(busy)
                }
            }
            .navigationTitle("预设修改")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("完成") { TapSound.play(); dismiss() } } }
        }
        .task { load() }
        .fullScreenCover(isPresented: $showApplyRisk) {
            RiskScreen(title: "高风险：应用预设", detail: "将写入 \(pending.count) 个字段。预设可能与设备硬件不匹配，导致功能失效、循环重启或需要恢复设备。写入前会备份完整 plist。", action: "我了解风险，应用修改") {
                showApplyRisk = false
                apply()
            } cancel: { showApplyRisk = false }
        }
        .fullScreenCover(isPresented: $showIslandRisk) {
            RiskScreen(title: "高风险：灵动岛布局", detail: "将设置 BQTool 的布局值 \(subtype) 并启用 Dynamic Island。错误布局可能遮挡状态栏或影响系统功能。", action: "我了解风险，应用布局") {
                showIslandRisk = false
                applyIsland()
            } cancel: { showIslandRisk = false }
        }
        .fullScreenCover(isPresented: $showIPadOSRisk) {
            RiskScreen(title: "极高风险：iPadOS 模式", detail: "参考 BQTool 修改 MobileGestalt 的二进制 CacheData 和五个能力字段。可能破坏系统界面、Face ID 或导致循环重启。仅在完整备份并准备好恢复设备时使用。", action: "我了解风险，启用 iPadOS 模式") {
                showIPadOSRisk = false
                applyIPadOS()
            } cancel: { showIPadOSRisk = false }
        }
        .fullScreenCover(isPresented: $showDisableIPadOSRisk) {
            RiskScreen(title: "高风险：关闭 iPadOS 模式", detail: "只从匹配的启用前备份恢复 iPadOS CacheData 与五个能力字段；其他当前修改会保留。找不到匹配备份时会拒绝写入。请先完成整机备份。", action: "我了解风险，关闭 iPadOS 模式") {
                showDisableIPadOSRisk = false
                disableIPadOS()
            } cancel: { showDisableIPadOSRisk = false }
        }
        .fullScreenCover(isPresented: $showExternalDisplayRisk) {
            RiskScreen(title: "高风险：外接屏实验", detail: "本实验可能更改 iPadOS 设备类别，已有机型出现音频、麦克风、电话及相机视频失效。请先完成整机备份，并准备好用原始 plist 恢复。此功能尚未证明能在 iOS 27 启用扩展桌面。", action: "我了解风险，进入实验") {
                showExternalDisplayRisk = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showExternalDisplay = true }
            } cancel: { showExternalDisplayRisk = false }
        }
        .fullScreenCover(isPresented: $showRespringRisk) {
            RiskScreen(title: "高风险：Respring", detail: "参考 BQTool 的 NeoSpring 方式触发 SpringBoard 重启。所有打开的 App 会关闭，未保存内容可能丢失；此方式在不同 iPadOS / iOS 版本上不保证成功。", action: "我了解风险，Respring") {
                showRespringRisk = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { respringActive = true }
            } cancel: { showRespringRisk = false }
        }
        .fullScreenCover(isPresented: $respringActive) { NeoSpringView() }
        .sheet(isPresented: $showExternalDisplay) { ExternalDisplayView() }
    }

    private func presetRow(_ preset: GestaltPreset) -> some View {
        Toggle(isOn: Binding(get: { states[preset.id] ?? false }, set: { on in
            TapSound.play(on ? .confirm : .tap)
            states[preset.id] = on
            for key in preset.keys { pending[key] = on ? .boolean(preset.value) : .remove }
            status = "已暂存 \(pending.count) 个字段；尚未写入"
        })) {
            VStack(alignment: .leading, spacing: 3) {
                Text(YumLocalization.text(preset.title))
                Text(YumLocalization.text(preset.note)).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
    private func load() {
        Task.detached {
            let result = Result { try RegionWriter.readFields() }
            await MainActor.run {
                switch result {
                case .success(let items):
                    fields = items
                    states = Dictionary(uniqueKeysWithValues: GestaltPreset.all.map { preset in
                        (preset.id, preset.keys.allSatisfy { key in items.first(where: { $0.key == key })?.value == (preset.value ? "true" : "false") })
                    })
                    version = items.first(where: { $0.key == "qNNddlUK+B/YlooNoymwgA" })?.value ?? ""
                    build = items.first(where: { $0.key == "mZfUC7qo4pURNhyMHZ62RQ" })?.value ?? ""
                    status = "已读取 \(items.count) 个字段"
                case .failure(let error): status = "读取失败：\(error.localizedDescription)"
                }
            }
        }
    }
    private func apply() {
        busy = true
        let changes = pending
        Task.detached {
            let result = RegionWriter.edit(changes)
            await MainActor.run {
                busy = false; status = result.1
                TapSound.play(result.0 ? .success : .failure)
                if result.0 { pending.removeAll() }
            }
        }
    }
    private func applyIsland() {
        busy = true
        let selected = subtype
        Task.detached {
            let result = RegionWriter.applyIsland(subtype: selected)
            await MainActor.run {
                busy = false; status = result.1
                TapSound.play(result.0 ? .success : .failure)
            }
        }
    }
    private func applyIPadOS() {
        busy = true
        Task.detached {
            let result = RegionWriter.applyIPadOSMode()
            await MainActor.run {
                busy = false; status = result.1
                TapSound.play(result.0 ? .success : .failure)
            }
        }
    }
    private func disableIPadOS() {
        busy = true
        Task.detached {
            let result = RegionWriter.disableIPadOSMode()
            await MainActor.run {
                busy = false; status = result.1
                TapSound.play(result.0 ? .success : .failure)
            }
        }
    }
}
