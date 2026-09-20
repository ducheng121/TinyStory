# 小小奇遇 · TinyStory

在桌面上读一段故事，做一个选择。每篇故事经过四次选择到达结局，适合在零碎时间里玩一会儿。

Read a little, make a choice, and see where it leads. Each story takes four choices to reach an ending, right from your Home Screen.

## 这一版 / This version

- 5 篇中文分支故事，每篇 4 个结局。
- 在 Widget 中选择 A/B，结局后直接重玩或换故事。
- 主 App 管理故事、独立进度和已解锁结局，查看历史旅程与已探索的分支。
- 进度保存在本地，App 与 Widget 共享，无需联网。

- Five branching stories in Chinese, with four endings each.
- Make A/B choices in the widget, then replay or switch stories when you finish.
- Use the app to choose a story, manage progress, collect endings, and revisit your choices and explored branches.
- Progress is stored locally and shared between the app and widget. No internet connection needed.

## 接下来 / Next steps

先把桌面阅读和选择的体验打磨好，再尝试更有探案感的故事和轻松一点的视觉风格。

Refine reading and choices on the Home Screen, then explore a mystery story and a more playful visual style.

## 运行 / Run

使用 Xcode 打开 `TinyStory.xcodeproj`，选择 `StoryApp`。真机运行前，在两个 Target 中配置自己的签名团队，并同步修改 App Group 标识。启动 App 后，在桌面添加中号小组件。

Open `TinyStory.xcodeproj` in Xcode and select `StoryApp`. For a physical device, configure signing for both targets and update the App Group identifier in the entitlements and source code to match your setup. Launch the app, then add a medium widget to your Home Screen.

Swift / SwiftUI / WidgetKit / App Intents；无第三方依赖。

Built with Swift, SwiftUI, WidgetKit, and App Intents. No third-party dependencies.

## 文件 / Files

| 路径 / Path | 用途 / Purpose |
| --- | --- |
| `Sources/Story.swift` | 故事、分支与存档 / Stories, branching, and persistence |
| `Sources/StoryApp.swift` | 主 App 页面 / App screens |
| `Sources/StoryWidget.swift` | Widget 刷新与交互 / Widget updates and actions |
| `Sources/WidgetReadingLayout.swift` | Widget 排版 / Widget layout |
| `TinyStory.xcodeproj/` | Xcode 工程 / Xcode project |
| `AppInfo.plist`, `WidgetInfo.plist` | App 与扩展配置 / App and extension configuration |
| `Shared.entitlements` | 共享存储权限 / Shared storage entitlement |
