import Foundation

enum StoryLanguage: String, Codable, CaseIterable {
    case system, chinese, english
    func resolved(preferredLanguages: [String] = Locale.preferredLanguages) -> StoryLanguage {
        guard self == .system else { return self }
        return preferredLanguages.first?.lowercased().hasPrefix("zh") == true ? .chinese : .english
    }
    var locale: Locale { Locale(identifier: resolved() == .chinese ? "zh-Hans" : "en") }
    var title: String {
        switch self {
        case .system: return "跟随系统"
        case .chinese: return "简体中文"
        case .english: return "English"
        }
    }
}
struct StoryLocalizer {
    let language: StoryLanguage
    private var interfaceBundle: Bundle {
        guard let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
              let bundle = Bundle(path: path) else { return .main }
        return bundle
    }
    func callAsFunction(_ source: String) -> String {
        guard language.resolved() == .english else { return source }
        return StoryContent.translations[source] ?? interfaceBundle.localizedString(forKey: source, value: source, table: nil)
    }
    func callAsFunction(_ chinese: String, _ english: String) -> String {
        language.resolved() == .english ? english : chinese
    }
}
#if canImport(SwiftUI)
import SwiftUI
private struct StoryLanguageKey: EnvironmentKey {
    static let defaultValue: StoryLanguage = .system
}
extension EnvironmentValues {
    var storyLanguage: StoryLanguage {
        get { self[StoryLanguageKey.self] }
        set { self[StoryLanguageKey.self] = newValue }
    }
}
#endif

// Pagination preserves every character. It only splits at a word boundary when possible.
// 分页保留全部字符，尽量在单词边界处分隔。
enum StoryPages {
    static func split(_ text: String, limit: Int) -> [String] {
        precondition(limit > 0)
        var remainder = text[...]
        var pages: [String] = []
        while remainder.count > limit {
            var end = remainder.index(remainder.startIndex, offsetBy: limit)
            if let space = remainder[..<end].lastIndex(where: { $0.isWhitespace }) {
                end = remainder.index(after: space)
            }
            pages.append(String(remainder[..<end]))
            remainder = remainder[end...]
        }
        if !remainder.isEmpty || pages.isEmpty { pages.append(String(remainder)) }
        return pages
    }
}
