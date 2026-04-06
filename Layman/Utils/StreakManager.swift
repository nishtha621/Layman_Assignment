import Foundation

// MARK: - StreakManager

/// Tracks daily reading streaks using UserDefaults.
/// A streak increments when the user opens the app on consecutive calendar days.
/// Missing a day resets the streak to 1 (today counts as day 1).
final class StreakManager {

    static let shared = StreakManager()
    private init() { updateStreak() }

    private let lastOpenKey = "streak_last_open_date"
    private let countKey    = "streak_count"

    // MARK: - Current Streak

    var currentStreak: Int {
        UserDefaults.standard.integer(forKey: countKey)
    }

    // MARK: - Update on App Open

    func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        let defaults = UserDefaults.standard

        if let lastData = defaults.object(forKey: lastOpenKey) as? Date {
            let lastDay = Calendar.current.startOfDay(for: lastData)
            let days = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0

            switch days {
            case 0:
                break           // Same day — no change
            case 1:
                defaults.set(currentStreak + 1, forKey: countKey)  // +1 consecutive day
            default:
                defaults.set(1, forKey: countKey)                   // Streak broken — reset to 1
            }
        } else {
            defaults.set(1, forKey: countKey)   // First time ever — start at 1
        }

        defaults.set(Date(), forKey: lastOpenKey)
    }
}
