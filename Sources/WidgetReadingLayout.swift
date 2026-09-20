import SwiftUI

struct WidgetChoiceLabel: View {
    let title: String
    var body: some View {
        Text(title).font(.system(size: 13, weight: .semibold))
            .lineLimit(1).minimumScaleFactor(0.9)
            .frame(maxWidth: .infinity, minHeight: 36)
            .foregroundStyle(.orange)
            .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }
}
struct WidgetReadingLayout<Actions: View>: View {
    let state: StoryState
    @ViewBuilder var actions: () -> Actions
    @ScaledMetric(relativeTo: .body) private var readingSize = 15.0
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 优先使用阅读字号，空间不足时尝试更小字号。
            ViewThatFits(in: .vertical) {
                content(size: min(18, max(15, readingSize)))
                content(size: 15)
                content(size: 14)
            }
            // 将操作区留在底部，避免短正文时按钮跟着文字上移。
            Spacer(minLength: 8)
            actions().buttonStyle(.plain)
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).padding(12)
    }
    func content(size: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(state.story.title).font(.system(size: 12, weight: .semibold))
                Spacer(minLength: 4)
                Text(state.finished ? state.ending : "\(state.step + 1) / 4").font(.system(size: 12)).monospacedDigit()
            }.foregroundStyle(.secondary).lineLimit(1)
            Text(state.text).font(.system(size: size)).lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
        }
    }
}
