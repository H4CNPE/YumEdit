import SwiftUI
import UniformTypeIdentifiers

struct OriginalIdentityView: View {
    @State private var product = ""
    @State private var board = ""
    @State private var cpu = ""
    @State private var regulatory = ""
    @State private var country = ""
    @State private var source = "未设置"
    @State private var status = "导入原版 plist 或填写原始参数。"
    @State private var showingImporter = false
    @State private var confirmingManual = false
    @State private var confirmingClear = false

    var body: some View {
        Form {
                Section("当前基准") {
                    LabeledContent("物理机型", value: RegionWriter.physicalIdentifier)
                    LabeledContent("基准来源", value: source)
                    Text(YumLocalization.text(status))
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("原版 plist") {
                    Button("导入原版 plist") { TapSound.play(); showingImporter = true }
                    Text("仅同机完整缓存可用于恢复；指纹不符时只保存供核对。")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("手动参数") {
                    TextField("ProductType，例如 iPhone13,2", text: $product)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    TextField("主板型号，例如 D53gAP", text: $board)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    TextField("芯片型号，例如 t8101", text: $cpu)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    TextField("监管型号，例如 A2404", text: $regulatory)
                        .textInputAutocapitalization(.characters).autocorrectionDisabled()
                    TextField("原销售地区，例如 CH", text: $country)
                        .textInputAutocapitalization(.characters).autocorrectionDisabled()
                    Text("保存后仅更改 YumEdit 的校验基准，不写入系统缓存。")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button("保存基准") { TapSound.play(.warning); confirmingManual = true }
                }
                if source != "未设置" {
                    Section {
                        Button("移除基准", role: .destructive) { TapSound.play(.warning); confirmingClear = true }
                    }
                }
        }
        .navigationTitle("校验基准")
        .onAppear(perform: reload)
            .fileImporter(isPresented: $showingImporter,
                          allowedContentTypes: [UTType(filenameExtension: "plist") ?? .data]) { result in
                switch result {
                case .success(let url):
                    let scoped = url.startAccessingSecurityScopedResource()
                    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                    do {
                        status = try RegionWriter.importOriginalIdentity(from: url)
                        reloadFields()
                        TapSound.play(.success)
                    } catch {
                        status = "导入失败：\(error.localizedDescription)"
                        TapSound.play(.failure)
                    }
                case .failure(let error):
                    status = "无法选择文件：\(error.localizedDescription)"
                }
            }
            .confirmationDialog("保存手填原始身份？", isPresented: $confirmingManual) {
                Button("保存校验基准") { TapSound.play(.confirm); saveManual() }
            } message: {
                Text("手填参数由你提供，YumEdit 无法独立证明其真实性。错误参数可能导致后续恢复写入错误。")
            }
            .confirmationDialog("移除自定义校验基准？", isPresented: $confirmingClear) {
                Button("移除", role: .destructive) {
                    TapSound.play(.confirm)
                    do {
                        try RegionWriter.clearOriginalIdentity()
                        source = "未设置"
                        status = "已移除自定义基准，将使用内置机型表及历史备份校验。"
                    } catch {
                        status = "移除失败：\(error.localizedDescription)"
                    }
                }
            }
    }

    private func reload() {
        product = RegionWriter.physicalIdentifier
        reloadFields()
    }

    private func reloadFields() {
        guard let settings = RegionWriter.originalIdentitySettings() else {
            source = "未设置"
            return
        }
        product = settings.product
        board = settings.board
        cpu = settings.cpu
        regulatory = settings.regulatory
        country = settings.country
        source = settings.source
    }

    private func saveManual() {
        do {
            status = try RegionWriter.saveOriginalIdentity(
                product: product, board: board, cpu: cpu,
                regulatoryModel: regulatory, countryCode: country)
            reloadFields()
            TapSound.play(.success)
        } catch {
            status = "保存失败：\(error.localizedDescription)"
            TapSound.play(.failure)
        }
    }
}
