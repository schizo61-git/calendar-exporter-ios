import EventKit

/// Picker表示用に EKCalendar をラップする。
/// 表示名は「Source名 / Calendar名」形式(仕様書 05章)。
struct CalendarOption: Identifiable, Hashable {
    let id: String
    let calendar: EKCalendar

    init(calendar: EKCalendar) {
        self.calendar = calendar
        self.id = calendar.calendarIdentifier
    }

    var sourceTitle: String { calendar.source?.title ?? "不明なソース" }
    var calendarTitle: String { calendar.title }
    var displayName: String { "\(sourceTitle) / \(calendarTitle)" }

    static func == (lhs: CalendarOption, rhs: CalendarOption) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
