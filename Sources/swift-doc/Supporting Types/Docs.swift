import CommonMark
import Foundation

public final class Doc {
    public let name: String
    public let heading: CommonMark.Heading
    public let summary: CommonMark.Paragraph?
    public let document: CommonMark.Document

    public init(name: String, document: CommonMark.Document) {
        self.name = name
        self.document = document
        self.heading = document.children.lazy.compactMap({ $0 as? CommonMark.Heading }).first ?? CommonMark.Heading { name }
        self.summary = document.children.lazy.compactMap({ $0 as? CommonMark.Paragraph }).first
    }
}

public final class Docs {
    public let documents: [Doc]

    public required init(documents: [String: CommonMark.Document]) {
        self.documents = documents
            .map { Doc(name: $0.key, document: $0.value) }
            .sorted { $0.name < $1.name }
    }

    public convenience init(paths: [String]) throws {
        var files: [URL] = []
        let inputURLs = paths.map(URL.init(fileURLWithPath:))

        let fileManager = FileManager.default
        for inputURL in inputURLs {
            var isInputDirectory: ObjCBool = false
            guard fileManager.isReadableFile(atPath: inputURL.path),
                fileManager.fileExists(atPath: inputURL.path, isDirectory: &isInputDirectory)
            else { continue }

            guard isInputDirectory.boolValue else {
                files.append(inputURL)
                continue
            }

            guard let directoryEnumerator = fileManager.enumerator(at: inputURL, includingPropertiesForKeys: nil) else { continue }
            for case let fileURL as URL in directoryEnumerator {
                var isFileDirectory: ObjCBool = false
                guard fileURL.pathExtension == "md",
                    fileManager.isReadableFile(atPath: fileURL.path),
                    fileManager.fileExists(atPath: fileURL.path, isDirectory: &isFileDirectory),
                    isFileDirectory.boolValue == false
                else { continue }
                files.append(fileURL)
            }
        }

        try self.init(documents: Dictionary(uniqueKeysWithValues: files.parallelMap({
            let name = $0.deletingPathExtension().lastPathComponent
            let document = try CommonMark.Document(String(contentsOf: $0))
            return (name, document)
        })))
    }
}
