import CommonMark
import Foundation

public final class Documents {
    public let documents: [String: CommonMark.Document]

    public required init(documents: [String: CommonMark.Document]) {
        self.documents = documents
    }

    public convenience init(paths: [String], extensions: Set<String> = ["md"]) throws {
        var files: [URL] = []

        let fileManager = FileManager.default
        for path in paths.map(URL.init(fileURLWithPath:)) {
            var isPathDirectory: ObjCBool = false
            guard fileManager.isReadableFile(atPath: path.path),
                fileManager.fileExists(atPath: path.path, isDirectory: &isPathDirectory)
            else { continue }

            guard isPathDirectory.boolValue else {
                files.append(path)
                continue
            }

            guard let directoryEnumerator = fileManager.enumerator(at: path, includingPropertiesForKeys: nil) else { continue }
            for case let url as URL in directoryEnumerator {
                print(url)

                var isDirectory: ObjCBool = false
                guard extensions.contains(url.pathExtension),
                    fileManager.isReadableFile(atPath: url.path),
                    fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
                    isDirectory.boolValue == false
                else { continue }
                files.append(url)
            }
        }

        let documents = try Dictionary(uniqueKeysWithValues: files.parallelMap({
            try ($0.lastPathComponent, CommonMark.Document(String(contentsOf: $0), options: []))
        }))

        self.init(documents: documents)
    }
}
