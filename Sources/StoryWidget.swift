import SwiftUI
import WidgetKit
import AppIntents

struct ChooseIntent: AppIntent {
    static var title: LocalizedStringResource = "Choose a story branch"
    static var openAppWhenRun: Bool = false
    @Parameter(title: "Choice") var choice: String
    @Parameter(title: "Run") var run: String
    @Parameter(title: "Scene") var step: Int
    @Parameter(title: "Page") var page: Int
    @Parameter(title: "Language") var languageToken: String
    init() {}
    init(_ choice: String, state: StoryState) { self.choice = choice; run = state.run; step = state.step; page = state.pageIndex; languageToken = state.languageToken }
    func perform() async throws -> some IntentResult {
        try StoryStore.choose(choice, run: run, step: step, page: page, languageToken: languageToken)
        return .result()
    }
}
struct FinishIntent: AppIntent {
    static var title: LocalizedStringResource = "Continue reading"
    static var openAppWhenRun: Bool = false
    @Parameter(title: "Action") var action: String
    @Parameter(title: "Run") var run: String
    @Parameter(title: "Page") var page: Int
    @Parameter(title: "Language") var languageToken: String
    init() {}
    init(_ action: String, state: StoryState) { self.action = action; run = state.run; page = state.pageIndex; languageToken = state.languageToken }
    func perform() async throws -> some IntentResult {
        try StoryStore.finishAction(action, run: run, page: page, languageToken: languageToken)
        return .result()
    }
}
struct TurnPageIntent: AppIntent {
    static var title: LocalizedStringResource = "Turn a page"
    static var openAppWhenRun: Bool = false
    @Parameter(title: "Direction") var delta: Int
    @Parameter(title: "Run") var run: String
    @Parameter(title: "Scene") var step: Int
    @Parameter(title: "Page") var page: Int
    @Parameter(title: "Language") var languageToken: String
    init() {}
    init(_ delta: Int, state: StoryState) {
        self.delta = delta; run = state.run; step = state.step
        page = state.pageIndex; languageToken = state.languageToken
    }
    func perform() async throws -> some IntentResult {
        try StoryStore.turnPage(delta, run: run, step: step, page: page, languageToken: languageToken)
        return .result()
    }
}
struct Entry: TimelineEntry { let date: Date; let state: StoryState; var error: Bool = false }
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry { Entry(date: .now, state: StoryState(), error: StoryContent.error != nil) }
    func current() -> Entry { do { return Entry(date: .now, state: try StoryStore.transaction()) } catch { return Entry(date: .now, state: StoryState(), error: true) } }
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) { completion(current()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) { completion(Timeline(entries: [current()], policy: .never)) }
}
struct StoryWidgetView: View {
    let entry: Entry
    var l: StoryLocalizer { entry.state.localizer }
    var backButton: AnyView? {
        guard entry.state.pageIndex > 0 else { return nil }
        return AnyView(Button(intent: TurnPageIntent(-1, state: entry.state)) { Image(systemName: "chevron.left").frame(width: 28, height: 22) }.buttonStyle(.plain).accessibilityLabel(l("上一页")))
    }
    var body: some View {
        Group {
            if entry.error { Text(l(StoryContent.error == nil ? "暂时无法读取进度，请在 App 中重试。" : "故事资源暂时无法加载，请打开 App 查看。")).font(.subheadline).padding() }
            else {
                WidgetReadingLayout(state: entry.state, backButton: backButton) {
                    HStack(spacing: 8) {
                        if !entry.state.lastPage {
                            Button(intent: TurnPageIntent(1, state: entry.state)) {
                                WidgetChoiceLabel(title: l("下一页") + " · \(entry.state.pageIndex + 1)/\(entry.state.readingPages.count)")
                            }
                        } else if entry.state.finished {
                            Button(intent: FinishIntent("restart", state: entry.state)) { WidgetChoiceLabel(title: l("重新开始")) }
                            Button(intent: FinishIntent("next", state: entry.state)) { WidgetChoiceLabel(title: l("换个故事"), alternate: true) }
                        } else {
                            ForEach(0..<2) { i in
                                Button(intent: ChooseIntent(i == 0 ? "A" : "B", state: entry.state)) {
                                    WidgetChoiceLabel(title: "\(i == 0 ? "A" : "B") · \(l(entry.state.options[i]))", alternate: i == 1)
                                }
                            }
                        }
                    }
                }.invalidatableContent()
            }
        }.containerBackground(for: .widget) { WidgetCandyBackground() }
    }
}

@main struct StoryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MicroStory", provider: Provider()) { StoryWidgetView(entry: $0) }
            .contentMarginsDisabled()
            .configurationDisplayName("TinyStory").description("A short story in four choices, right on your Home Screen.").supportedFamilies([.systemMedium])
    }
}
