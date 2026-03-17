import SwiftUI

struct ContentView: View {
    @State private var now = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    statusBadge
                    claudeIcon
                    statusTitle
                    countdownView
                    scheduleCard
                    promotionInfo
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .onReceive(timer) { _ in now = Date() }
    }

    // MARK: - Status Badge
    var statusBadge: some View {
        let active = ClaudeUsage.is2xActive(at: now)
        return Text(ClaudeUsage.statusLabel(at: now))
            .font(.system(size: 14, weight: .bold, design: .monospaced))
            .tracking(2)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(active
                        ? LinearGradient(colors: [.red, .orange, .yellow, .green, .blue, .purple],
                                         startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [.gray, .gray.opacity(0.6)],
                                         startPoint: .leading, endPoint: .trailing))
            )
    }

    // MARK: - Claude Icon
    var claudeIcon: some View {
        Text("\u{1F9F1}")
            .font(.system(size: 80))
            .padding(.top, 20)
    }

    // MARK: - Status Title
    var statusTitle: some View {
        let active = ClaudeUsage.is2xActive(at: now)
        return VStack(spacing: 4) {
            if ClaudeUsage.isPromotionActive(at: now) {
                HStack(spacing: 0) {
                    Text("2x ")
                        .foregroundColor(.orange)
                    Text("Usage")
                        .foregroundColor(.yellow)
                }
                .font(.system(size: 36, weight: .bold))
            } else {
                Text("Promotion Ended")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.gray)
            }

            if active {
                Text("ACTIVE NOW")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.green)
            } else if ClaudeUsage.isPromotionActive(at: now) {
                Text("PEAK HOURS - Normal Limits")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.orange)
            }
        }
    }

    // MARK: - Countdown
    var countdownView: some View {
        VStack(spacing: 8) {
            if let t = ClaudeUsage.timeUntilNextTransition(from: now) {
                HStack(spacing: 4) {
                    timeBlock(String(format: "%02d", t.hours))
                    Text(":").font(.system(size: 40, weight: .bold, design: .monospaced)).foregroundColor(.white)
                    timeBlock(String(format: "%02d", t.minutes))
                    Text(":").font(.system(size: 40, weight: .bold, design: .monospaced)).foregroundColor(.white)
                    timeBlock(String(format: "%02d", t.seconds))
                }
                Text(t.to2x ? "until 2x usage" : "until peak hours")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
            } else {
                Text("Promotion has ended")
                    .foregroundColor(.gray)
            }
        }
    }

    func timeBlock(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 44, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
    }

    // MARK: - Schedule Card
    var scheduleCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekday Schedule (IST)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            // Timeline bar
            timelineBar

            // Legend
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.orange).frame(width: 4, height: 28)
                    VStack(alignment: .leading) {
                        Text("Peak Hours").font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                        Text("Weekdays 18:30 – 00:30 IST").font(.system(size: 13)).foregroundColor(.gray)
                    }
                }
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.green).frame(width: 4, height: 28)
                    VStack(alignment: .leading) {
                        Text("2x Usage").font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                        Text("Outside peak + all weekends").font(.system(size: 13)).foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.08)))
    }

    var timelineBar: some View {
        GeometryReader { geo in
            let w = geo.size.width
            // 24h bar: 0:00 to 24:00
            // 2x: 0:30 (0.0208) to 18:30 (0.7708)
            // Peak: 0:00-0:30 and 18:30-24:00
            ZStack(alignment: .leading) {
                // Background (peak = orange)
                RoundedRectangle(cornerRadius: 4).fill(Color.orange).frame(height: 8)
                // 2x portion (green)
                RoundedRectangle(cornerRadius: 4).fill(Color.green)
                    .frame(width: w * (18.0 / 24.0 - 0.5 / 24.0), height: 8)
                    .offset(x: w * (0.5 / 24.0))

                // Current time indicator
                let istHour = currentISTHour()
                Circle().fill(Color.white).frame(width: 12, height: 12)
                    .offset(x: w * CGFloat(istHour / 24.0) - 6)
            }

            // Time labels
            HStack {
                Text("12am").font(.system(size: 10)).foregroundColor(.gray)
                Spacer()
                Text("6am").font(.system(size: 10)).foregroundColor(.gray)
                Spacer()
                Text("12pm").font(.system(size: 10)).foregroundColor(.gray)
                Spacer()
                Text("6pm").font(.system(size: 10)).foregroundColor(.gray)
                Spacer()
                Text("12am").font(.system(size: 10)).foregroundColor(.gray)
            }
            .offset(y: 14)
        }
        .frame(height: 30)
    }

    func currentISTHour() -> Double {
        var cal = Calendar.current
        cal.timeZone = ClaudeUsage.ist
        let h = cal.component(.hour, from: now)
        let m = cal.component(.minute, from: now)
        return Double(h) + Double(m) / 60.0
    }

    // MARK: - Promotion Info
    var promotionInfo: some View {
        VStack(spacing: 8) {
            Text("Spring Break for Claude Code")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            Text(ClaudeUsage.promotionDateRange)
                .font(.system(size: 14))
                .foregroundColor(.gray)

            if !ClaudeUsage.isPromotionActive(at: now) {
                Text("This promotion has ended.")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
                    .padding(.top, 4)
            } else {
                let daysLeft = daysRemaining()
                Text("\(daysLeft) days remaining")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
                    .padding(.top, 4)
            }
        }
        .padding(.top, 12)
    }

    func daysRemaining() -> Int {
        let diff = Calendar.current.dateComponents([.day], from: now, to: ClaudeUsage.promotionEndUTC)
        return max(0, diff.day ?? 0)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
