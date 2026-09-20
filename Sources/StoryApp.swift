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
    var l: StoryLocalizer { state.localizer }
    @Environment(\.scenePhase) var phase
    @State var state = StoryState()
    @State var error: String?
    @State var loaded = false
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
    func perform(_ action: () throws -> Void) {
        do { try action(); refresh(); WidgetCenter.shared.reloadAllTimelines() }
        catch { self.error = error.localizedDescription }
    }
    @State private var selectedTab = 0
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(l("小小奇遇")).font(.largeTitle.bold()).foregroundStyle(TinyPalette.title)
                                if (state.language ?? .system).resolved() == .chinese {
                                    Text(verbatim: "TinyStory").font(.title3.weight(.semibold)).foregroundStyle(TinyPalette.title.opacity(0.55))
                                }
                            }
                            Spacer()
                            Image(systemName: "face.smiling.fill").font(.system(size: 34)).foregroundStyle(.orange).accessibilityHidden(true)
                        }
                        Text(l("四次选择，一段小小奇遇。", "Four choices. A tiny adventure.")).font(.title3)
                        if loaded {
                            NavigationLink { detail(state.story) } label: {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack(alignment: .top, spacing: 14) {
                                        VStack(alignment: .leading, spacing: 10) {
                                            Label(l("正在桌面"), systemImage: "face.smiling.fill").font(.caption.bold()).foregroundStyle(TinyPalette.title)
                                            Text(l(state.story.title)).font(.title2.bold())
                                            Text(state.finished ? l("已完成") : l("已选择 \(state.step) / 4 次", "\(state.step) / 4 choices")).font(.subheadline).foregroundStyle(.secondary)
                                        }.frame(maxWidth: .infinity, alignment: .leading)
                                        StoryCover(story: state.story).frame(width: 104, height: 104)
                                    }
                                    Text(l(state.text)).font(.subheadline).lineSpacing(4).foregroundStyle(.secondary).lineLimit(3)
                                    HStack {
                                        Spacer()
                                        Text(state.finished ? l("回顾这段旅程") : l("查看当前故事")).font(.subheadline.bold())
                                        Image(systemName: "chevron.right").font(.caption.bold())
                                        Spacer()
                                    }.padding(.vertical, 14).background(TinyPalette.peach, in: Capsule())
                                }.padding(18).tinyCard()
                            }.buttonStyle(.plain)
                            HStack {
                                Text(l("故事书架")).font(.title2.bold())
                                Spacer()
                                Text(l("\(StoryCatalog.all.count) 篇故事", "\(StoryCatalog.all.count) stories")).font(.caption).foregroundStyle(.secondary)
                            }
                            VStack(spacing: 12) {
                                ForEach(StoryCatalog.all) { story in
                                    NavigationLink { detail(story) } label: {
                                        HStack(alignment: .center, spacing: 14) {
                                            StoryCover(story: story).frame(width: 76, height: 86)
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(l(story.title)).font(.headline)
                                                Text(l(story.summary)).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                                                Text(status(story)).font(.caption).foregroundStyle(.secondary)
                                            }.frame(maxWidth: .infinity, alignment: .leading)
                                            Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
                                        }.padding(14).tinyCard()
                                    }.buttonStyle(.plain)
                                }
                            }
                        } else if error == nil { ProgressView(l("正在读取故事…")) }
                        errorView
                    }.padding(20)
                }.background(TinyBackground()).toolbar(.hidden, for: .navigationBar).refreshable { refresh() }
            }.tabItem { Label(l("故事库"), systemImage: "books.vertical") }.tag(0)
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        Text(l("我的旅程")).font(.largeTitle.bold()).foregroundStyle(TinyPalette.title)
                        Text(l("\(state.progress.values.reduce(0) { $0 + ($1.history?.count ?? 0) }) 段旅程 · \(state.progress.values.reduce(0) { $0 + $1.endings.count }) 个结局", "\(state.progress.values.reduce(0) { $0 + ($1.history?.count ?? 0) }) journeys · \(state.progress.values.reduce(0) { $0 + $1.endings.count }) endings")).foregroundStyle(.secondary)
                        NavigationLink { EndingLibrary(state: state) } label: {
                            TinyMenuRow(title: l("结局收藏"), icon: "sparkles", mint: false)
                                .padding(16).tinyCard()
                        }.buttonStyle(.plain)
                        ForEach(StoryCatalog.all) { story in
                            let p = state.progress[story.id] ?? StoryProgress()
                            let edition = StoryCatalog.story(story.id, version: p.edition)!
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(spacing: 14) {
                                    StoryCover(story: story).frame(width: 70, height: 76)
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(l(story.title)).font(.headline).foregroundStyle(TinyPalette.title)
                                        Text(l(story.summary)).font(.subheadline).foregroundStyle(.secondary)
                                    }
                                }
                                NavigationLink { JourneyHistoryView(story: edition, progress: p) } label: {
                                    TinyMenuRow(title: l("历史旅程 · \(p.history?.count ?? 0) 次", "Past journeys · \(p.history?.count ?? 0)"), icon: "clock", mint: false)
                                }.buttonStyle(.plain)
                                Divider().overlay(TinyPalette.border)
                                NavigationLink { ExploredGraphView(story: edition, progress: p) } label: {
                                    TinyMenuRow(title: l("已探索分支图"), icon: "point.3.connected.trianglepath.dotted", mint: true)
                                }.buttonStyle(.plain)
                            }.padding(16).tinyCard()
                        }
                        errorView
                    }.padding(20)
                }.background(TinyBackground()).toolbar(.hidden, for: .navigationBar)
            }.tabItem { Label(l("我的旅程"), systemImage: "point.topleft.down.to.point.bottomright.curvepath") }.tag(1)
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text(l("设置")).font(.largeTitle.bold()).foregroundStyle(TinyPalette.title)
                        HStack(spacing: 16) {
                            Image(systemName: "face.smiling.fill").font(.system(size: 54)).foregroundStyle(.orange).accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(l("小小奇遇")).font(.title.bold()).foregroundStyle(TinyPalette.title)
                                if (state.language ?? .system).resolved() == .chinese { Text(verbatim: "TinyStory").foregroundStyle(TinyPalette.title) }
                            }
                        }.padding(.vertical, 8)
                        Text(l("阅读")).font(.title3.bold()).foregroundStyle(TinyPalette.title)
                        VStack(spacing: 16) {
                            NavigationLink { ReadingSettings(order: state.nextStoryOrder ?? .unfinishedFirst) { order in perform { try StoryStore.setNextStoryOrder(order) } } } label: {
                                TinyMenuRow(title: l("换故事顺序"), icon: "book", mint: false, subtitle: l((state.nextStoryOrder ?? .unfinishedFirst).title))
                            }.buttonStyle(.plain)
                            Divider().overlay(TinyPalette.border)
                            NavigationLink { HelpView() } label: { TinyMenuRow(title: l("桌面阅读指南"), icon: "doc.text", mint: true) }.buttonStyle(.plain)
                        }.padding(16).tinyCard()
                        Text(l("语言")).font(.title3.bold()).foregroundStyle(TinyPalette.title)
                        VStack(alignment: .leading, spacing: 14) {
                            ViewThatFits(in: .horizontal) {
                                HStack(spacing: 6) { languageButtons }
                                VStack(spacing: 6) { languageButtons }
                            }
                            Text(l("语言同时应用于 App 和小组件，不改变故事进度。")).font(.footnote).foregroundStyle(.secondary)
                        }.padding(16).tinyCard()
                        Text(l("关于小小奇遇")).font(.title3.bold()).foregroundStyle(TinyPalette.title)
                        VStack(alignment: .leading, spacing: 10) {
                            Label(l("离线阅读 · 进度保存在本机"), systemImage: "iphone").font(.headline)
                            Text(l("不需要登录，也不需要联网。当前不提供云同步，删除 App 后数据可能无法恢复。")).font(.footnote).foregroundStyle(.secondary)
                        }.padding(18).frame(maxWidth: .infinity, alignment: .leading).tinyCard()
                        errorView
                    }.padding(20)
                }.background(TinyBackground()).toolbar(.hidden, for: .navigationBar)
            }.tabItem { Label(l("设置"), systemImage: "gearshape") }.tag(2)
        }.foregroundStyle(TinyPalette.text)
            .toolbarBackground(TinyPalette.background, for: .tabBar)
            .environment(\.storyLanguage, state.language ?? .system)
            .environment(\.locale, (state.language ?? .system).locale)
            .onAppear {
                refresh()
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("-audit-settings") { selectedTab = 2 }
                if ProcessInfo.processInfo.arguments.contains("-audit-journeys") { selectedTab = 1 }
                #endif
            }.onChange(of: phase) { _, p in if p == .active { refresh() } }
    }
    @ViewBuilder var languageButtons: some View {
        ForEach(StoryLanguage.allCases, id: \.self) { value in
            let selected = (state.language ?? .system) == value
            Button { perform { try StoryStore.setLanguage(value) } } label: {
                Text(l(value.title)).font(.subheadline.weight(selected ? .semibold : .regular))
                    .fixedSize().padding(.horizontal, 10).padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(selected ? TinyPalette.pink : Color.clear, in: RoundedRectangle(cornerRadius: 13))
            }.buttonStyle(.plain).accessibilityAddTraits(selected ? [.isSelected] : [])
        }
    }
    @ViewBuilder var errorView: some View {
        if let error {
            VStack(alignment: .leading, spacing: 8) {
                Label(l("读取未完成"), systemImage: "exclamationmark.circle").font(.headline)
                Text(l(error)).font(.subheadline).foregroundStyle(.secondary)
                Button(l("重试")) { refresh() }
            }.padding(.vertical, 8)
        }
    }
    func status(_ story: Story) -> String {
        let p = state.progress[story.id]
        let count = p?.choices.count ?? 0
        let reading = count == 4 ? l("已读完", "Finished") : (count == 0 ? l("未开始", "Not started") : l("已选择 \(count) 次", "\(count) choices made"))
        return l("\(reading) · 结局 \(p?.endings.count ?? 0)/\(story.endingNodes.count)", "\(reading) · Endings \(p?.endings.count ?? 0)/\(story.endingNodes.count)")
    }
    func detail(_ story: Story) -> some View {
        StoryDetail(story: StoryCatalog.story(story.id, version: state.progress[story.id]?.edition ?? 2)!, state: state, select: { perform { try StoryStore.select(story.id) } }, restart: { perform { try StoryStore.reset(story.id) } }, error: error)
    }
}
struct StoryDetail: View {
    @Environment(\.storyLanguage) private var language
    var l: StoryLocalizer { StoryLocalizer(language: language) }
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
                    Text(l(story.summary)).font(.title3).lineSpacing(4)
                }.padding(.vertical, 10)
                Text(l("四次选择 · \(story.endingNodes.count) 个结局", "Four choices · \(story.endingNodes.count) endings")).font(.subheadline).foregroundStyle(.secondary)
            }
            Section(node.endingTitle == nil ? l("当前进度 · 已选择 \(progress.choices.count) / 4 次", "Progress · \(progress.choices.count) / 4 choices") : l("本轮结局 · \(node.endingTitle!)", "Ending · \(l(node.endingTitle!))")) {
                Text(l(node.text)).font(.body).lineSpacing(6).padding(.vertical, 8)
                ProgressView(value: Double(progress.choices.count), total: 4).tint(.orange).accessibilityLabel(l("已完成 \(progress.choices.count) 次选择，共四次", "\(progress.choices.count) of four choices completed"))
                if !progress.choices.isEmpty {
                    NavigationLink(l("查看本轮剧情路径")) { StoryPathView(story: story, progress: progress) }
                }
                if state.activeID == story.id {
                    Label(node.endingTitle == nil ? l("已在桌面，返回小组件继续") : l("桌面正在显示这个结局"), systemImage: "checkmark.circle").font(.subheadline).foregroundStyle(.secondary)
                } else {
                    Button(node.endingTitle == nil ? l("在桌面\(progress.choices.isEmpty ? "开始" : "继续")", "\(progress.choices.isEmpty ? "Start" : "Continue") in widget") : l("在桌面显示结局"), action: select)
                }
                if !progress.choices.isEmpty { Button(l("重新开始")) { confirmRestart = true } }
            }
            Section(l("探索与回顾")) {
                NavigationLink { JourneyHistoryView(story: story, progress: progress) } label: { Label(l("历史旅程 · \(progress.history?.count ?? 0) 次", "Past journeys · \(progress.history?.count ?? 0)"), systemImage: "clock.arrow.circlepath") }
                NavigationLink { ExploredGraphView(story: story, progress: progress) } label: { Label(l("已探索分支图"), systemImage: "point.3.connected.trianglepath.dotted") }
                if progress.edition == 1 {
                    Text(l("本轮继续旧版剧情；重新开始后进入新版分支，旧旅程和结局会保留。")).font(.footnote).foregroundStyle(.secondary)
                }
            }
            Section(l("已发现结局 · \(progress.endings.count)/\(story.endingNodes.count)", "Endings found · \(progress.endings.count)/\(story.endingNodes.count)")) {
                if progress.endings.isEmpty { Text(l("读到故事结尾后，会将结局收藏在这里。")).foregroundStyle(.secondary) }
                ForEach(story.endingNodes.filter { progress.endings.contains($0.id) }, id: \.id) { ending in
                    NavigationLink(l(ending.endingTitle!)) { EndingDetail(storyTitle: story.title, node: ending) }
                }
            }
            if let error { Text(l(error)).foregroundStyle(.secondary) }
        }.tinyPage().navigationTitle(l(story.title))
            .confirmationDialog(l("重新开始这篇故事？"), isPresented: $confirmRestart, titleVisibility: .visible) {
                Button(l("重新开始"), role: .destructive, action: restart)
                Button(l("取消"), role: .cancel) {}
            } message: { Text(l("本轮路径将存入历史旅程，已收藏的结局会保留。桌面将切换到这篇故事。")) }
    }
}
struct StoryPathView: View {
    @Environment(\.storyLanguage) private var language
    var l: StoryLocalizer { StoryLocalizer(language: language) }
    let story: Story
    let progress: StoryProgress
    var body: some View { JourneyDetailView(journey: progress.snapshot(story: story), title: l("本轮剧情路径")) }
}
struct JourneyDetailView: View {
    @Environment(\.storyLanguage) private var language
    var l: StoryLocalizer { StoryLocalizer(language: language) }
    let journey: Journey
    var title = "旅程回顾"
    var body: some View {
        List {
            if journey.reconstructed {
                Section { Text(l("这是根据升级时保留的选择记录恢复的路径，使用旧版剧情文本；更早已重玩的记录无法补回。")).font(.footnote).foregroundStyle(.secondary) }
            }
            ForEach(Array(journey.steps.enumerated()), id: \.offset) { index, step in
                Section(l("第 \(index + 1) 次选择", "Choice \(index + 1)")) {
                    Text(l(step.node.text)).lineSpacing(6).padding(.vertical, 6)
                    Text(l("你的选择：\(step.choice) · \(step.optionTitle)", "You chose: \(step.choice) · \(l(step.optionTitle))")).foregroundStyle(.orange)
                }
            }
            Section(journey.lastNode.endingTitle.map { l("结局 · \($0)", "Ending · \(l($0))") } ?? l("读到这里")) { Text(l(journey.lastNode.text)).lineSpacing(6).padding(.vertical, 6) }
        }.tinyPage().navigationTitle(l(title))
    }
}
struct JourneyHistoryView: View {
    @Environment(\.storyLanguage) private var language
    var l: StoryLocalizer { StoryLocalizer(language: language) }
    let story: Story
    let progress: StoryProgress
    var body: some View {
        List {
            Section { Text(l("读到结局时自动保存；中途重新开始也会保留已走路径。历史旅程保留当时的正文和选择。")).font(.footnote).foregroundStyle(.secondary) }
            if (progress.history ?? []).isEmpty { Text(l("还没有历史旅程。完成故事或重新开始后，可以在这里回顾。")).foregroundStyle(.secondary) }
            ForEach((progress.history ?? []).reversed()) { journey in
                NavigationLink { JourneyDetailView(journey: journey) } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(journey.lastNode.endingTitle.map { l($0) } ?? l("未完成的旅程")).font(.headline)
                        Text(l("\(journey.steps.count) 次选择 · 第 \(journey.storyVersion) 版剧情", "\(journey.steps.count) choices · Story edition \(journey.storyVersion)")).font(.caption).foregroundStyle(.secondary)
                        Text(journey.date.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened).locale(language.locale))).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }.tinyPage().navigationTitle(l("历史旅程"))
    }
}
struct ExploredGraphView: View {
    @Environment(\.storyLanguage) private var language
    var l: StoryLocalizer { StoryLocalizer(language: language) }
    let story: Story
    let progress: StoryProgress
    var tree: ExploredBranch { story.exploredTree(progress) }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(l("已读 \(tree.visibleIDs.count) / \(story.nodes.count) 个节点", "\(tree.visibleIDs.count) / \(story.nodes.count) scenes explored")).font(.headline)
                Text(l("橙色连接表示走过的选择。未探索节点不显示剧情和结局名称。相同节点可能由不同路线到达。")).font(.footnote).foregroundStyle(.secondary)
                branch(tree, depth: 0)
            }.padding()
        }.tinyPage().navigationTitle(l("已探索分支图"))
    }
    func branch(_ tree: ExploredBranch, depth: Int) -> AnyView {
        let node = tree.node
        return AnyView(VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Label(node.endingTitle.map { l($0) } ?? (depth == 0 ? l("故事开始") : l("第 \(depth + 1) 节点", "Scene \(depth + 1)")), systemImage: node.endingTitle == nil ? "circle.fill" : "flag.checkered")
                    .font(.subheadline.bold()).foregroundStyle(.orange)
                Text(l(node.text)).font(.subheadline)
            }.padding(12).frame(maxWidth: .infinity, alignment: .leading).background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            ForEach(Array(tree.exits.enumerated()), id: \.offset) { _, exit in
                let taken = exit.child != nil
                HStack(alignment: .top, spacing: 8) {
                    Rectangle().fill(taken ? Color.orange : Color.secondary.opacity(0.25)).frame(width: 2)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exit.label.prefix(4) + l(String(exit.label.dropFirst(4)))).font(.caption.bold()).foregroundStyle(taken ? .orange : .secondary)
                        if let child = exit.child { branch(child, depth: depth + 1) }
                        else { Label(l("未探索"), systemImage: "lock").font(.subheadline).foregroundStyle(.secondary).padding(.vertical, 8) }
                    }
                }.fixedSize(horizontal: false, vertical: true).padding(.leading, 6)
            }
        })
    }
}
struct EndingLibrary: View {
    @Environment(\.storyLanguage) private var language
    var l: StoryLocalizer { StoryLocalizer(language: language) }
    let state: StoryState
    var total: Int { state.progress.values.reduce(0) { $0 + $1.endings.count } }
    var body: some View {
        List {
            Section { Text(l("已发现 \(total) / \(StoryCatalog.all.reduce(0) { $0 + $1.endingNodes.count }) 个结局", "\(total) / \(StoryCatalog.all.reduce(0) { $0 + $1.endingNodes.count }) endings found")).foregroundStyle(.secondary) }
            ForEach(StoryCatalog.all) { story in
                Section(l(story.title)) {
                    let ids = state.progress[story.id]?.endings ?? []
                    if ids.isEmpty { Text(l("尚未发现结局")).foregroundStyle(.secondary) }
                    ForEach(story.endingNodes.filter { ids.contains($0.id) }, id: \.id) { node in
                        NavigationLink(l(node.endingTitle!)) { EndingDetail(storyTitle: story.title, node: node) }
                    }
                }
            }
        }.tinyPage().navigationTitle(l("结局收藏"))
    }
}
struct EndingDetail: View {
    @Environment(\.storyLanguage) private var language
    var l: StoryLocalizer { StoryLocalizer(language: language) }
    let storyTitle: String
    let node: StoryNode
    var body: some View {
        List { Section(l(storyTitle)) { Text(l(node.text)).font(.body).lineSpacing(6).padding(.vertical, 8) } }
            .tinyPage().navigationTitle(node.endingTitle.map { l($0) } ?? l("结局"))
    }
}
struct ReadingSettings: View {
    @Environment(\.storyLanguage) private var language
    var l: StoryLocalizer { StoryLocalizer(language: language) }
    let order: NextStoryOrder
    let update: (NextStoryOrder) -> Void
    var body: some View {
        List {
            Section {
                Picker(l("换故事顺序"), selection: Binding(get: { order }, set: update)) {
                    ForEach(NextStoryOrder.allCases, id: \.self) { value in Text(l(value.title)).tag(value) }
                }
            } header: { Text(l("桌面阅读")) } footer: {
                Text(l("优先未完成：按目录寻找尚未读完的故事，接着原进度读。按列表顺序：直接进入下一篇。遇到已完成故事会重新开始，已收藏结局保留。"))
            }
            Section(l("外观")) { Text(l("按钮保持橙色，App 外观跟随系统。")) }
            Section(l("本地保存")) { Text(l("设置与进度只保存在这台设备。切换故事不会清空其他故事进度。")) }
        }.tinyPage().navigationTitle(l("阅读设置"))
    }
}
struct HelpView: View {
    @Environment(\.storyLanguage) private var language
    var l: StoryLocalizer { StoryLocalizer(language: language) }
    var body: some View {
        List {
            Section(l("添加小组件")) {
                Text(l("1. 回到主屏幕，长按空白处。"))
                Text(l("2. 点击「编辑」→「添加小组件」。"))
                Text(l("3. 搜索「小小奇遇」，添加中号小组件。"))
                Text(l("正文分页不计入剧情选择，请读完后选择 A/B。"))
            }
            Section(l("开始阅读")) { Text(l("在故事详情中选择要在桌面阅读的故事。返回主屏幕，点击 A 或 B，四次选择后获得结局。结局页可直接点「重新开始」或「换个故事」，无需打开 App。「换个故事」默认优先继续尚未完成的故事；也可在阅读设置中改为按列表顺序。遇到已完成故事会重新开始，收藏不丢失。切换故事会保留各自进度，所有小组件显示同一篇当前故事。")) }
            Section(l("进度与隐私")) { Text(l("故事和进度均保存在本机，不需要联网。重新开始会保留已发现结局和历史旅程。当前不提供云同步或备份，删除 App 后数据可能无法恢复。")) }
        }.tinyPage().navigationTitle(l("桌面阅读指南"))
    }
}

