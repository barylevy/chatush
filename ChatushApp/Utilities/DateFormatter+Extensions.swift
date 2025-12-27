import Foundation

enum ConversationDateFormatter {
    static func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        // Check if today
        if calendar.isDateInToday(date) {
            return date.formatted(date: .omitted, time: .shortened)
        }

        // Check if within last 7 days
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        if date > weekAgo {
            return date.formatted(.dateTime.weekday(.wide))
        }

        // Older than a week - show only date
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}
