# 小小奇遇 · TinyStory

在桌面上读一段故事，做一个选择。小小奇遇是一款以交互式小组件为主要入口的分支故事 App：每篇故事经过四次选择到达结局，几分钟就能完成一次奇遇。

Read a little, make a choice, and see where it leads. TinyStory is a branching-story app built around an interactive Home Screen widget. Four choices take you to an ending, making each story a short break in your day.

## 功能 / Features

- 六篇故事，每篇四个结局，包括探案故事《雨夜失踪的曲谱》。
- 直接在小组件中选择 A/B，结束后可以重玩或换故事。
- 主 App 提供故事库、独立进度、结局收藏、历史旅程和已探索的分支。
- 支持中文、英文和跟随系统语言。长正文分页显示，读完后再做选择。
- 进度保存在本地，App 与 Widget 共享，离线可玩。

- Six stories with four endings each, including a mystery about a missing musical score.
- Make A/B choices in the widget, then replay or switch stories when you finish.
- Browse the library, keep separate progress for each story, collect endings, and revisit your choices and explored branches.
- Read in Chinese or English, or follow the system language. Longer passages are paginated before choices appear.
- Play offline, with progress stored locally and shared between the app and widget.

## 项目结构 / Project structure

- Sources/StoryApp.swift：主 App 页面、样式和导航。
- Sources/StoryWidget.swift：Widget 入口、App Intents。
- Sources/WidgetReadingLayout.swift：共享小组件布局。
- Sources/Story.swift：故事、进度、存储与分支模型。
- Sources/StoryContent.swift：加载故事资源，校验节点和翻译，兼容历史快照。
- Sources/StoryLanguage.swift：语言选择、界面本地化与正文分页。
- Resources/Stories：六篇故事的中英文内容和分支；Legacy 保存旧版本内容。
- Resources/Localizable.xcstrings：界面文字的中英文翻译。
- Resources/StoryArt.xcassets：故事封面与 App 图标。
- AppInfo.plist、WidgetInfo.plist、Shared.entitlements：应用与扩展配置。

The Swift sources cover the app screens, widget actions and layout, story state, persistence, and translation. Resources contains the story covers and localization files.

## 运行 / Run

使用 Xcode 打开 `TinyStory.xcodeproj`，选择 `StoryApp`，运行到 iPhone 或模拟器。首次启动后，在桌面添加中号小组件即可开始阅读。

真机运行需要为 App 和 Widget 配置签名，并使用同一个 App Group。使用自己的开发者账号时，需要同步调整工程标识、共享组权限和 `StoryStore.group`。

Open `TinyStory.xcodeproj` in Xcode, select `StoryApp`, and run on an iPhone or simulator. Launch the app once, then add a medium widget to the Home Screen.

For a physical device, configure signing for both targets and use the same App Group. When using your own developer account, update the bundle identifiers, App Group entitlement, and `StoryStore.group` together.

## 实现 / Implementation

使用 Swift、SwiftUI、WidgetKit 和 App Intents，无第三方依赖。主 App 负责故事与进度管理，小组件负责阅读和选择。共享存档使用文件锁和原子写入，操作时检查轮次、节点与页码，避免旧按钮重复推进剧情。

Built with Swift, SwiftUI, WidgetKit, and App Intents, with no third-party dependencies. The app manages stories and progress; the widget handles reading and choices. Shared saves use file locking and atomic writes. Actions check the current run, node, and page to prevent stale buttons from advancing the story again.

## 编辑故事 / Editing stories

每篇故事使用一个 JSON 文件，中英文写在同一个节点里，共用分支关系：

| 文件 / File | 故事 / Story |
| --- | --- |
| `Resources/Stories/last-letter.json` | 末班来信 / The Last Letter |
| `Resources/Stories/rain-shop.json` | 借雨小店 |
| `Resources/Stories/moon-post.json` | 月亮邮差 |
| `Resources/Stories/sea-radio.json` | 海边电台 |
| `Resources/Stories/cloud-tailor.json` | 补云的人 |
| `Resources/Stories/rain-score.json` | 雨夜失踪的曲谱 |

`title`、`summary`、节点正文和选项标题都包含 `zh-Hans` 与 `en`。节点使用固定 `id`，选项的 `next` 指向下一个节点。`catalog.json` 决定书架顺序。调整文案时同步校对两种语言；不要随意修改现有 ID 或旧版文件，否则会影响存档。

Each JSON file holds both languages and one shared branching graph. Text fields contain `zh-Hans` and `en`; option destinations refer to stable node IDs. `catalog.json` controls library order. Keep both languages in sync and preserve existing IDs and legacy content for saved progress.

`Stories/Legacy/` 保留第一版五篇故事；其中 `snapshot-translations.json` 保存历史正文的英文对应，用于回顾旧旅程。界面按钮、标签等在 Xcode 的 `Localizable.xcstrings` 中编辑。JSON 修改后需重新构建，App 与 Widget 都会打包同一份内容。

`Stories/Legacy/` preserves the five first-edition stories. Its `snapshot-translations.json` keeps translations for historical journey text. Edit interface labels in `Localizable.xcstrings`. Rebuild after changing resources; both targets bundle the same story content.
