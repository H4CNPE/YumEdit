import SwiftUI

struct ExternalDisplayView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var status = "先保存整机备份，再按顺序试验。"
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
                    Text("当前只能验证 MobileGestalt 写入，不能检测系统是否真的启用了扩展桌面。")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                Section("第一阶段 · 候选字段") {
                    Text("写入 iPad 多任务能力、台前调度和 iPad App 能力，不改变设备类别。实测资料表明这种组合可能仍只会镜像。")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button("写入候选字段") { TapSound.play(.warning); showCandidateRisk = true }
                        .disabled(busy)
                }

                Section("第二阶段 · 设备类别") {
                    Text("仅在第一阶段无效、且你愿意承担风险时尝试。会将系统级设备类别改为 iPad；已有 iPhone 因此失去音频、麦克风、通话和相机视频。")
                        .font(.footnote).foregroundStyle(.red)
                    Button("试验 iPadOS 设备类别", role: .destructive) {
                        TapSound.play(.warning)
                        showDeviceClassRisk = true
                    }
                    .disabled(busy || !RegionWriter.hasExternalDisplayBaseline)
                }

                Section("恢复实验前状态") {
                    Text("只恢复本实验涉及的字段与设备类别；其他当前修改会保留。若实验基线丢失，请从 GestaltBackups 选择同一设备的原始 plist。")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button("恢复外接屏实验前状态", role: .destructive) {
                        TapSound.play(.warning)
                        showRestoreRisk = true
                    }
                    .disabled(busy || !RegionWriter.hasExternalDisplayBaseline)
                }

                Section("验证步骤") {
                    Text("每阶段写入后重启。连接蓝牙键盘与实体指针设备，再连接 AirPlay 显示器；观察是否出现独立桌面，而非手机画面镜像。最后检查声音、麦克风、电话和相机视频。")
                        .font(.footnote).foregroundStyle(.secondary)
                    Text("有问题时先恢复实验前状态并重启。不要在音频失效时继续第二阶段。")
                        .font(.footnote).foregroundStyle(.red)
                }
            }
            .navigationTitle("外接屏扩展实验")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("完成") { TapSound.play(); dismiss() } } }
        }
        .fullScreenCover(isPresented: $showCandidateRisk) {
            RiskScreen(title: "高风险：外接屏候选字段", detail: "将备份并写入七个 MobileGestalt 能力字段。可能影响多任务与系统稳定性，且不能保证扩展桌面可用。", action: "我了解风险，写入候选字段") {
                showCandidateRisk = false
                run(.candidate)
            } cancel: { showCandidateRisk = false }
        }
        .fullScreenCover(isPresented: $showDeviceClassRisk) {
            RiskScreen(title: "极高风险：iPadOS 设备类别", detail: "将修改二进制 CacheData 中的设备类别。已有 iPhone 实测出现音频、麦克风、电话、相机视频失效；重启不会自动修复。只有恢复原始字段并再次重启才能尝试排除。", action: "我承担风险，写入设备类别") {
                showDeviceClassRisk = false
                run(.deviceClass)
            } cancel: { showDeviceClassRisk = false }
        }
        .fullScreenCover(isPresented: $showRestoreRisk) {
            RiskScreen(title: "恢复外接屏实验", detail: "只回退本实验的七个能力字段及设备类别。若相关字段已被其他工具改动，YumEdit 会拒绝覆盖。当前缓存仍会先另存备份。", action: "恢复实验前状态") {
                showRestoreRisk = false
                run(.restore)
            } cancel: { showRestoreRisk = false }
        }
    }

    private func run(_ operation: Operation) {
        busy = true
        status = "正在备份并写入 MobileGestalt…"
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
