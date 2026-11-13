import SwiftUI

struct ExperimentsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var status = "实验结果需要在真机重启后验证。"
    @State private var busy = false
    @State private var showExternalRisk = false
    @State private var showExternal = false
    @State private var showSpoofRisk = false
    @State private var showSpoof = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(YumLocalization.text(status)).font(.footnote).foregroundStyle(.secondary)
                    Text("以下功能未经当前设备验证；写入成功不代表系统会启用功能。")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("完整机型伪装") {
                    Text("选择目标机型与销售地区，自动填写已核实的板号、CPU 和监管型号。未知组合拒绝写入。")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button("进入完整机型伪装", role: .destructive) {
                        TapSound.play(.warning); showSpoofRisk = true
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
        .fullScreenCover(isPresented: $showSpoofRisk) {
            RiskScreen(title: "极高风险：完整机型伪装", detail: "此功能同时修改产品、板号、CPU、监管型号和销售地区，可能导致 Face ID、听写、通信或启动异常。请先备份整机。", action: "我了解风险，进入机型伪装") {
                showSpoofRisk = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showSpoof = true }
            } cancel: { showSpoofRisk = false }
        }
        .fullScreenCover(isPresented: $showExternalRisk) {
            RiskScreen(title: "高风险：外接屏实验", detail: "此实验可能更改 iPadOS 设备类别，已有机型出现音频、麦克风、电话及相机视频失效。请先完成整机备份；扩展桌面尚未得到验证。", action: "我了解风险，进入外接屏实验") {
                showExternalRisk = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showExternal = true }
            } cancel: { showExternalRisk = false }
        }
        .sheet(isPresented: $showExternal) { ExternalDisplayView() }
        .sheet(isPresented: $showSpoof) { ExperimentalSpoofView() }
    }
}
