import SwiftUI

struct ExperimentsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var status = "实验结果需要在真机重启后验证。"
    @State private var busy = false
    @State private var showExternalRisk = false
    @State private var showExternal = false
    @State private var showSiriRisk = false
    @State private var showSiriRestoreRisk = false
    @State private var showIdentityRisk = false

    private enum Operation: Sendable { case siri, restoreSiri, identity }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(YumLocalization.text(status)).font(.footnote).foregroundStyle(.secondary)
                    Text("以下功能未经当前设备验证；写入成功不代表系统会启用功能。")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("SiriMode 独立实验") {
                    Text("只新增 SiriMode=2，不伪装产品、板号或芯片。用于区分字段缺失与身份伪装的影响；低于 A17 Pro 设备启用 Siri AI 尚无独立复现。")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button("仅新增 SiriMode=2") { TapSound.play(.warning); showSiriRisk = true }
                        .disabled(busy)
                    Button("恢复 SiriMode 实验前值", role: .destructive) {
                        TapSound.play(.warning); showSiriRestoreRisk = true
                    }
                    .disabled(busy)
                }
                Section("Face ID 排障实验") {
                    Text("从历史备份恢复真实产品、板号、芯片与监管型号，保留美区、AI 标记和 SiriMode。可能恢复 Face ID，也可能使 Siri AI 失效。")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button("恢复真实硬件身份", role: .destructive) {
                        TapSound.play(.warning); showIdentityRisk = true
                    }
                    .disabled(busy)
                }
                Section("外接屏扩展实验") {
                    Text("分阶段测试 iPad 多任务能力和设备类别。可能损坏音频、通话或相机视频；扩展桌面尚未得到验证。")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button("进入外接屏实验") { TapSound.play(.warning); showExternalRisk = true }
                        .disabled(busy)
                }
            }
            .navigationTitle("实验性选项")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("完成") { TapSound.play(); dismiss() } } }
        }
        .fullScreenCover(isPresented: $showSiriRisk) {
            RiskScreen(title: "高风险：仅新增 SiriMode", detail: "只在非原生 Siri AI 的 iOS 27 iPhone 上向 CacheExtra 写入 SiriMode=2。保留真实机型。是否被系统采用、能否启用 Siri AI 均未经验证；写入前会备份。", action: "我了解风险，新增字段") {
                showSiriRisk = false; run(.siri)
            } cancel: { showSiriRisk = false }
        }
        .fullScreenCover(isPresented: $showSiriRestoreRisk) {
            RiskScreen(title: "恢复 SiriMode 实验", detail: "只恢复本实验开始前的 SiriMode 原值。若 CacheData 已变化，将拒绝写入；当前缓存会先备份。", action: "恢复原值") {
                showSiriRestoreRisk = false; run(.restoreSiri)
            } cancel: { showSiriRestoreRisk = false }
        }
        .fullScreenCover(isPresented: $showIdentityRisk) {
            RiskScreen(title: "高风险：恢复真实硬件身份", detail: "仅在 AI 模型已下载后尝试。从历史备份寻找同设备、同 CacheData 的伪装前身份，恢复产品、板号、芯片与监管型号；保留美区和 SiriMode。可能恢复 Face ID，也可能令 Siri AI 失效。找不到精确备份就拒绝写入。", action: "我了解风险，恢复硬件身份") {
                showIdentityRisk = false; run(.identity)
            } cancel: { showIdentityRisk = false }
        }
        .fullScreenCover(isPresented: $showExternalRisk) {
            RiskScreen(title: "高风险：外接屏实验", detail: "此实验可能更改 iPadOS 设备类别，已有机型出现音频、麦克风、电话及相机视频失效。请先完成整机备份；扩展桌面尚未得到验证。", action: "我了解风险，进入外接屏实验") {
                showExternalRisk = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showExternal = true }
            } cancel: { showExternalRisk = false }
        }
        .sheet(isPresented: $showExternal) { ExternalDisplayView() }
    }

    private func run(_ operation: Operation) {
        busy = true
        status = "正在备份并写入 MobileGestalt…"
        Task.detached {
            let result: (Bool, String)
            switch operation {
            case .siri: result = RegionWriter.applySiriModeOnly()
            case .restoreSiri: result = RegionWriter.restoreSiriModeOnly()
            case .identity: result = RegionWriter.restoreRealHardwareIdentity()
            }
            await MainActor.run {
                busy = false
                status = result.1
                TapSound.play(result.0 ? .success : .failure)
            }
        }
    }
}
