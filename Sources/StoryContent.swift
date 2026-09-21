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
    private struct Catalog: Decodable {
        let storyIDs: [String]
        let legacyIDs: [String]
    }
    // Both targets bundle the same Stories directory; content is read locally once.
    // App和Widget打包同一份Stories目录，内容只在本地加载一次。
    private static let root: URL = {
        #if os(macOS)
        if let path = ProcessInfo.processInfo.environment["TINYSTORY_CONTENT_DIRECTORY"] {
            return URL(fileURLWithPath: path)
        }
        #endif
        guard let url = Bundle.main.url(forResource: "Stories", withExtension: nil) else {
            preconditionFailure("Missing bundled Stories directory")
        }
        return url
    }()
    private static func load<T: Decodable>(_ name: String, as type: T.Type = T.self) -> T {
        do {
            return try JSONDecoder().decode(type, from: Data(contentsOf: root.appendingPathComponent(name)))
        } catch {
            preconditionFailure("Invalid bundled story resource \(name): \(error)")
        }
    }
    private static let catalog: Catalog = load("catalog.json")
    static let current: [StoryDocument] = documents(catalog.storyIDs, edition: 2)
    static let legacy: [StoryDocument] = documents(catalog.legacyIDs, edition: 1)

    private static func documents(_ ids: [String], edition: Int) -> [StoryDocument] {
        precondition(Set(ids).count == ids.count, "Duplicate story IDs")
        return ids.map { id in
            let document: StoryDocument = load((edition == 1 ? "Legacy/" : "") + id + ".json")
            precondition(document.id == id && document.edition == edition, "Story identity mismatch")
            let nodeIDs = Set(document.nodes.map(\.id))
            precondition(nodeIDs.count == document.nodes.count && nodeIDs.contains("start"), "Invalid node IDs")
            precondition(document.texts.allSatisfy { !$0.chinese.isEmpty && !$0.english.isEmpty }, "Missing translation")
            for node in document.nodes {
                precondition(node.options.map(\.id) == (node.endingTitle == nil ? ["A", "B"] : []), "Invalid options")
                precondition(node.options.allSatisfy { nodeIDs.contains($0.next) }, "Missing destination")
            }
            return document
        }
    }

    // Historical journeys store original prose; keep a fallback for those snapshots.
    // 历史旅程保存的是当时的正文，保留旧译文供这些快照回放使用。
    static let translations: [String: String] = {
        var result: [String: String] = load("Legacy/snapshot-translations.json")
        for document in legacy + current {
            for text in document.texts { result[text.chinese] = text.english }
        }
        return result
    }()
}
