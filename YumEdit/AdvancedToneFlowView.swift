import SwiftUI

struct AdvancedToneFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedID = "iPhone18,1:A3256"
    @State private var status = "系统效果待真机验证。"
    @State private var busy = false
    @State private var confirmSpoof = false
    @State private var confirmRestore = false

    private var targets: [RegionWriter.SpoofProfile] {
        RegionWriter.spoofProfiles.filter { ["iPhone18,1", "iPhone18,2"].contains($0.product) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(YumLocalization.text(status)).font(.footnote).foregroundStyle(.secondary)
                }
                Section("第一阶段：临时伪装") {
                    Picker("目标机型", selection: $selectedID) {
                        ForEach(targets) { target in
                            Text("\(target.name) · \(target.product)").tag(target.id)
                        }
                    }
                    .onChange(of: selectedID) { _, _ in TapSound.play(.confirm) }
                    Button("写入临时伪装", role: .destructive) { TapSound.play(.warning); confirmSpoof = true }
                        .disabled(busy || RegionWriter.selectedExperimentStrategy == nil)
                }
                Section("第二阶段：按记录恢复") {
                    Button("按本次策略恢复", role: .destructive) { TapSound.play(.warning); confirmRestore = true }
                        .disabled(busy)
                }
            }
            .navigationTitle("高级 Siri AI 音色实验")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("完成") { TapSound.play(); dismiss() } } }
        }
        .confirmationDialog("写入临时伪装？", isPresented: $confirmSpoof) {
            Button("写入", role: .destructive) { TapSound.play(.confirm); runSpoof() }
        } message: { Text("将备份原始缓存并按所选策略写入。可能影响 Face ID 和听写。") }
        .confirmationDialog("按本次记录恢复？", isPresented: $confirmRestore) {
            Button("恢复", role: .destructive) { TapSound.play(.confirm); runRestore() }
        } message: { Text("仅在本次伪装的字段和缓存指纹匹配时恢复。") }
    }

    private func runSpoof() {
        busy = true
        let target = selectedID
        Task.detached {
            let result = RegionWriter.applyExperimentalSpoof(targetID: target, countryCode: "LL")
            await MainActor.run {
                busy = false; status = result.1
                TapSound.play(result.0 ? .success : .failure)
            }
        }
    }
    private func runRestore() {
        busy = true
        Task.detached {
            let result = RegionWriter.restoreExperiment()
            await MainActor.run {
                busy = false; status = result.1
                TapSound.play(result.0 ? .success : .failure)
            }
        }
    }
}