extension Story {
    var symbol: String {
        switch id {
        case "rain-score": return "magnifyingglass"
        case "last-letter": return "envelope"
        case "rain-shop": return "cloud.rain"
        case "moon-post": return "moon.stars"
        case "sea-radio": return "radio"
        default: return "cloud.sun"
        }
    }
}

enum TinyPalette {
    static func adaptive(_ light: UIColor, _ dark: UIColor) -> Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
    static let background = adaptive(UIColor(red: 1, green: 0.99, blue: 0.96, alpha: 1), UIColor(red: 0.13, green: 0.11, blue: 0.15, alpha: 1))
    static let card = adaptive(UIColor(red: 1, green: 0.995, blue: 0.98, alpha: 0.84), UIColor(red: 0.20, green: 0.17, blue: 0.22, alpha: 0.95))
    static let title = adaptive(UIColor(red: 0.56, green: 0.29, blue: 0.30, alpha: 1), UIColor(red: 0.95, green: 0.76, blue: 0.79, alpha: 1))
    static let text = adaptive(UIColor(red: 0.20, green: 0.17, blue: 0.23, alpha: 1), UIColor(red: 0.97, green: 0.94, blue: 0.91, alpha: 1))
    static let border = adaptive(UIColor(red: 0.95, green: 0.72, blue: 0.61, alpha: 0.65), UIColor(red: 0.73, green: 0.52, blue: 0.54, alpha: 0.45))
    static let pink = adaptive(UIColor(red: 1, green: 0.91, blue: 0.94, alpha: 1), UIColor(red: 0.33, green: 0.21, blue: 0.27, alpha: 1))
    static let mint = adaptive(UIColor(red: 0.88, green: 0.97, blue: 0.93, alpha: 1), UIColor(red: 0.19, green: 0.30, blue: 0.27, alpha: 1))
    static let peach = adaptive(UIColor(red: 1, green: 0.78, blue: 0.61, alpha: 1), UIColor(red: 0.42, green: 0.27, blue: 0.19, alpha: 1))
}
struct TinyBackground: View {
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                TinyPalette.background
                Circle().fill(TinyPalette.pink.opacity(0.55)).frame(width: 180, height: 180).offset(x: 70, y: -65)
                Circle().fill(TinyPalette.mint.opacity(0.5)).frame(width: 110, height: 110).position(x: 0, y: geo.size.height * 0.76)
            }.clipped()
        }.ignoresSafeArea().allowsHitTesting(false).accessibilityHidden(true)
    }
}
extension View {
    func tinyCard() -> some View {
        background(TinyPalette.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(TinyPalette.border, lineWidth: 0.75).allowsHitTesting(false))
    }
    func tinyPage() -> some View {
        scrollContentBackground(.hidden).background(TinyBackground())
            .foregroundStyle(TinyPalette.text).toolbar(.visible, for: .navigationBar)
    }
}
struct StoryCover: View {
    let story: Story
    var body: some View {
        GeometryReader { geo in
            Image("cover-" + story.id).resizable().scaledToFill().frame(width: geo.size.width, height: geo.size.height).clipped()
        }.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)).accessibilityHidden(true)
    }
}
struct TinyMenuRow: View {
    let title: String
    let icon: String
    var mint = false
    var subtitle: String? = nil
    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: icon).font(.title3).foregroundStyle(TinyPalette.title)
                .frame(width: 44, height: 48).background(mint ? TinyPalette.mint : TinyPalette.pink, in: RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline).fixedSize(horizontal: false, vertical: true)
                if let subtitle { Text(subtitle).font(.subheadline).foregroundStyle(.secondary) }
            }.frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.secondary)
        }.contentShape(Rectangle())
    }
}

