import SwiftUI
import UserNotifications
import WidgetKit

@main
struct TwoXClaudeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                // Force refresh all widgets whenever app comes to foreground
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        requestNotificationPermission()
        scheduleNotifications()
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    func scheduleNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        var cal = Calendar.current
        cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!

        // Schedule notifications for each transition during March 13-27
        // 2x starts at 00:30 IST (19:00 UTC) on weekdays
        // Peak starts at 18:30 IST (13:00 UTC) on weekdays
        // We schedule up to 64 notifications (iOS limit)

        var notifications: [(Date, String, String)] = []
        let utcCal: Calendar = {
            var c = Calendar.current
            c.timeZone = TimeZone(identifier: "UTC")!
            return c
        }()
        let etCal: Calendar = {
            var c = Calendar.current
            c.timeZone = TimeZone(identifier: "America/New_York")!
            return c
        }()

        // Iterate March 13-27
        var day = ClaudeUsage.promotionStartUTC
        while day < ClaudeUsage.promotionEndUTC {
            let wd = etCal.component(.weekday, from: day)
            if wd != 1 && wd != 7 {
                // Peak start: 13:00 UTC this day
                var peakComps = utcCal.dateComponents([.year, .month, .day], from: day)
                peakComps.hour = 13; peakComps.minute = 0; peakComps.timeZone = TimeZone(identifier: "UTC")
                if let peakStart = utcCal.date(from: peakComps), peakStart > Date() {
                    notifications.append((peakStart, "Peak Hours Started", "Normal usage limits now apply. 2x returns at 12:30 AM IST."))
                }
                // 2x start: 19:00 UTC this day
                var twoXComps = utcCal.dateComponents([.year, .month, .day], from: day)
                twoXComps.hour = 19; twoXComps.minute = 0; twoXComps.timeZone = TimeZone(identifier: "UTC")
                if let twoXStart = utcCal.date(from: twoXComps), twoXStart > Date() {
                    notifications.append((twoXStart, "2x Usage Active!", "You now have 2x Claude usage limits."))
                }
            }
            day = utcCal.date(byAdding: .day, value: 1, to: day)!
        }

        for (i, notif) in notifications.prefix(60).enumerated() {
            let content = UNMutableNotificationContent()
            content.title = notif.1
            content.body = notif.2
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: max(1, notif.0.timeIntervalSinceNow),
                repeats: false
            )
            center.add(UNNotificationRequest(identifier: "claude2x_\(i)", content: content, trigger: trigger))
        }
    }
}
