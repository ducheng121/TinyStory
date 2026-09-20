import SwiftUI
import WidgetKit

@main struct StoryApp: App {
    var body: some Scene { WindowGroup { LibraryView().tint(.orange).task {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-audit-layout") { try? LayoutAudit.render() }
        #endif
    } } }
}
struct LibraryView: View {
    @Environment(\.scenePhase) var phase
    @State var state = StoryState()
    @State var error: String?
    @State var loaded = false
    // 回到前台时重新读取共享存档，接上用户在 Widget 中的进度。
    func refresh() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-audit-layout") {
            state = StoryState(); state.select("last-letter"); loaded = true; error = nil
            return
        }
        #endif
        do { state = try StoryStore.transaction(); loaded = true; error = nil }
        catch { self.error = error.localizedDescription }
    }
    // 主 App 修改进度后，同时通知桌面小组件刷新。
    func perform(_ action: () throws -> Void) {
        do { try action(); refresh(); WidgetCenter.shared.reloadAllTimelines() }
        catch { self.error = error.localizedDescription }
    }
    var body: some View {
        TabView {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if loaded {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("四次选择，一段不同的故事。").font(.title3.weight(.medium))
                                Text("在桌面读故事，在这里留下旅程。").font(.subheadline).foregroundStyle(.secondary)
                            }
                            NavigationLink { detail(state.story) } label: {
                                VStack(alignment: .leading, spacing: 14) {
                                    HStack {
                                        Label("正在桌面", systemImage: "square.grid.2x2").font(.caption.bold()).foregroundStyle(.orange)
                                        Spacer()
                                        Text(state.finished ? "已完成" : "\(state.step) / 4 次选择").font(.caption).foregroundStyle(.secondary)
                                    }
                                    Text(state.story.title).font(.title2.bold()).foregroundStyle(.primary)
                                    Text(state.text).font(.body).lineSpacing(4).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                                    HStack {
                                        Text(state.finished ? "回顾这段旅程" : "查看当前故事").font(.subheadline.bold())
                                        Spacer(); Image(systemName: "arrow.right")
                                    }.foregroundStyle(.orange)
                                }.padding(20).background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 24))
                            }.buttonStyle(.plain)
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("故事书架").font(.title2.bold())
                                    Spacer(); Text("\(StoryCatalog.all.count) 篇故事").font(.caption).foregroundStyle(.secondary)
                                }
                                ForEach(StoryCatalog.all) { story in
                                    NavigationLink { detail(story) } label: {
                                        HStack(alignment: .top, spacing: 14) {
                                            Image(systemName: story.symbol).font(.title2).foregroundStyle(.orange)
                                                .frame(width: 48, height: 52).background(Color.orange.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
                                            VStack(alignment: .leading, spacing: 7) {
                                                Text(story.title).font(.headline).foregroundStyle(.primary)
                                                Text(story.summary).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                                                Text(status(story)).font(.caption).foregroundStyle(.secondary)
                                            }
                                            Spacer(minLength: 0)
                                            Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary).padding(.top, 5)
                                        }.multilineTextAlignment(.leading).padding(16)
                                            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
                                    }.buttonStyle(.plain)
                                }
                            }
                        } else if error == nil { ProgressView("正在读取故事…").frame(maxWidth: .infinity) }
                        errorView
                    }.padding(20)
                }.background(Color(uiColor: .systemGroupedBackground)).navigationTitle("小小奇遇")
                    .refreshable { refresh() }
            }.tabItem { Label("故事库", systemImage: "books.vertical") }
            NavigationStack {
                List {
                    Section {
                        NavigationLink { EndingLibrary(state: state) } label: { Label("结局收藏", systemImage: "sparkles") }
                    } header: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("阅读概览").font(.headline)
                            Text("\(state.progress.values.reduce(0) { $0 + ($1.history?.count ?? 0) }) 段旅程 · \(state.progress.values.reduce(0) { $0 + $1.endings.count }) 个结局")
                                .font(.subheadline)
                        }.textCase(nil).padding(.bottom, 8).accessibilityElement(children: .combine)
                    }
                    ForEach(StoryCatalog.all) { story in
                        let p = state.progress[story.id] ?? StoryProgress()
                        let edition = StoryCatalog.story(story.id, version: p.edition)!
                        Section(story.title) {
                            NavigationLink { JourneyHistoryView(story: edition, progress: p) } label: {
                                Label("历史旅程 · \(p.history?.count ?? 0) 次", systemImage: "clock.arrow.circlepath")
                            }
                            NavigationLink { ExploredGraphView(story: edition, progress: p) } label: {
                                Label("已探索分支图", systemImage: "point.3.connected.trianglepath.dotted")
                            }
                        }
                    }
                    errorView
                }.navigationTitle("我的旅程")
            }.tabItem { Label("我的旅程", systemImage: "point.topleft.down.to.point.bottomright.curvepath") }
            NavigationStack {
                List {
                    Section("阅读") {
                        NavigationLink { ReadingSettings(order: state.nextStoryOrder ?? .unfinishedFirst) { order in perform { try StoryStore.setNextStoryOrder(order) } } } label: {
                            Label("换故事顺序", systemImage: "arrow.triangle.2.circlepath")
                        }
                        NavigationLink { HelpView() } label: { Label("桌面阅读指南", systemImage: "square.grid.2x2") }
                    }
                    Section("关于小小奇遇") {
                        Label("离线阅读 · 进度保存在本机", systemImage: "iphone")
                        Text("不需要登录，也不需要联网。当前不提供云同步，删除 App 后数据可能无法恢复。").font(.footnote).foregroundStyle(.secondary)
                    }
                    errorView
                }.navigationTitle("设置")
            }.tabItem { Label("设置", systemImage: "slider.horizontal.3") }
        }.onAppear { refresh() }.onChange(of: phase) { _, p in if p == .active { refresh() } }
    }
    @ViewBuilder var errorView: some View {
        if let error {
            VStack(alignment: .leading, spacing: 8) {
                Label("读取未完成", systemImage: "exclamationmark.circle").font(.headline)
                Text(error).font(.subheadline).foregroundStyle(.secondary)
                Button("重试") { refresh() }
            }.padding(.vertical, 8)
        }
    }
    func status(_ story: Story) -> String {
        let p = state.progress[story.id]
        let count = p?.choices.count ?? 0
        return "\(count == 4 ? "已读完" : (count == 0 ? "未开始" : "已选择 \(count) 次")) · 结局 \(p?.endings.count ?? 0)/\(story.endingNodes.count)"
    }
    func detail(_ story: Story) -> some View {
        StoryDetail(story: StoryCatalog.story(story.id, version: state.progress[story.id]?.edition ?? 2)!, state: state, select: { perform { try StoryStore.select(story.id) } }, restart: { perform { try StoryStore.reset(story.id) } }, error: error)
    }
}
struct StoryDetail: View {
    let story: Story
    let state: StoryState
    let select: () -> Void
    let restart: () -> Void
    let error: String?
    @State private var confirmRestart = false
    var progress: StoryProgress { state.progress[story.id] ?? StoryProgress() }
    var node: StoryNode { story.node(progress.nodeID)! }
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: story.symbol).font(.largeTitle).foregroundStyle(.orange)
                    Text(story.summary).font(.title3).lineSpacing(4)
                }.padding(.vertical, 10)
                Text("四次选择 · \(story.endingNodes.count) 个结局").font(.subheadline).foregroundStyle(.secondary)
            }
            Section(node.endingTitle == nil ? "当前进度 · 已选择 \(progress.choices.count) / 4 次" : "本轮结局 · \(node.endingTitle!)") {
                Text(node.text).font(.body).lineSpacing(6).padding(.vertical, 8)
                ProgressView(value: Double(progress.choices.count), total: 4).tint(.orange).accessibilityLabel("已完成 \(progress.choices.count) 次选择，共四次")
                if !progress.choices.isEmpty {
                    NavigationLink("查看本轮剧情路径") { StoryPathView(story: story, progress: progress) }
                }
                if state.activeID == story.id {
                    Label(node.endingTitle == nil ? "已在桌面，返回小组件继续" : "桌面正在显示这个结局", systemImage: "checkmark.circle").font(.subheadline).foregroundStyle(.secondary)
                } else {
                    Button(node.endingTitle == nil ? "在桌面\(progress.choices.isEmpty ? "开始" : "继续")" : "在桌面显示结局", action: select)
                }
                if !progress.choices.isEmpty { Button("重新开始") { confirmRestart = true } }
            }
            Section("探索与回顾") {
                NavigationLink { JourneyHistoryView(story: story, progress: progress) } label: { Label("历史旅程 · \(progress.history?.count ?? 0) 次", systemImage: "clock.arrow.circlepath") }
                NavigationLink { ExploredGraphView(story: story, progress: progress) } label: { Label("已探索分支图", systemImage: "point.3.connected.trianglepath.dotted") }
                if progress.edition == 1 {
                    Text("本轮继续旧版剧情；重新开始后进入新版分支，旧旅程和结局会保留。").font(.footnote).foregroundStyle(.secondary)
                }
            }
            Section("已发现结局 · \(progress.endings.count)/\(story.endingNodes.count)") {
                if progress.endings.isEmpty { Text("读到故事结尾后，会将结局收藏在这里。").foregroundStyle(.secondary) }
                ForEach(story.endingNodes.filter { progress.endings.contains($0.id) }, id: \.id) { ending in
                    NavigationLink(ending.endingTitle!) { EndingDetail(storyTitle: story.title, node: ending) }
                }
            }
            if let error { Text(error).foregroundStyle(.secondary) }
        }.navigationTitle(story.title)
            .confirmationDialog("重新开始这篇故事？", isPresented: $confirmRestart, titleVisibility: .visible) {
                Button("重新开始", role: .destructive, action: restart)
                Button("取消", role: .cancel) {}
            } message: { Text("本轮路径将存入历史旅程，已收藏的结局会保留。桌面将切换到这篇故事。") }
    }
}
struct StoryPathView: View {
    let story: Story
    let progress: StoryProgress
    var body: some View { JourneyDetailView(journey: progress.snapshot(story: story), title: "本轮剧情路径") }
}
struct JourneyDetailView: View {
    let journey: Journey
    var title = "旅程回顾"
    var body: some View {
        List {
            if journey.reconstructed {
                Section { Text("这是根据升级时保留的选择记录恢复的路径，使用旧版剧情文本；更早已重玩的记录无法补回。").font(.footnote).foregroundStyle(.secondary) }
            }
            ForEach(Array(journey.steps.enumerated()), id: \.offset) { index, step in
                Section("第 \(index + 1) 次选择") {
                    Text(step.node.text).lineSpacing(6).padding(.vertical, 6)
                    Text("你的选择：\(step.choice) · \(step.optionTitle)").foregroundStyle(.orange)
                }
            }
            Section(journey.lastNode.endingTitle.map { "结局 · \($0)" } ?? "读到这里") { Text(journey.lastNode.text).lineSpacing(6).padding(.vertical, 6) }
        }.navigationTitle(title)
    }
}
struct JourneyHistoryView: View {
    let story: Story
    let progress: StoryProgress
    var body: some View {
        List {
            Section { Text("读到结局时自动保存；中途重新开始也会保留已走路径。历史旅程保留当时的正文和选择。").font(.footnote).foregroundStyle(.secondary) }
            if (progress.history ?? []).isEmpty { Text("还没有历史旅程。完成故事或重新开始后，可以在这里回顾。").foregroundStyle(.secondary) }
            ForEach((progress.history ?? []).reversed()) { journey in
                NavigationLink { JourneyDetailView(journey: journey) } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(journey.lastNode.endingTitle ?? "未完成的旅程").font(.headline)
                        Text("\(journey.steps.count) 次选择 · 第 \(journey.storyVersion) 版剧情").font(.caption).foregroundStyle(.secondary)
                        Text(journey.date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }.navigationTitle("历史旅程")
    }
}
struct ExploredGraphView: View {
    let story: Story
    let progress: StoryProgress
    var tree: ExploredBranch { story.exploredTree(progress) }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("已读 \(tree.visibleIDs.count) / \(story.nodes.count) 个节点").font(.headline)
                Text("橙色连接表示走过的选择。未探索节点不显示剧情和结局名称。相同节点可能由不同路线到达。").font(.footnote).foregroundStyle(.secondary)
                branch(tree, depth: 0)
            }.padding()
        }.navigationTitle("已探索分支图")
    }
    func branch(_ tree: ExploredBranch, depth: Int) -> AnyView {
        let node = tree.node
        return AnyView(VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Label(node.endingTitle ?? (depth == 0 ? "故事开始" : "第 \(depth + 1) 节点"), systemImage: node.endingTitle == nil ? "circle.fill" : "flag.checkered")
                    .font(.subheadline.bold()).foregroundStyle(.orange)
                Text(node.text).font(.subheadline)
            }.padding(12).frame(maxWidth: .infinity, alignment: .leading).background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            ForEach(Array(tree.exits.enumerated()), id: \.offset) { _, exit in
                let taken = exit.child != nil
                HStack(alignment: .top, spacing: 8) {
                    Rectangle().fill(taken ? Color.orange : Color.secondary.opacity(0.25)).frame(width: 2)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exit.label).font(.caption.bold()).foregroundStyle(taken ? .orange : .secondary)
                        if let child = exit.child { branch(child, depth: depth + 1) }
                        else { Label("未探索", systemImage: "lock").font(.subheadline).foregroundStyle(.secondary).padding(.vertical, 8) }
                    }
                }.fixedSize(horizontal: false, vertical: true).padding(.leading, 6)
            }
        })
    }
}
struct EndingLibrary: View {
    let state: StoryState
    var total: Int { state.progress.values.reduce(0) { $0 + $1.endings.count } }
    var body: some View {
        List {
            Section { Text("已发现 \(total) / \(StoryCatalog.all.reduce(0) { $0 + $1.endingNodes.count }) 个结局").foregroundStyle(.secondary) }
            ForEach(StoryCatalog.all) { story in
                Section(story.title) {
                    let ids = state.progress[story.id]?.endings ?? []
                    if ids.isEmpty { Text("尚未发现结局").foregroundStyle(.secondary) }
                    ForEach(story.endingNodes.filter { ids.contains($0.id) }, id: \.id) { node in
                        NavigationLink(node.endingTitle!) { EndingDetail(storyTitle: story.title, node: node) }
                    }
                }
            }
        }.navigationTitle("结局收藏")
    }
}
struct EndingDetail: View {
    let storyTitle: String
    let node: StoryNode
    var body: some View {
        List { Section(storyTitle) { Text(node.text).font(.body).lineSpacing(6).padding(.vertical, 8) } }
            .navigationTitle(node.endingTitle ?? "结局")
    }
}
struct ReadingSettings: View {
    let order: NextStoryOrder
    let update: (NextStoryOrder) -> Void
    var body: some View {
        List {
            Section {
                Picker("换故事顺序", selection: Binding(get: { order }, set: update)) {
                    ForEach(NextStoryOrder.allCases, id: \.self) { value in Text(value.title).tag(value) }
                }
            } header: { Text("桌面阅读") } footer: {
                Text("优先未完成：按目录寻找尚未读完的故事，接着原进度读。按列表顺序：直接进入下一篇。遇到已完成故事会重新开始，已收藏结局保留。")
            }
            Section("外观") { Text("按钮保持橙色，App 外观跟随系统。") }
            Section("本地保存") { Text("设置与进度只保存在这台设备。切换故事不会清空其他故事进度。") }
        }.navigationTitle("阅读设置")
    }
}
struct HelpView: View {
    var body: some View {
        List {
            Section("添加小组件") {
                Text("1. 回到主屏幕，长按空白处。")
                Text("2. 点击「编辑」→「添加小组件」。")
                Text("3. 搜索「小小奇遇」，添加中号小组件。")
            }
            Section("开始阅读") { Text("在故事详情中选择要在桌面阅读的故事。返回主屏幕，点击 A 或 B，四次选择后获得结局。结局页可直接点「重新开始」或「换个故事」，无需打开 App。「换个故事」默认优先继续尚未完成的故事；也可在阅读设置中改为按列表顺序。遇到已完成故事会重新开始，收藏不丢失。切换故事会保留各自进度，所有小组件显示同一篇当前故事。") }
            Section("进度与隐私") { Text("故事和进度均保存在本机，不需要联网。重新开始会保留已发现结局和历史旅程。当前不提供云同步或备份，删除 App 后数据可能无法恢复。") }
        }.navigationTitle("桌面阅读指南")
    }
}