#if DEBUG
@MainActor enum LayoutAudit {
    static func render() throws {
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("LayoutAudit")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var report: [String] = []
        var samples: [(String, StoryState)] = []
        let font = UIFont.systemFont(ofSize: 14)
        let rounded = UIFont(descriptor: font.fontDescriptor.withDesign(.rounded)!, size: 14)
        let paragraph = NSMutableParagraphStyle(); paragraph.lineSpacing = 2
        for language in [StoryLanguage.chinese, .english] {
            for (edition, stories) in [(1, StoryCatalog.legacy), (2, StoryCatalog.all)] {
                for story in stories {
                    for node in story.nodes {
                        var state = StoryState(); state.language = language; state.select(story.id)
                        state.progress[story.id]!.contentVersion = edition
                        state.progress[story.id]!.nodeID = node.id
                        state.progress[story.id]!.choices = Array(repeating: "A", count: node.endingTitle != nil ? 4 : (node.id == "start" ? 0 : 3))
                        for page in state.readingPages.indices {
                            state.widgetPage = page
                            let rect = (state.pageText as NSString).boundingRect(with: CGSize(width: 296, height: 1000), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [.font: rounded, .paragraphStyle: paragraph], context: nil)
                            report.append("\(language.rawValue)/\(edition)/\(story.id)/\(node.id)/\(page): \(ceil(rect.height)) pt")
                            if rect.height > 59 { report.append("OVERFLOW") }
                            if edition == 2 && (story.id == "rain-score" && ["start", "proven", "endA"].contains(node.id) || story.id == "last-letter" && node.id == "start") {
                                samples.append(("\(language.rawValue)-\(story.id)-\(node.id)-\(page)", state))
                            }
                        }
                    }
                }
            }
        }
        try report.joined(separator: "\n").write(to: folder.appendingPathComponent("text-fit.txt"), atomically: true, encoding: .utf8)
        for (name, state) in samples {
            for large in [false, true] {
                let content = WidgetReadingLayout(state: state, backButton: state.pageIndex > 0 ? AnyView(Image(systemName: "chevron.left").frame(width: 28, height: 22)) : nil) {
                    HStack(spacing: 8) {
                        if !state.lastPage {
                            WidgetChoiceLabel(title: state.localizer("下一页") + " · \(state.pageIndex + 1)/\(state.readingPages.count)")
                        } else {
                            WidgetChoiceLabel(title: state.finished ? state.localizer("重新开始") : "A · " + state.localizer(state.options[0]))
                            WidgetChoiceLabel(title: state.finished ? state.localizer("换个故事") : "B · " + state.localizer(state.options[1]), alternate: true)
                        }
                    }
                }.frame(width: 320, height: 155)
                    .background { WidgetCandyBackground() }
                    .environment(\.colorScheme, .light)
                    .environment(\.dynamicTypeSize, large ? .accessibility3 : .large)
                let renderer = ImageRenderer(content: content); renderer.scale = 3
                guard let data = renderer.uiImage?.pngData() else { continue }
                try data.write(to: folder.appendingPathComponent("\(name)-\(large ? "large" : "normal").png"))
            }
        }
    }
}
#endif
