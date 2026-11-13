import SwiftUI

struct ExperimentalSpoofView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedID = "iPhone16,1:A2848"
    @State private var countryCode = "LL"
    @State private var busy = false
    @State private var showRisk = false
    @State private var status = "仅对已核实的机型、板号、CPU 与监管型号组合写入。"

    private var target: RegionWriter.SpoofProfile? {
        RegionWriter.experimentalTargets.first { $0.id == selectedID }
    }
    private var regulatory: String? {
        target.flatMap { RegionWriter.experimentalRegulatory($0, countryCode: countryCode.uppercased()) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(YumLocalization.text(status)).font(.footnote).foregroundStyle(.secondary)
                    Text("此功能会完整伪装机型身份，可能影响 Face ID、听写、通信和系统稳定性。写入前会备份完整 plist。")
                        .font(.footnote).foregroundStyle(.red)
                }
                Section("目标机型") {
                    Picker("机型", selection: $selectedID) {
                        ForEach(RegionWriter.experimentalTargets) { target in
                            Text("\(DeviceNames.labeled(target.product)) · \(target.regulatory)").tag(target.id)
                        }
                    }
                    .onChange(of: selectedID) { _, _ in TapSound.play(.confirm) }
                    TextField("销售地区代码，例如 LL / CH / JP", text: $countryCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    if let target {
                        Text("ProductType: \(target.product) · Board: \(target.board) · CPU: \(target.cpu)")
                            .font(.system(.footnote, design: .monospaced))
                        Text("监管型号：\(regulatory ?? "无可靠映射，不可写入")")
                            .font(.footnote)
                            .foregroundStyle(regulatory == nil ? .red : .secondary)
                    }
                }
                Section {
                    Button("写入实验性机型伪装", role: .destructive) {
                        TapSound.play(.warning)
                        showRisk = true
                    }
                    .disabled(busy || regulatory == nil)
                }
            }
            .navigationTitle("完整机型伪装 · 实验性")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("完成") { TapSound.play(); dismiss() } } }
        }
        .fullScreenCover(isPresented: $showRisk) {
            RiskScreen(title: "极高风险：完整机型伪装", detail: "将同时改写 ProductType、板号、CPU、监管型号与销售地区。可能导致 Face ID、听写、通信或启动异常。已知型号才允许写入；操作前保存完整备份。", action: "我了解风险，继续写入") {
                showRisk = false
                apply()
            } cancel: { showRisk = false }
        }
    }

    private func apply() {
        busy = true
        let selected = selectedID
        let code = countryCode
        Task.detached {
            let result = RegionWriter.applyExperimentalSpoof(targetID: selected, countryCode: code)
            await MainActor.run {
                busy = false
                status = result.1
                TapSound.play(result.0 ? .success : .failure)
            }
        }
    }
}
