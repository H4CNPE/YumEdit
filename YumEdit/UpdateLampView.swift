import SwiftUI

private struct GitHubRelease: Decodable {
    let tag_name: String
    let prerelease: Bool
    let draft: Bool
}

struct UpdateLampView: View {
    private enum Lamp {
        case red, yellow, green, neutral
        var color: Color {
            switch self {
            case .red: .red
            case .yellow: .yellow
            case .green: .green
            case .neutral: .gray
            }
        }
        var voiceOver: String {
            switch self {
            case .red: "有更新的正式版；打开当前版本介绍"
            case .yellow: "有更新的 Prerelease；打开当前版本介绍"
            case .green: "当前已是最新正式版；打开当前版本介绍"
            case .neutral: "当前为 Prerelease；打开当前版本介绍"
            }
        }
    }
    @State private var lamp: Lamp? = .neutral
    @State private var showNotes = false

    var body: some View {
        Group {
            if let lamp {
                Button { TapSound.play(); showNotes = true } label: {
                    Circle().fill(lamp.color)
                        .frame(width: 17, height: 17)
                        .overlay(Circle().strokeBorder(.white.opacity(0.55), lineWidth: 1.5))
                        .shadow(color: lamp.color.opacity(0.65), radius: 5)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(YumLocalization.text(lamp.voiceOver))
            }
        }
        .task { await check() }
        .sheet(isPresented: $showNotes) { CurrentReleaseNotesView() }
    }

    private func check() async {
        guard let url = URL(string: "https://api.github.com/repos/H4CNPE/YumEdit/releases?per_page=30") else {
            lamp = nil
            return
        }
        do {
            var request = URLRequest(url: url)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("YumEdit/2.0.0", forHTTPHeaderField: "User-Agent")
            request.timeoutInterval = 15
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                lamp = nil
                return
            }
            let releases = try JSONDecoder().decode([GitHubRelease].self, from: data).filter { !$0.draft }
            let current = versionParts(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0")
            let currentPrerelease = Bundle.main.infoDictionary?["YumEditPrerelease"] as? Bool ?? true
            let formal = releases.filter { !$0.prerelease }.map { versionParts($0.tag_name) }.max(by: less)
            let preview = releases.filter(\.prerelease).map { versionParts($0.tag_name) }.max(by: less)
            if let formal, less(current, formal) || (formal == current && currentPrerelease) { lamp = .red }
            else if let preview, less(current, preview) { lamp = .yellow }
            else if formal == current && !currentPrerelease { lamp = .green }
            else { lamp = .neutral }
        } catch {
            lamp = nil
        }
    }

    private func versionParts(_ value: String) -> [Int] {
        value.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
            .split(separator: ".").map { Int($0) ?? 0 }
    }
    private func less(_ lhs: [Int], _ rhs: [Int]) -> Bool {
        for index in 0..<max(lhs.count, rhs.count) {
            let a = index < lhs.count ? lhs[index] : 0
            let b = index < rhs.count ? rhs[index] : 0
            if a != b { return a < b }
        }
        return false
    }
}

struct CurrentReleaseNotesView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section("2.0.0 Prerelease") {
                    Text("四种听写与 Siri AI 音色实验策略；恢复按本次记录执行。")
                    Text("设备状态显示 Audio 机型；高级选项集中管理校验基准。")
                    Text("高级音色与听写效果待真机验证。写入前请备份整机。")
                }
            }
            .navigationTitle("当前版本介绍")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("完成") { dismiss() } } }
        }
    }
}
