import SwiftUI

struct AboutView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    private let contributors: [(name: String, handle: String, avatar: String, note: String?)] = [
        ("Murkuwuwuwu", "Murkuwuwuwu", "Avatar-murkuwuwu", "本工具使用的漏洞贡献者"),
        ("HYumPiX", "HYumPiX", "Avatar-HYumPiX", nil),
        ("DawnToDusk_", "DawnToDusk_", "Avatar-DawnToDusk_", nil)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("贡献者").font(.title2.bold())
                    ForEach(contributors, id: \.handle) { person in
                        Button {
                            TapSound.play(.confirm)
                            openURL(URL(string: "https://x.com/\(person.handle)")!)
                        } label: {
                            HStack(spacing: 12) {
                                Image(person.avatar).resizable().scaledToFill()
                                    .frame(width: 48, height: 48).clipShape(Circle())
                                VStack(alignment: .leading) {
                                    Text(person.name).font(.headline)
                                    Text("@\(person.handle) · X").font(.caption).foregroundStyle(.secondary)
                                    if let note = person.note {
                                        Text(YumLocalization.text(note)).font(.caption2.weight(.semibold)).foregroundStyle(.cyan)
                                    }
                                }
                                Spacer()
                                Image(systemName: "arrow.up.right").foregroundStyle(.secondary)
                            }
                            .padding(10).background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                    }
                    Text("GitHub 仓库").font(.headline).padding(.top, 4)
                    Button {
                        TapSound.play(.confirm)
                        openURL(URL(string: "https://github.com/H4CNPE/YumEdit")!)
                    } label: {
                        Label("H4CNPE / YumEdit", systemImage: "chevron.left.forwardslash.chevron.right")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14).background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "未知"
                    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "未知"
                    Text(YumLocalization.text("版本 \(version) · 构建 \(build)"))
                        .font(.footnote).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
                .padding(20)
            }
            .navigationTitle("关于 YumEdit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) {
                Button("完成") { TapSound.play(); dismiss() }
            }}
        }
        .preferredColorScheme(.dark)
    }
}
