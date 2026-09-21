import Foundation

struct StoryText: Decodable {
    let chinese: String
    let english: String
    enum CodingKeys: String, CodingKey { case chinese = "zh-Hans", english = "en" }
}
struct StoryDocument: Decodable {
    struct Option: Decodable {
        let id: String
        let title: StoryText
        let next: String
    }
    struct Node: Decodable {
        let id: String
        let text: StoryText
        let options: [Option]
        let endingTitle: StoryText?
    }
    let id: String
    let edition: Int
    let title: StoryText
    let summary: StoryText
    let nodes: [Node]

    var story: Story {
        Story(id: id, title: title.chinese, summary: summary.chinese, nodes: nodes.map {
            StoryNode(id: $0.id, text: $0.text.chinese,
                      options: $0.options.map { StoryOption(title: $0.title.chinese, next: $0.next) },
                      endingTitle: $0.endingTitle?.chinese)
        })
    }
    var texts: [StoryText] {
        [title, summary] + nodes.flatMap { [$0.text] + $0.options.map(\.title) + [$0.endingTitle].compactMap { $0 } }
    }
}

enum StoryContent {
    struct ContentError: LocalizedError {
        let detail: String
        var errorDescription: String? { detail }
    }
    struct Library {
        let current: [StoryDocument]
        let legacy: [StoryDocument]
        let translations: [String: String]
    }
    private struct Catalog: Decodable {
        let storyIDs: [String]
        let legacyIDs: [String]
    }
    // Cache the result, including failures, without terminating the app.
    // 缓存加载结果；资源异常交给界面提示，不直接终止程序。
    private static let result: Result<Library, Error> = Result {
        #if os(macOS)
        if let path = ProcessInfo.processInfo.environment["TINYSTORY_CONTENT_DIRECTORY"] {
            return try validate(at: URL(fileURLWithPath: path))
        }
        #endif
        guard let root = Bundle.main.url(forResource: "Stories", withExtension: nil) else {
            throw ContentError(detail: "Missing bundled Stories directory")
        }
        return try validate(at: root)
    }
    static var error: Error? {
        if case .failure(let error) = result { return error }
        return nil
    }
    static var current: [StoryDocument] { (try? result.get().current) ?? [] }
    static var legacy: [StoryDocument] { (try? result.get().legacy) ?? [] }
    static var translations: [String: String] { (try? result.get().translations) ?? [:] }
    static func requireAvailable() throws { _ = try result.get() }

    // Used both by the app and the Release build's content validation step.
    // 运行时与Release构建共用这套校验，避免发布含断链、循环或缺译文的故事。
    @discardableResult
    static func validate(at root: URL) throws -> Library {
        func require(_ condition: Bool, _ message: String) throws {
            if !condition { throw ContentError(detail: message) }
        }
        func load<T: Decodable>(_ name: String, as type: T.Type) throws -> T {
            do {
                return try JSONDecoder().decode(type, from: Data(contentsOf: root.appendingPathComponent(name)))
            } catch { throw ContentError(detail: "\(name): \(error.localizedDescription)") }
        }
        let catalog = try load("catalog.json", as: Catalog.self)
        try require(!catalog.storyIDs.isEmpty && catalog.storyIDs.contains("last-letter"), "Missing initial story")
        func documents(_ ids: [String], edition: Int) throws -> [StoryDocument] {
            try require(Set(ids).count == ids.count, "Duplicate story IDs")
            return try ids.map { id in
                try require(!id.isEmpty && !id.contains("/") && !id.contains(".."), "Invalid story ID")
                let path = (edition == 1 ? "Legacy/" : "") + id + ".json"
                let doc = try load(path, as: StoryDocument.self)
                try require(doc.id == id && doc.edition == edition, "\(path): edition or ID mismatch")
                let ids = Set(doc.nodes.map(\.id))
                try require(ids.count == doc.nodes.count && ids.contains("start"), "\(path): invalid node IDs")
                try require(doc.texts.allSatisfy { !$0.chinese.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !$0.english.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }, "\(path): missing translation")
                for node in doc.nodes {
                    try require(node.options.map(\.id) == (node.endingTitle == nil ? ["A", "B"] : []), "\(path): invalid options at \(node.id)")
                    try require(node.options.allSatisfy { ids.contains($0.next) }, "\(path): missing destination at \(node.id)")
                }
                let nodes = Dictionary(uniqueKeysWithValues: doc.nodes.map { ($0.id, $0) })
                var reached = Set<String>()
                func visit(_ id: String, depth: Int, ancestors: Set<String>) throws {
                    try require(!ancestors.contains(id), "\(path): cycle at \(id)")
                    guard let node = nodes[id] else { throw ContentError(detail: "\(path): missing node") }
                    reached.insert(id)
                    if node.endingTitle != nil {
                        try require(depth == 4, "\(path): ending must follow four choices")
                    } else {
                        try require(depth < 4, "\(path): too many choices")
                        for option in node.options { try visit(option.next, depth: depth + 1, ancestors: ancestors.union([id])) }
                    }
                }
                try visit("start", depth: 0, ancestors: [])
                try require(reached == ids, "\(path): unreachable nodes")
                return doc
            }
        }
        let current = try documents(catalog.storyIDs, edition: 2)
        let legacy = try documents(catalog.legacyIDs, edition: 1)
        try require(Set(catalog.legacyIDs).isSubset(of: Set(catalog.storyIDs)), "Legacy story has no current edition")
        // Keep exact historical translations even when current text changes.
        // 保留历史正文的精确译文，不用当前文案覆盖旧快照。
        var translations = try load("Legacy/snapshot-translations.json", as: [String: String].self)
        try require(!translations.isEmpty && translations.allSatisfy { !$0.key.isEmpty && !$0.value.isEmpty }, "Invalid snapshot translations")
        var currentTexts: [String: String] = [:]
        for doc in legacy + current {
            for text in doc.texts {
                if let previous = currentTexts[text.chinese] {
                    try require(previous == text.english, "Conflicting translation in \(doc.id)")
                }
                currentTexts[text.chinese] = text.english
                translations[text.chinese] = text.english
            }
        }
        return Library(current: current, legacy: legacy, translations: translations)
    }
}
