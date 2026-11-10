import Foundation

nonisolated enum YumLocalization {
    private struct Template {
        let source: String
        let expression: NSRegularExpression
        let placeholderIDs: [Int]
    }

    private static let templates: [Template] = {
        let sourceURL = Bundle.main.bundleURL.appendingPathComponent("zh-Hans.lproj/Localizable.strings")
        guard let data = try? Data(contentsOf: sourceURL),
              let strings = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String],
              let placeholder = try? NSRegularExpression(pattern: "__X([0-9]+)__") else { return [] }
        return strings.keys.filter { $0.contains("__X0__") }.compactMap { source in
            let ns = source as NSString
            let matches = placeholder.matches(in: source, range: NSRange(location: 0, length: ns.length))
            var expression = "^"
            var cursor = 0
            var ids: [Int] = []
            for match in matches {
                expression += NSRegularExpression.escapedPattern(for: ns.substring(with: NSRange(location: cursor, length: match.range.location - cursor)))
                expression += "(.*?)"
                ids.append(Int(ns.substring(with: match.range(at: 1))) ?? ids.count)
                cursor = match.range.location + match.range.length
            }
            expression += NSRegularExpression.escapedPattern(for: ns.substring(from: cursor)) + "$"
            guard let regex = try? NSRegularExpression(pattern: expression, options: .dotMatchesLineSeparators) else { return nil }
            return Template(source: source, expression: regex, placeholderIDs: ids)
        }.sorted { $0.source.count > $1.source.count }
    }()

    static func text(_ source: String) -> String {
        let direct = Bundle.main.localizedString(forKey: source, value: source, table: "Localizable")
        if direct != source { return direct }
        let ns = source as NSString
        for template in templates {
            guard let match = template.expression.firstMatch(in: source, range: NSRange(location: 0, length: ns.length)) else { continue }
            var result = Bundle.main.localizedString(forKey: template.source, value: template.source, table: "Localizable")
            for (index, id) in template.placeholderIDs.enumerated() {
                guard match.range(at: index + 1).location != NSNotFound else { continue }
                result = result.replacingOccurrences(of: "__X\(id)__", with: ns.substring(with: match.range(at: index + 1)))
            }
            return result
        }
        return source
    }
}
