import Foundation
import Darwin

struct StoryOption: Codable { let title: String; let next: String }
struct StoryNode: Codable {
    let id: String
    let text: String
    let options: [StoryOption]
    var endingTitle: String? = nil
}
struct Story: Identifiable {
    let id: String
    let title: String
    let summary: String
    let nodes: [StoryNode]
    var start: String { "start" }
    var endingNodes: [StoryNode] { nodes.filter { $0.endingTitle != nil } }
    func node(_ id: String) -> StoryNode? { nodes.first { $0.id == id } }
}

// Stable IDs and editions keep existing saves compatible with resource updates.
// 固定故事ID和内容版本，确保资源迁移后仍能继续已有存档。
enum StoryCatalog {
    static let all: [Story] = StoryContent.current.map(\.story)
    static let legacy: [Story] = StoryContent.legacy.map(\.story)
    static func story(_ id: String, version: Int = 2) -> Story? {
        (version == 1 ? legacy : all).first { $0.id == id }
    }
}

struct JourneyStep: Codable {
    let node: StoryNode
    let choice: String
    let optionTitle: String
}
struct Journey: Codable, Identifiable {
    let id: String
    let storyVersion: Int
    let steps: [JourneyStep]
    let lastNode: StoryNode
    let date: Date
    let reconstructed: Bool
    var completed: Bool { lastNode.endingTitle != nil }
}
struct StoryProgress: Codable {
    var contentVersion: Int? = 2
    var journeyID: String? = UUID().uuidString
    var steps: [JourneyStep]? = []
    var history: [Journey]? = []
    var reconstructed: Bool? = false
    var edition: Int { contentVersion ?? 1 }
    func snapshot(story: Story) -> Journey {
        Journey(id: journeyID ?? run, storyVersion: edition, steps: steps ?? [], lastNode: story.node(nodeID)!, date: updated, reconstructed: reconstructed ?? false)
    }

