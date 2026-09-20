import SwiftUI
import WidgetKit
import AppIntents

struct ChooseIntent: AppIntent {
    static var title: LocalizedStringResource = "选择剧情分支"
    static var openAppWhenRun: Bool = false
    @Parameter(title: "选项") var choice: String
    @Parameter(title: "本轮") var run: String
    @Parameter(title: "节点") var step: Int
    init() {}
    // 将显示时的轮次和步数带入操作，由存储层检查是否仍然有效。
    init(_ choice: String, state: StoryState) { self.choice = choice; run = state.run; step = state.step }
    func perform() async throws -> some IntentResult {
        try StoryStore.choose(choice, run: run, step: step)
        return .result()
    }
}
struct FinishIntent: AppIntent {
    static var title: LocalizedStringResource = "继续桌面阅读"
    static var openAppWhenRun: Bool = false
    @Parameter(title: "操作") var action: String
    @Parameter(title: "本轮") var run: String
    init() {}
    init(_ action: String, state: StoryState) { self.action = action; run = state.run }
    func perform() async throws -> some IntentResult {
        try StoryStore.finishAction(action, run: run)
        return .result()
    }
}
struct Entry: TimelineEntry { let date: Date; let state: StoryState; var error: Bool = false }
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry { Entry(date: .now, state: StoryState()) }
    func current() -> Entry { do { return Entry(date: .now, state: try StoryStore.transaction()) } catch { return Entry(date: .now, state: StoryState(), error: true) } }
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) { completion(current()) }
    // 剧情由用户选择推进，不按时间自动切换节点。
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) { completion(Timeline(entries: [current()], policy: .never)) }
}
struct StoryWidgetView: View {
    let entry: Entry
    var body: some View {
        Group {
            if entry.error { Text("暂时无法读取进度，请在 App 中重试。").font(.subheadline).padding() }
            else {
                WidgetReadingLayout(state: entry.state) {
                    HStack(spacing: 8) {
                        if entry.state.finished {
                            Button(intent: FinishIntent("restart", state: entry.state)) { WidgetChoiceLabel(title: "重新开始") }
                            Button(intent: FinishIntent("next", state: entry.state)) { WidgetChoiceLabel(title: "换个故事") }
                        } else {
                            ForEach(0..<2) { i in
                                Button(intent: ChooseIntent(i == 0 ? "A" : "B", state: entry.state)) {
                                    WidgetChoiceLabel(title: "\(i == 0 ? "A" : "B") · \(entry.state.options[i])")
                                }
                            }
                        }
                    }
                }.invalidatableContent()
            }
        }.containerBackground(.background, for: .widget)
    }
}

@main struct StoryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MicroStory", provider: Provider()) { StoryWidgetView(entry: $0) }
            .contentMarginsDisabled()
            .configurationDisplayName("小小奇遇").description("直接选择，四次选择，读完一个短故事。").supportedFamilies([.systemMedium])
    }
}
