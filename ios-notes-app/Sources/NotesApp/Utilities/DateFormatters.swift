import Foundation

enum DateFormatters {

    /// "Mon 28 Mar 2026, 09:41"
    static let full: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE d MMM yyyy, HH:mm"
        return f
    }()

    /// "09:41" — time only
    static let time: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    /// "28 Mar" — short date for week view columns
    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return f
    }()

    /// "March 2026" — month + year for month view header
    static let monthYear: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    /// "Mon" — abbreviated weekday
    static let weekday: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    /// Relative: "Just now", "2 min ago", "Yesterday", then falls back to full
    static func relative(_ date: Date) -> String {
        let now = Date()
        let diff = now.timeIntervalSince(date)
        if diff < 60 { return "Just now" }
        if diff < 3600 { return "\(Int(diff / 60)) min ago" }
        if Calendar.current.isDateInToday(date) { return "Today, \(time.string(from: date))" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday, \(time.string(from: date))" }
        return full.string(from: date)
    }

    /// Returns an array of Date values for the 7 days of the week containing `date`
    static func week(containing date: Date) -> [Date] {
        let cal = Calendar.current
        guard let start = cal.dateInterval(of: .weekOfYear, for: date)?.start else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    /// Returns the start and end of the given day
    static func dayBounds(for date: Date) -> (start: Date, end: Date) {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        return (start, end)
    }
}