    var run = UUID().uuidString
    var nodeID = "start"
    var choices: [String] = []
    var endings: [String] = []
    var updated = Date()
}
struct ExploredBranch {
    let node: StoryNode
    let exits: [ExploredExit]
    var visibleIDs: Set<String> { exits.reduce(into: Set([node.id])) { result, exit in if let child = exit.child { result.formUnion(child.visibleIDs) } } }
}
struct ExploredExit {
    let label: String
    let child: ExploredBranch?
}
extension Story {
    func exploredTree(_ progress: StoryProgress) -> ExploredBranch {
        var edges = Set<String>()
        for journey in progress.history ?? [] where journey.storyVersion == progress.edition {
            for step in journey.steps { edges.insert(step.node.id + ":" + step.choice) }
        }
        for step in progress.steps ?? [] { edges.insert(step.node.id + ":" + step.choice) }
        func build(_ id: String, depth: Int) -> ExploredBranch {
            let node = self.node(id)!
            let exits = node.options.enumerated().map { index, option in
                let letter = index == 0 ? "A" : "B"
                return ExploredExit(label: "\(letter) · \(option.title)", child: depth < 4 && edges.contains(id + ":" + letter) ? build(option.next, depth: depth + 1) : nil)
            }
            return ExploredBranch(node: node, exits: exits)
        }
        return build(start, depth: 0)
    }
}
enum NextStoryOrder: String, Codable, CaseIterable {
    case unfinishedFirst, listOrder
    var title: String { self == .unfinishedFirst ? "优先未完成" : "按列表顺序" }
}
struct StoryState: Codable {
    var language: StoryLanguage? = nil
    var widgetPage: Int? = nil
    var languageToken: String { (language ?? .system).rawValue + ":" + (language ?? .system).resolved().rawValue }
    var readingPages: [String] { StoryPages.split(localizer(text), limit: (language ?? .system).resolved() == .english ? 100 : 60) }
    var pageIndex: Int { min(max(widgetPage ?? 0, 0), readingPages.count - 1) }
    var pageText: String { readingPages[pageIndex] }
    var lastPage: Bool { pageIndex == readingPages.count - 1 }
    var localizer: StoryLocalizer { StoryLocalizer(language: language ?? .system) }
    var nextStoryOrder: NextStoryOrder? = nil
    var version = 2
    var activeID = "last-letter"
    var progress: [String: StoryProgress] = [:]
    var story: Story { StoryCatalog.story(activeID, version: current.edition)! }
    var current: StoryProgress { progress[activeID] ?? StoryProgress() }
    var node: StoryNode { story.node(current.nodeID)! }
    var run: String { current.run }
    var step: Int { current.choices.count }
    var finished: Bool { node.endingTitle != nil }
    var ending: String { node.endingTitle ?? "" }
    var text: String { node.text }
    var options: [String] { node.options.map(\.title) }
    mutating func select(_ id: String) {
        if activeID != id { widgetPage = 0 }
        if progress[id] == nil { progress[id] = StoryProgress() }
        if activeID != id { progress[id]!.run = UUID().uuidString }
        activeID = id
    }
}
struct LegacyState: Codable { var run: String; var choices: [String]; var endings: [String]; var updated: Date }
enum StoreError: LocalizedError {
    case invalidData
    var errorDescription: String? { "暂时无法读取故事进度。原有数据已保留，请稍后重试。" }
}
struct StoryStore {
    static let group = "group.com.ducheng.story"
    static func directory() throws -> URL {
        #if os(macOS)
        if let path = ProcessInfo.processInfo.environment["MICROSTORY_TEST_DIRECTORY"] { return URL(fileURLWithPath: path) }
        #endif
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) else { throw CocoaError(.fileNoSuchFile) }
        return url
    }
    static func prepareJourneys(_ state: inout StoryState) {
        for id in Array(state.progress.keys) {
            var p = state.progress[id]!
            guard let story = StoryCatalog.story(id, version: p.edition) else { continue }
            if p.steps == nil {
                var nodeID = story.start
                var steps: [JourneyStep] = []
                for choice in p.choices {
                    guard let node = story.node(nodeID), node.options.count == 2 else { break }
                    let option = node.options[choice == "A" ? 0 : 1]
                    steps.append(JourneyStep(node: node, choice: choice, optionTitle: option.title)); nodeID = option.next
                }
                p.steps = steps; p.reconstructed = true
            }
            if p.journeyID == nil { p.journeyID = UUID().uuidString }
            if p.history == nil { p.history = [] }
            if story.node(p.nodeID)?.endingTitle != nil { archive(&p, story: story) }
            state.progress[id] = p
        }
    }
    static func archive(_ p: inout StoryProgress, story: Story) {
        guard !p.choices.isEmpty else { return }
        let journey = p.snapshot(story: story)
        if !(p.history ?? []).contains(where: { $0.id == journey.id }) { p.history = (p.history ?? []) + [journey] }
    }
    static func freshProgress(_ old: StoryProgress?, id: String) -> StoryProgress {
        var old = old ?? StoryProgress()
        archive(&old, story: StoryCatalog.story(id, version: old.edition)!)
        var fresh = StoryProgress(); fresh.endings = old.endings; fresh.history = old.history
        return fresh
    }
    static func validate(_ state: StoryState) throws {
        guard state.version == 2, StoryCatalog.story(state.activeID) != nil, state.progress[state.activeID] != nil else { throw StoreError.invalidData }
        for (id, p) in state.progress {
            guard [1, 2].contains(p.edition), let story = StoryCatalog.story(id, version: p.edition), let node = story.node(p.nodeID), p.choices.count <= 4,
                  p.choices.allSatisfy({ ["A","B"].contains($0) }),
                  p.endings.allSatisfy({ StoryCatalog.story(id)!.node($0)?.endingTitle != nil }),
                  (node.endingTitle != nil) == (p.choices.count == 4) else { throw StoreError.invalidData }
        }
    }
    static func migrate(_ old: LegacyState) throws -> StoryState {
        guard old.choices.count <= 4, old.choices.allSatisfy({ ["A","B"].contains($0) }) else { throw StoreError.invalidData }
        var state = StoryState(); state.select("last-letter")
        var p = StoryProgress(); p.contentVersion = 1; p.steps = nil; p.choices = old.choices; p.updated = old.updated
        for c in old.choices { p.nodeID = StoryCatalog.story(state.activeID, version: 1)!.node(p.nodeID)!.options[c == "A" ? 0 : 1].next }
        // Completed validation saves retain the ending they actually saw.
        // 验证版中已完成的存档，保留用户当时实际读到的结局。
        if old.choices.count == 4 { p.nodeID = old.choices.filter { $0 == "A" }.count >= 2 ? "endA" : "endB" }
        p.endings = old.endings.compactMap { $0 == "灯火重逢" ? "endA" : ($0 == "寄往明天" ? "endB" : nil) }
        state.progress[state.activeID] = p
        return state
    }
    static func transaction(_ mutate: ((inout StoryState) -> Void)? = nil) throws -> StoryState {
        try StoryContent.requireAvailable()
        let dir = try directory()
        let fd = open(dir.appendingPathComponent("state.lock").path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard fd >= 0 else { throw CocoaError(.fileWriteUnknown) }
        defer { flock(fd, LOCK_UN); close(fd) }
        guard flock(fd, LOCK_EX) == 0 else { throw CocoaError(.fileWriteUnknown) }
        let url = dir.appendingPathComponent("library-v2.json")
        let exists = FileManager.default.fileExists(atPath: url.path)
        var state: StoryState
        if exists { state = try JSONDecoder().decode(StoryState.self, from: Data(contentsOf: url)) }
        else {
            let legacy = dir.appendingPathComponent("state.json")
            if FileManager.default.fileExists(atPath: legacy.path) { state = try migrate(JSONDecoder().decode(LegacyState.self, from: Data(contentsOf: legacy))) }
            else { state = StoryState(); state.select(state.activeID) }
        }
        try validate(state)
        prepareJourneys(&state)
        if let mutate { mutate(&state) }
        try validate(state)
        let encoded = try JSONEncoder().encode(state)
        try encoded.write(to: url, options: .atomic)
        return state
    }
    static func choose(_ choice: String, run: String, step: Int, page: Int? = nil, languageToken: String? = nil) throws {
        _ = try transaction { state in
            guard (page == nil || (page == state.pageIndex && state.lastPage)), (languageToken == nil || languageToken == state.languageToken), state.run == run, state.step == step, !state.finished, ["A","B"].contains(choice) else { return }
            var p = state.current
            let option = state.node.options[choice == "A" ? 0 : 1]
            p.steps = (p.steps ?? []) + [JourneyStep(node: state.node, choice: choice, optionTitle: option.title)]
            p.nodeID = state.node.options[choice == "A" ? 0 : 1].next
            p.choices.append(choice); p.updated = Date()
            if state.story.node(p.nodeID)!.endingTitle != nil && !p.endings.contains(p.nodeID) { p.endings.append(p.nodeID) }
            if state.story.node(p.nodeID)!.endingTitle != nil { archive(&p, story: state.story) }
            state.progress[state.activeID] = p
            state.widgetPage = 0
        }
    }
    // End-screen actions are checked inside the same lock as the mutation.
    // 结局页操作的校验和存档修改放在同一个锁内完成。
    static func finishAction(_ action: String, run: String, page: Int? = nil, languageToken: String? = nil) throws {
        _ = try transaction { state in
            guard (page == nil || (page == state.pageIndex && state.lastPage)), (languageToken == nil || languageToken == state.languageToken), state.run == run, state.finished else { return }
            state.widgetPage = 0
            if action == "restart" {
                state.progress[state.activeID] = freshProgress(state.current, id: state.activeID)
            } else if action == "next" {
                let index = StoryCatalog.all.firstIndex { $0.id == state.activeID }!
                let candidates = (1..<StoryCatalog.all.count).map { StoryCatalog.all[(index + $0) % StoryCatalog.all.count].id }
                let preferred = state.nextStoryOrder == .listOrder ? candidates.first : candidates.first(where: { (state.progress[$0]?.choices.count ?? 0) < 4 })
                guard let next = preferred ?? candidates.first else { return }
                if state.progress[next]?.choices.count == 4 {
                    state.progress[next] = freshProgress(state.progress[next], id: next)
                }
                state.select(next)
            }
        }
    }
    static func turnPage(_ delta: Int, run: String, step: Int, page: Int, languageToken: String) throws {
        _ = try transaction { state in
            guard [-1, 1].contains(delta), state.run == run, state.step == step,
                  state.pageIndex == page, state.languageToken == languageToken else { return }
            state.widgetPage = min(max(page + delta, 0), state.readingPages.count - 1)
        }
    }
    static func setLanguage(_ language: StoryLanguage) throws {
        _ = try transaction { state in
            if state.language != language { state.language = language; state.widgetPage = 0 }
        }
    }
    static func setNextStoryOrder(_ order: NextStoryOrder) throws {
        _ = try transaction { $0.nextStoryOrder = order }
    }
    static func select(_ id: String) throws {
        guard StoryCatalog.story(id) != nil else { throw StoreError.invalidData }
        _ = try transaction { $0.select(id) }
    }
    static func reset(_ id: String) throws {
        guard StoryCatalog.story(id) != nil else { throw StoreError.invalidData }
        _ = try transaction { state in
            state.progress[id] = freshProgress(state.progress[id], id: id); state.select(id); state.widgetPage = 0
        }
    }
}
