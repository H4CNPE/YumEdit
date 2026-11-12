import SwiftUI

struct OlderDeviceFlowView: View {
    let source: RegionWriter.SalesSource

    @Environment(\.dismiss) private var dismiss
    @State private var selectedProduct = "iPhone18,5"
    @State private var confirmedDownloaded = false
    @State private var snapshot: RegionWriter.DeviceSnapshot?
    @State private var status = "确认资源下载完成后，再执行第二阶段。"
    @State private var busy = false
    @State private var showFirstRisk = false
    @State private var showSecondRisk = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let snapshot {
                        Text(YumLocalization.text(snapshot.isSpoofed
                            ? "当前仍是临时伪装机型" : "当前已是真实机型"))
                            .foregroundStyle(snapshot.isSpoofed ? .orange : .green)
                        Text("\(snapshot.physicalModel) → \(snapshot.cachedModel)")
                            .font(.system(.footnote, design: .monospaced))
                    }
                    Text(YumLocalization.text(status))
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("第一阶段：临时伪装并下载资源") {
                    Picker("临时伪装机型", selection: $selectedProduct) {
                        ForEach(RegionWriter.spoofProfiles) { profile in
                            Text(profile.name).tag(profile.product)
                        }
                    }
                    .onChange(of: selectedProduct) { _, _ in TapSound.play(.confirm) }
                    Text("第一阶段会临时修改产品、板号、CPU 与监管型号，可能使 Face ID 和听写暂时失效。写入前自动备份；完整重启后等待系统下载资源。不会写入生成式模型能力字段。")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button("第一阶段：临时伪装并下载资源", role: .destructive) {
                        TapSound.play(.warning)
                        showFirstRisk = true
                    }
                    .disabled(busy || snapshot == nil || snapshot?.isSpoofed == true)
                }
                Section("第二阶段：恢复真实机型") {
                    Text("第二阶段从同设备、同 CacheData 与 CacheUUID 的历史备份恢复真实产品、板号、CPU 与原监管型号，同时保留美区和 SiriMode。找不到可信备份就拒绝写入；恢复后需完整重启并测试 Face ID、听写及 Siri AI。不会写入生成式模型能力字段。")
                        .font(.footnote).foregroundStyle(.secondary)
                    Toggle("我确认资源已下载完成", isOn: $confirmedDownloaded)
                        .onChange(of: confirmedDownloaded) { _, _ in TapSound.play(.confirm) }
                    Button("第二阶段：恢复真实机型", role: .destructive) {
                        TapSound.play(.warning)
                        showSecondRisk = true
                    }
                    .disabled(busy || snapshot?.isSpoofed != true || !confirmedDownloaded)
                }
            }
            .navigationTitle(YumLocalization.text("旧机型两阶段") + " · " + YumLocalization.text("实验性选项"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { TapSound.play(); dismiss() }
                }
            }
        }
        .task { refresh() }
        .fullScreenCover(isPresented: $showFirstRisk) {
            RiskScreen(
                title: "高风险：临时伪装机型",
                detail: "第一阶段会临时修改产品、板号、CPU 与监管型号，可能使 Face ID 和听写暂时失效。写入前自动备份；完整重启后等待系统下载资源。不会写入生成式模型能力字段。",
                action: "我了解风险，继续写入"
            ) {
                showFirstRisk = false
                runFirst()
            } cancel: { showFirstRisk = false }
        }
        .fullScreenCover(isPresented: $showSecondRisk) {
            RiskScreen(
                title: "高风险：恢复真实机型",
                detail: "第二阶段从同设备、同 CacheData 与 CacheUUID 的历史备份恢复真实产品、板号、CPU 与原监管型号，同时保留美区和 SiriMode。找不到可信备份就拒绝写入；恢复后需完整重启并测试 Face ID、听写及 Siri AI。不会写入生成式模型能力字段。",
                action: "我了解风险，恢复硬件身份"
            ) {
                showSecondRisk = false
                runSecond()
            } cancel: { showSecondRisk = false }
        }
    }

    private func refresh() {
        Task.detached {
            let result = RegionWriter.readDeviceSnapshot()
            await MainActor.run {
                snapshot = result.0
                if let error = result.1 { status = "读取失败：\(error)" }
            }
        }
    }

    private func runFirst() {
        busy = true
        let product = selectedProduct
        Task.detached {
            let result = RegionWriter.beginOlderDownloadStage(profileProduct: product, source: source)
            await MainActor.run {
                busy = false
                status = result.1
                TapSound.play(result.0 ? .success : .failure)
                refresh()
            }
        }
    }

    private func runSecond() {
        busy = true
        Task.detached {
            let result = RegionWriter.finishOlderDownloadStage()
            await MainActor.run {
                busy = false
                status = result.1
                confirmedDownloaded = false
                TapSound.play(result.0 ? .success : .failure)
                refresh()
            }
        }
    }
}