extension Story {
    var symbol: String {
        switch id {
        case "last-letter": return "envelope"
        case "rain-shop": return "cloud.rain"
        case "moon-post": return "moon.stars"
        case "sea-radio": return "radio"
        default: return "cloud.sun"
        }
    }
}

#if DEBUG
@MainActor enum LayoutAudit {
    static func render() throws {
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("LayoutAudit")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let longest = StoryCatalog.all.flatMap { story in story.nodes.map { (story, $0) } }.max { $0.1.text.count < $1.1.text.count }!
        for (name, story, node) in [("longest", longest.0, longest.1), ("ending", StoryCatalog.all[0], StoryCatalog.all[0].endingNodes.last!)] {
            var state = StoryState(); state.select(story.id)
            state.progress[story.id]!.nodeID = node.id
            state.progress[story.id]!.choices = node.endingTitle == nil ? ["A","A"] : ["B","B","B","B"]
            for dark in [false, true] {
                for large in [false, true] {
                    let content = WidgetReadingLayout(state: state) {
                        HStack(spacing: 8) {
                            WidgetChoiceLabel(title: state.finished ? "重新开始" : "A · " + state.options[0])
                            WidgetChoiceLabel(title: state.finished ? "换个故事" : "B · " + state.options[1])
                        }
                    }.frame(width: 320, height: 155)
                        .background(dark ? Color.black : Color.white)
                        .environment(\.colorScheme, dark ? .dark : .light)
                        .environment(\.dynamicTypeSize, large ? .accessibility3 : .large)
                    let renderer = ImageRenderer(content: content); renderer.scale = 3
                    guard let data = renderer.uiImage?.pngData() else { continue }
                    try data.write(to: folder.appendingPathComponent("\(name)-\(dark ? "dark" : "light")-\(large ? "large" : "normal").png"))
                }
            }
        }
    }
}
#endif
