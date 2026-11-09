import SwiftUI
import WebKit

struct RiskScreen: View {
    let title: String
    let detail: String
    let action: String
    let confirm: () -> Void
    let cancel: () -> Void

    var body: some View {
        ZStack {
            Color(red: 0.34, green: 0.02, blue: 0.04).ignoresSafeArea()
            VStack(spacing: 22) {
                Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 70))
                Text(title).font(.largeTitle.bold()).multilineTextAlignment(.center)
                Text(detail).multilineTextAlignment(.center)
                Button(action) { TapSound.play(.confirm); confirm() }
                    .font(.headline).padding(18).frame(maxWidth: .infinity)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.red)
                Button("取消") { TapSound.play(); cancel() }.foregroundStyle(.white)
            }
            .foregroundStyle(.white).padding(28).frame(maxWidth: 600)
        }
    }
}

struct GestaltEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var fields: [RegionWriter.EditorField] = []
    @State private var filter = ""
    @State private var key = ""
    @State private var value = ""
    @State private var valueType = "String"
    @State private var pending: [String: RegionWriter.EditorMutation] = [:]
    @State private var status = "读取中…"
    @State private var busy = false
    @State private var showWriteRisk = false
    @State private var showRespringRisk = false
    @State private var respringActive = false
    private let types = ["String", "Integer", "Boolean", "Data"]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(status).font(.footnote).foregroundStyle(.secondary)
                    Text("只编辑 CacheExtra。集合类型只读。修改先暂存，确认后才写入系统缓存。")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("字段（\(fields.count)）") {
                    ForEach(fields.filter { filter.isEmpty || $0.key.localizedCaseInsensitiveContains(filter) }) { field in
                        Button {
                            TapSound.play()
                            key = field.key
                            value = field.value
                            valueType = field.type
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(field.key).font(.system(.caption, design: .monospaced)).foregroundStyle(.primary)
                                Text("\(field.type) · \(field.value.prefix(80))").font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                            }
                        }
                    }
                }
                Section("编辑 / 新增") {
                    TextField("CacheExtra 键", text: $key).font(.system(.body, design: .monospaced))
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    Picker("类型", selection: $valueType) {
                        ForEach(types, id: \.self) { Text($0).tag($0) }
                    }
                    TextField(valueType == "Data" ? "Base64 数据" : "值", text: $value, axis: .vertical)
                        .font(.system(.body, design: .monospaced))
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    Button("暂存修改") {
                        guard let mutation = parsedMutation() else { status = "字段值格式无效，未暂存"; return }
                        pending[key] = mutation
                        TapSound.play()
                        status = "已暂存 \(pending.count) 项；尚未写入设备"
                    }
                    .disabled(key.isEmpty || valueType == "Collection")
                    Button("暂存删除", role: .destructive) {
                        guard fields.contains(where: { $0.key == key }) else { return }
                        pending[key] = .remove
                        TapSound.play()
                        status = "已暂存 \(pending.count) 项；尚未写入设备"
                    }
                    .disabled(!fields.contains(where: { $0.key == key }))
                    Button("清空输入") { key = ""; value = ""; valueType = "String" }
                }
                Section("操作") {
                    Button("应用暂存字段（\(pending.count)）") { TapSound.play(.warning); showWriteRisk = true }
                        .disabled(pending.isEmpty || busy)
                    Button("Respring（重启 SpringBoard）") { TapSound.play(.warning); showRespringRisk = true }
                }
            }
            .searchable(text: $filter, prompt: "搜索字段键")
            .navigationTitle("MobileGestalt")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("完成") { dismiss() } } }
        }
        .task { load() }
        .fullScreenCover(isPresented: $showWriteRisk) {
            RiskScreen(title: "高风险：直接改字段", detail: "将写入 \(pending.count) 个 CacheExtra 字段。错误的键、类型或值可能导致功能失效、循环重启或需要恢复设备。写入前会保存完整 plist，失败时尝试回滚。", action: "我了解风险，应用字段") {
                showWriteRisk = false
                apply()
            } cancel: { showWriteRisk = false }
        }
        .fullScreenCover(isPresented: $showRespringRisk) {
            RiskScreen(title: "高风险：Respring", detail: "参考 BQTool 的 NeoSpring 方式触发 SpringBoard 重启。所有打开的 App 会关闭，未保存内容可能丢失；此方式在不同 iPadOS / iOS 版本上不保证成功。", action: "我了解风险，Respring") {
                showRespringRisk = false
                respringActive = true
            } cancel: { showRespringRisk = false }
        }
        .fullScreenCover(isPresented: $respringActive) { NeoSpringView() }
    }

    private func parsedMutation() -> RegionWriter.EditorMutation? {
        switch valueType {
        case "String": .string(value)
        case "Integer": Int(value).map { .integer($0) }
        case "Boolean": value.lowercased() == "true" ? .boolean(true) : (value.lowercased() == "false" ? .boolean(false) : nil)
        case "Data": Data(base64Encoded: value).map { .data($0) }
        default: nil
        }
    }
    private func load() {
        Task.detached {
            let result = Result { try RegionWriter.readFields() }
            await MainActor.run {
                switch result {
                case .success(let items): fields = items; status = "已读取 \(items.count) 个字段"
                case .failure(let error): status = "读取失败：\(error.localizedDescription)"
                }
            }
        }
    }
    private func apply() {
        busy = true
        let changes = pending
        Task.detached {
            let result = RegionWriter.edit(changes)
            await MainActor.run {
                busy = false
                status = result.1
                TapSound.play(result.0 ? .success : .failure)
                if result.0 { pending.removeAll(); load() }
            }
        }
    }
}

private struct NeoSpringView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            NeoSpringWebView().ignoresSafeArea()
            ProgressView("正在尝试 Respring…").tint(.white).foregroundStyle(.white)
        }
    }
}
private struct NeoSpringWebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView()
        if let url = Bundle.main.url(forResource: "respring", withExtension: "html") {
            view.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return view
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
