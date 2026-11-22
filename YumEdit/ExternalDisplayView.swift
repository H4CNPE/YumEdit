import SwiftUI

struct ExternalDisplayView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var status = "尚未写入"
    @State private var busy = false
    @State private var showCandidateRisk = false
    @State private var showDeviceClassRisk = false
    @State private var showRestoreRisk = false

    private enum Operation: Sendable { case candidate, deviceClass, restore }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(YumLocalization.text(status))
                        .foregroundStyle(.secondary)
                    Text("扩展桌面效果需重启后在真机验证。")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                Section("第一阶段 · 候选字段") {
                    Text("写入多任务、台前调度和 iPad App 能力；设备类别保持不变。")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button("写入候选字段") { TapSound.play(.warning); showCandidateRisk = true }
                        .disabled(busy)
                }

                Section("第二阶段 · 设备类别") {
                    Text("更改系统设备类别；已有 iPhone 因此失去音频、通话或相机视频。")
                        .font(.footnote).foregroundStyle(.red)
                    Button("试验 iPadOS 设备类别", role: .destructive) {
                        TapSound.play(.warning)
                        showDeviceClassRisk = true
                    }
                    .disabled(busy || !RegionWriter.hasExternalDisplayBaseline)
                }

                Section("恢复实验前状态") {
                    Text("仅恢复本实验修改的字段和设备类别。需要匹配的实验前基准。")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button("恢复外接屏实验前状态", role: .destructive) {
                        TapSound.play(.warning)
                        showRestoreRisk = true
                    }
                    .disabled(busy || !RegionWriter.hasExternalDisplayBaseline)
                }

                Section("验证步骤") {
                    Text("每阶段重启后，连接键盘、指针和 AirPlay 显示器，检查独立桌面及音频、通话、相机。")
                        .font(.footnote).foregroundStyle(.secondary)
                    Text("音频失效时不要继续第二阶段；先恢复并重启。")
                        .font(.footnote).foregroundStyle(.red)
                }
            }
            .navigationTitle("外接屏扩展实验")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("完成") { TapSound.play(); dismiss() } } }
        }
        .fullScreenCover(isPresented: $showCandidateRisk) {
            RiskScreen(title: "高风险：外接屏候选字段", detail: "将备份并写入七个能力字段。可能影响多任务，且不保证扩展桌面可用。", action: "确认写入候选字段") {
                showCandidateRisk = false
                run(.candidate)
            } cancel: { showCandidateRisk = false }
        }
        .fullScreenCover(isPresented: $showDeviceClassRisk) {
            RiskScreen(title: "极高风险：iPadOS 设备类别", detail: "将修改 CacheData。已有 iPhone 出现音频、麦克风、通话或相机视频失效，重启不能自动修复。", action: "确认写入设备类别") {
                showDeviceClassRisk = false
                run(.deviceClass)
            } cancel: { showDeviceClassRisk = false }
        }
        .fullScreenCover(isPresented: $showRestoreRisk) {
            RiskScreen(title: "恢复外接屏实验", detail: "仅恢复本实验的字段和设备类别；不匹配实验前基准时拒绝写入。", action: "确认恢复") {
                showRestoreRisk = false
                run(.restore)
            } cancel: { showRestoreRisk = false }
        }
    }

    private func run(_ operation: Operation) {
        busy = true
        switch operation {
        case .restore: status = "正在恢复…"
        default: status = "正在备份并写入…"
        }
        Task.detached {
            let result: (Bool, String)
            switch operation {
            case .candidate: result = RegionWriter.applyExternalDisplayCandidate()
            case .deviceClass: result = RegionWriter.applyExternalDisplayDeviceClass()
            case .restore: result = RegionWriter.restoreExternalDisplayBaseline()
            }
            await MainActor.run {
                busy = false
                status = result.1
                TapSound.play(result.0 ? .success : .failure)
            }
        }
    }
}
