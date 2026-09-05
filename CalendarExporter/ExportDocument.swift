import SwiftUI
import UniformTypeIdentifiers

/// `.fileExporter`用の汎用ドキュメント。中身は既に組み立て済みの Data を
/// そのまま書き出すだけで、EventKitへの書き込みは一切行わない。
struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText, .json] }
    static var writableContentTypes: [UTType] { [.commaSeparatedText, .json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileContents: data)
    }
}
