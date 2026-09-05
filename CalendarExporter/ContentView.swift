import EventKit
import SwiftUI
import UniformTypeIdentifiers

enum ExportFormat: String, CaseIterable, Identifiable {
    case csv = "CSV"
    case json = "JSON"
    var id: String { rawValue }
}

struct ContentView: View {
    @StateObject private var store = CalendarStore()

    @State private var selectedCalendarID: String?
    @State private var startDate = ContentView.defaultStart
    @State private var endDate = ContentView.defaultEnd
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var fetchedEvents: [EKEvent] = []

    @State private var exportFormat: ExportFormat = .csv
    @State private var isExporting = false
    @State private var exportDocument: ExportDocument?
    @State private var exportFilename = ""
    @State private var completionMessage: String?
    @State private var alertMessage: String?

    private static var defaultStart: Date {
        Calendar.current.date(from: DateComponents(year: 2000, month: 1, day: 1)) ?? .distantPast
    }

    private static var defaultEnd: Date {
        Calendar.current.date(from: DateComponents(year: 2040, month: 12, day: 31)) ?? .distantFuture
    }

    private var selectedCalendar: EKCalendar? {
        store.calendarOptions.first { $0.id == selectedCalendarID }?.calendar
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.isAuthorized {
                    mainForm
                } else {
                    permissionView
                }
            }
            .navigationTitle("Calendar Exporter")
        }
        .task {
            await store.requestAccessIfNeeded()
            if selectedCalendarID == nil {
                selectedCalendarID = store.calendarOptions.first?.id
            }
        }
        .onChange(of: store.calendarOptions) { _, options in
            if selectedCalendarID == nil {
                selectedCalendarID = options.first?.id
            }
        }
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .commaSeparatedText,
            defaultFilename: exportFilename
        ) { result in
            switch result {
            case .success:
                completionMessage = "\(fetchedEvents.count)件を書き出しました"
            case .failure(let error):
                alertMessage = "書き出しに失敗しました: \(error.localizedDescription)"
            }
        }
        .alert(
            "エラー",
            isPresented: Binding(
                get: { alertMessage != nil },
                set: { if !$0 { alertMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private var permissionView: some View {
        VStack(spacing: 16) {
            Text("カレンダーへのアクセスが必要です")
                .font(.headline)
            if let message = store.errorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            Button("アクセスを許可する") {
                Task { await store.requestAccess() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var mainForm: some View {
        Form {
            Section("対象カレンダー") {
                Picker("カレンダー", selection: $selectedCalendarID) {
                    ForEach(store.calendarOptions) { option in
                        Text(option.displayName).tag(Optional(option.id))
                    }
                }
            }

            Section("期間") {
                DatePicker("開始日", selection: $startDate, displayedComponents: .date)
                DatePicker("終了日", selection: $endDate, displayedComponents: .date)
            }

            Section {
                Button {
                    Task { await search() }
                } label: {
                    if isSearching {
                        ProgressView()
                    } else {
                        Text("イベントを検索")
                    }
                }
                .disabled(selectedCalendar == nil || isSearching)
            }

            if hasSearched {
                Section {
                    Text("\(fetchedEvents.count)件見つかりました")
                }

                Section("出力形式") {
                    Picker("出力形式", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Button("エクスポート") {
                        exportTapped()
                    }
                    .disabled(fetchedEvents.isEmpty)
                }

                if let completionMessage {
                    Section {
                        Label(completionMessage, systemImage: "checkmark.circle")
                            .foregroundStyle(.green)
                    }
                }
            }
        }
    }

    private func search() async {
        guard let calendar = selectedCalendar else { return }
        isSearching = true
        completionMessage = nil
        let normalizedEnd = Calendar.current.date(
            bySettingHour: 23, minute: 59, second: 59, of: endDate
        ) ?? endDate
        fetchedEvents = await store.fetchEvents(calendar: calendar, start: startDate, end: normalizedEnd)
        hasSearched = true
        isSearching = false
    }

    private func exportTapped() {
        completionMessage = nil
        guard exportFormat == .csv else {
            alertMessage = "JSON出力はPhase 2で実装予定です。現在はCSVのみ対応しています。"
            return
        }
        let data = CSVExporter.makeCSV(events: fetchedEvents)
        exportDocument = ExportDocument(data: data)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        exportFilename = "CalendarExport_\(dateFormatter.string(from: Date()))"

        isExporting = true
    }
}

#Preview {
    ContentView()
}
