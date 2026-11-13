import SwiftUI

struct OlderDeviceFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProduct = ""
    @State private var spoofEnabled = false
    @State private var confirmedDownloaded = false
    @State private var snapshot: RegionWriter.DeviceSnapshot?
    @State private var status = "确认资源下载完成后，再执行第二阶段。"
    @State private var busy = false
    @State private var showFirstRisk = false
    @State private var showSecondRisk = false
    @State private var showPhotoRisk = false
    @State private var showNoSiriWarning = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let snapshot {
                        Text(YumLocalization.text(snapshot.isSpoofed
                            ? "当前仍是临时伪装机型" : "当前已是真实机型"))
                            .foregroundStyle(snapshot.isSpoofed ? .orange : .green)
                        Text("\(DeviceNames.labeled(snapshot.physicalModel)) → \(DeviceNames.labeled(snapshot.cachedModel))")
                            .font(.system(.footnote, design: .monospaced))
                    }
                    Text(YumLocalization.text(status))
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if snapshot?.photoRepairNeeded == true {
                    Section("检测到扩图字段异常，点击修正") {
                        Text("只修正已存在的两个扩图能力字段；写入前保存完整备份并读回校验。")
                            .font(.footnote).foregroundStyle(.secondary)
                        Button("修正扩图字段", role: .destructive) {
                            TapSound.play(.warning)
                            showPhotoRisk = true
                        }.disabled(busy)
                    }
                }
                if snapshot?.isSpoofed == true || snapshot?.olderAIReady == true {
                    Section {
                        Label("恢复真实机型后，千万不要打开「设置 → Siri」页面", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline).foregroundStyle(.white)
                        Text("打开该页面可能重新检查设备资格，使已下载的 Siri AI 资源失效。请只通过语音测试，勿进入 Siri 设置。")
                            .font(.footnote).foregroundStyle(.white.opacity(0.9))
                    }.listRowBackground(Color.red.opacity(0.75))
                }
                Section("第一阶段：临时伪装并下载资源") {
                    Toggle("临时伪装机型", isOn: $spoofEnabled)
                        .onChange(of: spoofEnabled) { _, _ in TapSound.play(.confirm) }
                    if spoofEnabled {
                        Picker("临时伪装机型", selection: $selectedProduct) {
                            ForEach(RegionWriter.isPad ? RegionWriter.padSpoofProfiles : RegionWriter.spoofProfiles) { profile in
                                Text("\(profile.name) (\(profile.product))").tag(profile.product)
                            }
                        }
                        .onChange(of: selectedProduct) { _, _ in TapSound.play(.confirm) }
                    }
                    Text("写入美区、SiriMode、生成式模型能力与三处 CacheData 槽位。机型伪装可选；开启时仅修改 ProductType，可能影响 Face ID 和听写。写入前自动备份；完整重启后测试资源下载。")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button("第一阶段：临时伪装并下载资源", role: .destructive) {
                        TapSound.play(.warning)
                        showFirstRisk = true
                    }
                    .disabled(busy || snapshot == nil || snapshot?.isSpoofed == true || (snapshot?.olderAIReady == true && !spoofEnabled))
                }
                Section("第二阶段：恢复真实机型") {
                    Text("仅在第一阶段选择机型伪装时使用。从同设备历史备份恢复真实 ProductType，保留美区与能力字段。找不到可信备份就拒绝写入；恢复后完整重启并测试 Face ID 与听写。千万不要进入「设置 → Siri」。")
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
        .task {
            selectedProduct = RegionWriter.isPad ? "iPad16,3" : "iPhone18,5"
            refresh()
        }
        .fullScreenCover(isPresented: $showFirstRisk) {
            RiskScreen(
                title: "高风险：临时伪装机型",
                detail: "写入美区、SiriMode、生成式模型能力与三处 CacheData 槽位。机型伪装可选；开启时仅修改 ProductType，可能影响 Face ID 和听写。写入前自动备份；完整重启后测试资源下载。",
                action: "我了解风险，继续写入"
            ) {
                showFirstRisk = false
                runFirst()
            } cancel: { showFirstRisk = false }
        }
        .fullScreenCover(isPresented: $showSecondRisk) {
            RiskScreen(
                title: "高风险：恢复真实机型",
                detail: "恢复真实机型后，千万不要打开「设置 → Siri」页面。它可能重新检查设备资格，使下载的资源失效。恢复后完整重启，只通过语音测试 Siri。",
                action: "我了解风险，恢复硬件身份"
            ) {
                showSecondRisk = false
                runSecond()
            } cancel: { showSecondRisk = false }
        }
        .fullScreenCover(isPresented: $showPhotoRisk) {
            RiskScreen(title: "高风险：修正扩图字段", detail: "仅当两个字段均存在且值异常时，写入 M1n2sAqf33NAOgZRGxQYBA=true 与 rb2tKZxIjOGm2tBmUQSLqQ=false。操作前自动备份，完成后需重启测试。", action: "我了解风险，继续写入") {
                showPhotoRisk = false
                runPhotoRepair()
            } cancel: { showPhotoRisk = false }
        }
        .fullScreenCover(isPresented: $showNoSiriWarning) {
            ZStack {
                Color(red: 0.46, green: 0.01, blue: 0.03).ignoresSafeArea()
                VStack(spacing: 24) {
                    Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 76))
                    Text("千万不要打开「设置 → Siri」")
                        .font(.largeTitle.bold()).multilineTextAlignment(.center)
                    Text("已恢复真实机型。请完整重启设备。进入 Siri 设置可能触发设备资格重新检查；只通过语音测试 Siri，并检查 Face ID 和听写。")
                        .multilineTextAlignment(.center)
                    Button("我记住了") { TapSound.play(.confirm); showNoSiriWarning = false }
                        .font(.headline).padding(18).frame(maxWidth: .infinity)
                        .background(.white, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.red)
                }
                .foregroundStyle(.white).padding(28)
            }
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
        let shouldSpoof = spoofEnabled
        Task.detached {
            let result = RegionWriter.beginOlderDownloadStage(profileProduct: shouldSpoof ? product : nil)
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
                if result.0 { showNoSiriWarning = true }
                refresh()
            }
        }
    }
    private func runPhotoRepair() {
        busy = true
        Task.detached {
            let result = RegionWriter.repairPhotoCapabilities()
            await MainActor.run {
                busy = false
                status = result.1
                TapSound.play(result.0 ? .success : .failure)
                refresh()
            }
        }
    }
}
