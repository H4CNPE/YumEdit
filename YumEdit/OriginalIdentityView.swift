import SwiftUI
import UniformTypeIdentifiers

struct OriginalIdentityView: View {
    @State private var product = ""
    @State private var board = ""
    @State private var cpu = ""
    @State private var regulatory = ""
    @State private var country = ""
    @State private var source = "未设置"
    @State private var status = "导入改机前的原版 MobileGestalt plist，或手动填写原始机型参数。"
    @State private var showingImporter = false
    @State private var confirmingManual = false
    @State private var confirmingClear = false

    var body: some View {
        Group {
                Section("校验基准") {
                    LabeledContent("物理机型", value: RegionWriter.physicalIdentifier)
                    LabeledContent("基准来源", value: source)
                    Text(YumLocalization.text(status))
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("导入原版文件") {
                    Button("选择 MobileGestalt plist") { showingImporter = true }
                    Text("文件必须包含同一设备的 CacheExtra、CacheUUID 和 CacheData。指纹不匹配时仅保存供核对，不用于恢复写入。")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("手动修改原始参数") {
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
                    Text("区域将按销售地区生成，例如 CH/A。手填参数会参与 YumEdit 的原始身份校验，不会立即改写系统缓存。")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button("保存为原始身份校验基准") { confirmingManual = true }
                }
                if source != "未设置" {
                    Section {
                        Button("移除自定义校验基准", role: .destructive) { confirmingClear = true }
                    }
                }
        }
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
                Button("保存校验基准") { saveManual() }
            } message: {
                Text("手填参数由你提供，YumEdit 无法独立证明其真实性。错误参数可能导致后续恢复写入错误。")
            }
            .confirmationDialog("移除自定义校验基准？", isPresented: $confirmingClear) {
                Button("移除", role: .destructive) {
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
