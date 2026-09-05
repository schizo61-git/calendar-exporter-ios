import EventKit
import Foundation

/// EventKitへのアクセスをまとめる。読み取り専用: save/remove は絶対に呼ばない
/// (仕様書 13章「安全性」)。
@MainActor
final class CalendarStore: ObservableObject {
    private let eventStore = EKEventStore()

    @Published var authorizationStatus: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)
    @Published var calendarOptions: [CalendarOption] = []
    @Published var errorMessage: String?

    var isAuthorized: Bool {
        authorizationStatus == .fullAccess
    }

    func requestAccessIfNeeded() async {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        if authorizationStatus == .fullAccess {
            loadCalendars()
            return
        }
        await requestAccess()
    }

    func requestAccess() async {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
            if granted {
                errorMessage = nil
                loadCalendars()
            } else {
                errorMessage = "カレンダーへのアクセスが許可されませんでした。設定アプリの「プライバシーとセキュリティ」→「カレンダー」から許可してください。"
            }
        } catch {
            errorMessage = "アクセス要求でエラーが発生しました: \(error.localizedDescription)"
        }
    }

    func loadCalendars() {
        calendarOptions = eventStore.calendars(for: .event)
            .map(CalendarOption.init)
            .sorted {
                $0.displayName.localizedCompare($1.displayName) == .orderedAscending
            }
    }

    /// 指定期間・カレンダーのイベントをバックグラウンドで取得し、開始日時順に返す。
    /// (仕様書 6章: UIスレッドを長時間ブロックしない)
    func fetchEvents(calendar: EKCalendar, start: Date, end: Date) async -> [EKEvent] {
        let store = eventStore
        return await Task.detached(priority: .userInitiated) {
            let predicate = store.predicateForEvents(withStart: start, end: end, calendars: [calendar])
            let events = store.events(matching: predicate)
            return events.sorted { $0.startDate < $1.startDate }
        }.value
    }
}
