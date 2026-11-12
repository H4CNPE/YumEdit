import SwiftUI

struct ExperimentsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var status = "实验结果需要在真机重启后验证。"
    @State private var busy = false
    @State private var showExternalRisk = false
    @State private var showExternal = false
    @State private var showIdentityRisk = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(YumLocalization.text(status)).font(.footnote).foregroundStyle(.secondary)
                    Text("以下功能未经当前设备验证；写入成功不代表系统会启用功能。")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("还原回对应机型并修改美版") {
                    Text("从同设备历史备份恢复真实产品、板号与 CPU，并按已核实型号映射写入美版区域和监管型号。未知型号或找不到匹配备份时拒绝写入。请先备份整机。")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button("还原回对应机型并修改美版", role: .destructive) {
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
        .fullScreenCover(isPresented: $showIdentityRisk) {
            RiskScreen(title: "高风险：恢复真实硬件身份", detail: "从同设备历史备份恢复真实产品、板号与 CPU，并按已核实型号映射写入美版区域和监管型号。未知型号或找不到匹配备份时拒绝写入。请先备份整机。", action: "我了解风险，恢复硬件身份") {
                showIdentityRisk = false; runRestoreAndApply()
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

    private func runRestoreAndApply() {
        busy = true
        status = "正在备份并写入 MobileGestalt…"
        Task.detached {
            let result = RegionWriter.restoreAndApplyUS()
            await MainActor.run {
                busy = false
                status = result.1
                TapSound.play(result.0 ? .success : .failure)
            }
        }
    }
}
