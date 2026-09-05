import EventKit
import Foundation

/// EKEventの配列をRFC 4180準拠のCSV(UTF-8 BOM付き)へ変換する。
/// (仕様書 7章)
enum CSVExporter {
    private static let header = [
        "calendar_source", "calendar_name", "title", "start_date", "end_date",
        "is_all_day", "location", "notes", "url", "time_zone",
        "event_identifier", "calendar_item_external_identifier", "is_detached",
    ].joined(separator: ",")

    private static let bom: [UInt8] = [0xEF, 0xBB, 0xBF]

    static func makeCSV(events: [EKEvent]) -> Data {
        var lines = [header]

        for event in events {
            let zone = event.timeZone ?? TimeZone.current
            let formatter = ISO8601DateFormatter()
            formatter.timeZone = zone
            formatter.formatOptions = [.withInternetDateTime]

            let fields = [
                event.calendar?.source?.title ?? "",
                event.calendar?.title ?? "",
                event.title ?? "",
                formatter.string(from: event.startDate),
                formatter.string(from: event.endDate),
                event.isAllDay ? "true" : "false",
                event.location ?? "",
                event.notes ?? "",
                event.url?.absoluteString ?? "",
                zone.identifier,
                event.eventIdentifier ?? "",
                event.calendarItemExternalIdentifier ?? "",
                event.isDetached ? "true" : "false",
            ]
            lines.append(fields.map(escape).joined(separator: ","))
        }

        let text = lines.joined(separator: "\r\n") + "\r\n"
        var data = Data(bom)
        data.append(text.data(using: .utf8) ?? Data())
        return data
    }

    private static func escape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }
}
