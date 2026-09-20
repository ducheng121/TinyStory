import SwiftUI

// 蜜桃汽水：native shapes, no image assets or additional dependencies.
// 蜜桃汽水：使用原生图形绘制，不依赖图片资源或额外依赖。
struct WidgetCandyBackground: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        GeometryReader { geo in
            ZStack {
                (scheme == .dark ? Color(red: 0.16, green: 0.12, blue: 0.19) : Color(red: 1, green: 0.97, blue: 0.88))
                Circle().fill(Color.pink.opacity(scheme == .dark ? 0.12 : 0.13))
                    .frame(width: 92, height: 92).position(x: geo.size.width - 4, y: 2)
                Circle().fill(Color.mint.opacity(scheme == .dark ? 0.09 : 0.14))
                    .frame(width: 68, height: 68).position(x: 0, y: geo.size.height + 8)
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(scheme == .dark
                        ? Color(red: 0.80, green: 0.60, blue: 0.66).opacity(0.45)
                        : Color(red: 0.78, green: 0.58, blue: 0.49).opacity(0.50), lineWidth: 0.75)
                    .padding(4)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }.clipped()
        }
    }
}
struct WidgetChoiceLabel: View {
    let title: String
    var alternate = false
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        Text(title).font(.system(size: 13, weight: .bold, design: .rounded))
            .lineLimit(2).multilineTextAlignment(.center).minimumScaleFactor(0.9)
            .frame(maxWidth: .infinity, minHeight: 36)
            .foregroundStyle(.orange)
            .background {
                RoundedRectangle(cornerRadius: 14).fill(fillColor)
                    .shadow(color: Color.orange.opacity(scheme == .dark ? 0.08 : 0.14), radius: 0, x: 0, y: 2)
            }
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(scheme == .dark ? 0.15 : 0.8), lineWidth: 1))
    }
    var fillColor: Color {
        scheme == .dark
        ? (alternate ? Color(red: 0.17, green: 0.29, blue: 0.26) : Color(red: 0.34, green: 0.19, blue: 0.26))
        : (alternate ? Color(red: 0.78, green: 0.94, blue: 0.84) : Color(red: 1, green: 0.82, blue: 0.87))
    }

}
struct WidgetReadingLayout<Actions: View>: View {
    let state: StoryState
    var backButton: AnyView? = nil
    @ViewBuilder var actions: () -> Actions
    @ScaledMetric(relativeTo: .body) private var readingSize = 15.0
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ViewThatFits(in: .vertical) {
                content(size: min(18, max(15, readingSize)))
                content(size: 15)
                content(size: 14)
            }
            Spacer(minLength: 8)
            actions().buttonStyle(.plain)
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).padding(12)
    }
    func content(size: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: state.finished ? "sparkles" : "face.smiling.fill")
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(.orange)
                    .accessibilityHidden(true)
                Text(state.localizer(state.finished && (state.language ?? .system).resolved() == .english ? state.ending : state.story.title)).font(.system(size: 12, weight: .bold, design: .rounded))
                if let backButton { backButton }
                Spacer(minLength: 4)
                Text(state.finished ? ((state.language ?? .system).resolved() == .english ? "✓" : state.ending) : "\(state.step + 1) / 4")
                    .font(.system(size: 11, weight: .bold, design: .rounded)).monospacedDigit()
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(scheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.8), in: Capsule())
            }.minimumScaleFactor(0.75).foregroundStyle(scheme == .dark ? Color(red: 0.94, green: 0.80, blue: 0.85) : Color(red: 0.53, green: 0.29, blue: 0.30)).lineLimit(1)
            Text(state.pageText).font(.system(size: size, design: .rounded)).lineSpacing(2)
                .foregroundStyle(scheme == .dark ? Color(red: 0.98, green: 0.94, blue: 0.90) : Color(red: 0.26, green: 0.20, blue: 0.24))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
        }
    }
}
