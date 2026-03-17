import WidgetKit
import SwiftUI

struct TwoXEntry: TimelineEntry {
    let date: Date
    let is2x: Bool
    let isPromoActive: Bool
    let transitionDate: Date? // when status next changes
    let statusText: String
}

struct TwoXProvider: TimelineProvider {
    func placeholder(in context: Context) -> TwoXEntry {
        TwoXEntry(date: Date(), is2x: true, isPromoActive: true,
                  transitionDate: Date().addingTimeInterval(3600 * 8),
                  statusText: "2x Usage")
    }

    func getSnapshot(in context: Context, completion: @escaping (TwoXEntry) -> Void) {
        completion(makeEntry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TwoXEntry>) -> Void) {
        let now = Date()
        var entries: [TwoXEntry] = []

        // Entry for right now
        entries.append(makeEntry(for: now))

        // Create entries at each transition point so status/gradient flips instantly
        var cursor = now
        for _ in 0..<10 {
            guard let (nextDate, _) = ClaudeUsage.nextTransition(from: cursor),
                  nextDate < now.addingTimeInterval(86400 * 2) else { break }
            // Entry right at the transition
            entries.append(makeEntry(for: nextDate))
            // Also one second after to ensure the flip renders
            entries.append(makeEntry(for: nextDate.addingTimeInterval(1)))
            cursor = nextDate.addingTimeInterval(1)
        }

        // Determine refresh policy: refresh right at the next transition
        // so WidgetKit requests a new timeline then
        if let (nextDate, _) = ClaudeUsage.nextTransition(from: now) {
            completion(Timeline(entries: entries, policy: .after(nextDate)))
        } else {
            // Promotion over — refresh once per day
            completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(86400))))
        }
    }

    func makeEntry(for date: Date) -> TwoXEntry {
        let active = ClaudeUsage.is2xActive(at: date)
        let promoActive = ClaudeUsage.isPromotionActive(at: date)
        let transition = ClaudeUsage.nextTransition(from: date)
        let status = active ? "2x Usage" : (promoActive ? "Peak Hours" : "Ended")
        return TwoXEntry(date: date, is2x: active, isPromoActive: promoActive,
                         transitionDate: transition?.date, statusText: status)
    }
}

// MARK: - Gradient helper
func widgetGradient(is2x: Bool) -> LinearGradient {
    LinearGradient(
        colors: is2x
            ? [.red, .orange, .yellow, .green, .blue, .purple]
            : [.gray, .gray.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Small Widget
struct TwoXWidgetSmall: View {
    let entry: TwoXEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Claude")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))

            Spacer()

            Text(entry.statusText)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            if entry.isPromoActive, let target = entry.transitionDate {
                // Live countdown — system updates this automatically
                Text("Changes in ")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                +
                Text(target, style: .relative)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Medium Widget
struct TwoXWidgetMedium: View {
    let entry: TwoXEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Claude")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))

                Text(entry.statusText)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                if entry.isPromoActive, let target = entry.transitionDate {
                    Text("Changes in ")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    +
                    Text(target, style: .relative)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            Spacer()

            if entry.isPromoActive {
                Text(entry.is2x ? "2x" : "1x")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Lock Screen Widgets
struct TwoXLockScreenCircular: View {
    let entry: TwoXEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Text(entry.is2x ? "2x" : "1x")
                    .font(.system(size: 20, weight: .heavy))
                if let target = entry.transitionDate {
                    Text(target, style: .timer)
                        .font(.system(size: 9))
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

struct TwoXLockScreenRectangular: View {
    let entry: TwoXEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Claude \(entry.statusText)")
                .font(.system(size: 14, weight: .bold))
            if let target = entry.transitionDate {
                Text("Changes in ")
                    .font(.system(size: 12))
                +
                Text(target, style: .relative)
                    .font(.system(size: 12))
            }
        }
    }
}

struct TwoXLockScreenInline: View {
    let entry: TwoXEntry

    var body: some View {
        if let target = entry.transitionDate {
            Text("Claude \(entry.statusText) | ")
            +
            Text(target, style: .relative)
        } else {
            Text("Claude: \(entry.statusText)")
        }
    }
}

// MARK: - Widget Configuration
struct TwoXClaudeWidget: Widget {
    let kind = "TwoXClaudeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TwoXProvider()) { entry in
            if #available(iOS 17.0, *) {
                TwoXWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        widgetGradient(is2x: entry.is2x)
                    }
            } else {
                TwoXWidgetEntryView(entry: entry)
                    .background(widgetGradient(is2x: entry.is2x))
            }
        }
        .configurationDisplayName("Claude Usage")
        .description("Shows whether Claude is currently offering 2x usage.")
        .supportedFamilies([.systemSmall, .systemMedium,
                            .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct TwoXWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: TwoXEntry

    var body: some View {
        switch family {
        case .systemSmall:
            TwoXWidgetSmall(entry: entry)
        case .systemMedium:
            TwoXWidgetMedium(entry: entry)
        case .accessoryCircular:
            TwoXLockScreenCircular(entry: entry)
        case .accessoryRectangular:
            TwoXLockScreenRectangular(entry: entry)
        case .accessoryInline:
            TwoXLockScreenInline(entry: entry)
        default:
            TwoXWidgetSmall(entry: entry)
        }
    }
}

@main
struct TwoXWidgetBundle: WidgetBundle {
    var body: some Widget {
        TwoXClaudeWidget()
    }
}
