import Foundation

struct ClaudeUsage {
    static let ist = TimeZone(identifier: "Asia/Kolkata")!
    static let et = TimeZone(identifier: "America/New_York")!
    static let utc = TimeZone(identifier: "UTC")!

    // Promotion: March 13-27, 2026
    static let promotionStartUTC: Date = {
        var c = DateComponents()
        c.year = 2026; c.month = 3; c.day = 13; c.hour = 0; c.minute = 0
        c.timeZone = TimeZone(identifier: "America/New_York")!
        return Calendar.current.date(from: c)!
    }()

    static let promotionEndUTC: Date = {
        var c = DateComponents()
        c.year = 2026; c.month = 3; c.day = 28; c.hour = 0; c.minute = 0
        c.timeZone = TimeZone(identifier: "America/New_York")!
        return Calendar.current.date(from: c)!
    }()

    static func isPromotionActive(at date: Date = Date()) -> Bool {
        date >= promotionStartUTC && date < promotionEndUTC
    }

    /// Peak hours: 13:00-19:00 UTC on ET weekdays (= 6:30 PM - 12:30 AM IST)
    static func isPeak(at date: Date = Date()) -> Bool {
        guard isPromotionActive(at: date) else { return false }

        var etCal = Calendar.current
        etCal.timeZone = et
        let weekday = etCal.component(.weekday, from: date)
        if weekday == 1 || weekday == 7 { return false }

        var utcCal = Calendar.current
        utcCal.timeZone = utc
        let hour = utcCal.component(.hour, from: date)
        return hour >= 13 && hour < 19
    }

    static func is2xActive(at date: Date = Date()) -> Bool {
        guard isPromotionActive(at: date) else { return false }
        return !isPeak(at: date)
    }

    /// Returns (nextTransitionDate, willBe2x) or nil if promotion is over
    static func nextTransition(from date: Date = Date()) -> (date: Date, to2x: Bool)? {
        guard isPromotionActive(at: date) else { return nil }

        let currentlyPeak = isPeak(at: date)

        var utcCal = Calendar.current
        utcCal.timeZone = utc
        var etCal = Calendar.current
        etCal.timeZone = et

        if currentlyPeak {
            // Peak ends at 19:00 UTC today
            var comps = utcCal.dateComponents([.year, .month, .day], from: date)
            comps.hour = 19; comps.minute = 0; comps.second = 0
            comps.timeZone = utc
            if let next = utcCal.date(from: comps), next > date, isPromotionActive(at: next) {
                return (next, true)
            }
        }

        // Currently 2x — find next peak start: 13:00 UTC on next ET weekday
        var check = date
        for _ in 0..<20 {
            var comps = utcCal.dateComponents([.year, .month, .day], from: check)
            comps.hour = 13; comps.minute = 0; comps.second = 0
            comps.timeZone = utc
            if let candidate = utcCal.date(from: comps), candidate > date {
                let wd = etCal.component(.weekday, from: candidate)
                if wd != 1 && wd != 7 {
                    if isPromotionActive(at: candidate) {
                        return (candidate, false)
                    } else {
                        return nil // Promotion ends before next peak
                    }
                }
            }
            check = utcCal.date(byAdding: .day, value: 1, to: check)!
        }
        return nil
    }

    static func timeUntilNextTransition(from date: Date = Date()) -> (hours: Int, minutes: Int, seconds: Int, to2x: Bool)? {
        guard let (next, to2x) = nextTransition(from: date) else { return nil }
        let diff = Int(next.timeIntervalSince(date))
        let h = diff / 3600
        let m = (diff % 3600) / 60
        let s = diff % 60
        return (h, m, s, to2x)
    }

    /// Status text for display
    static func statusLabel(at date: Date = Date()) -> String {
        if !isPromotionActive(at: date) { return "Promotion Ended" }
        return is2xActive(at: date) ? "2x ACTIVE" : "PEAK HOURS"
    }

    /// "until peak hours" or "until 2x usage"
    static func countdownLabel(at date: Date = Date()) -> String {
        guard let (_, to2x) = nextTransition(from: date) else { return "Promotion ending" }
        return to2x ? "until peak hours" : "until 2x usage"
    }

    // IST display times for schedule card
    static let peakHoursIST = "18:30 – 00:30"
    static let twoXHoursIST = "00:30 – 18:30"
    static let promotionDateRange = "March 13 – 27, 2026"
}
