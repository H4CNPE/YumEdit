import SwiftUI

struct ExperimentsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("experimentStrategy") private var experimentStrategy = 0
    @State private var showExternalRisk = false
    @State private var showExternal = false
    @State private var showSpoofRisk = false
    @State private var showSpoof = false

    var body: some View {
        NavigationStack {
            List {
                Section("听写与 Siri AI 音色实验") {
                    Picker("实验策略", selection: $experimentStrategy) {
                        Text("未选择").tag(0)
                        ForEach(RegionWriter.ExperimentStrategy.allCases) { strategy in
                            Text(YumLocalization.text(strategy.title)).tag(strategy.rawValue)
                        }
                    }
                    .onChange(of: experimentStrategy) { _, _ in TapSound.play(.confirm) }
                    Text("仅决定下次伪装的字段范围；恢复采用本次操作记录的策略。系统效果待真机验证。")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section {
                    Button("完整机型伪装", role: .destructive) {
                        TapSound.play(.warning); showSpoofRisk = true
                    }
                }
                Section {
                    NavigationLink("校验基准") { OriginalIdentityView() }
                        .simultaneousGesture(TapGesture().onEnded { TapSound.play() })
                }
                Section {
                    Button("外接屏扩展实验") { TapSound.play(.warning); showExternalRisk = true }
                }
            }
            .navigationTitle("高级选项")
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
