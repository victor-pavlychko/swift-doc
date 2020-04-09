import ArgumentParser
import CommonMark
import Foundation
import SwiftSemantics
import struct SwiftSemantics.Protocol
import SwiftMarkup
import SwiftDoc

extension SwiftDoc {
    struct Generate: ParsableCommand {
        enum Format: String, ExpressibleByArgument {
            case commonmark
            case html
        }

        struct Options: ParsableArguments {
            @Argument(help: "One or more paths to Swift files")
            var inputs: [String]

            @Option(name: .shortAndLong,
                    default: nil,
                    help: "The path to the CommonMark file for the home page (html output only)")
            var brief: String?

            @Option(name: .shortAndLong,
                    help: "Paths to CommonMark documentation files")
            var docs: [String]

            @Option(name: [.long, .customShort("n")],
                    help: "The name of the module")
            var moduleName: String

            @Option(name: .shortAndLong,
                    default: ".build/documentation",
                    help: "The path for generated output")
            var output: String

            @Option(name: .shortAndLong,
                    default: .commonmark,
                    help: "The output format")
            var format: Format

            @Option(name: .customLong("base-url"),
                    default: "/",
                    help: "The base URL used for all relative URLs in generated documents.")
            var baseURL: String
        }

        static var configuration = CommandConfiguration(abstract: "Generates Swift documentation")

        @OptionGroup()
        var options: Options

        func run() throws {
            let module = try Module(name: options.moduleName, paths: options.inputs)

            let outputDirectoryURL = URL(fileURLWithPath: options.output)
            try fileManager.createDirectory(at: outputDirectoryURL, withIntermediateDirectories: true, attributes: fileAttributes)

            do {
                let format = options.format

                var pages: [String: Page] = [:]

                var globals: [String: [Symbol]] = [:]
                for symbol in module.interface.topLevelSymbols.filter({ $0.isPublic }) {
                    switch symbol.api {
                    case is Class, is Enumeration, is Structure, is Protocol:
                        pages[path(for: symbol)] = TypePage(module: module, symbol: symbol)
                    case let `typealias` as Typealias:
                        pages[path(for: `typealias`.name)] = TypealiasPage(module: module, symbol: symbol)
                    case let function as Function where !function.isOperator:
                        globals[function.name, default: []] += [symbol]
                    case let variable as Variable:
                        globals[variable.name, default: []] += [symbol]
                    default:
                        continue
                    }
                }

                for (name, symbols) in globals {
                    pages[path(for: name)] = GlobalPage(module: module, name: name, symbols: symbols)
                }

                guard !pages.isEmpty else { return }

                if pages.count == 1, let page = pages.first?.value {
                    let filename: String
                    switch format {
                    case .commonmark:
                        filename = "Home.md"
                    case .html:
                        filename = "index.html"
                    }

                    let url = outputDirectoryURL.appendingPathComponent(filename)
                    try page.write(to: url, format: format, baseURL: options.baseURL)
                } else {
                    switch format {
                    case .commonmark:
                        pages["Home"] = HomePage(module: module)
                        pages["_Sidebar"] = SidebarPage(module: module)
                        pages["_Footer"] = FooterPage()
                    case .html:
                        let brief = try options.brief
                            .map(URL.init(fileURLWithPath:))
                            .map { try CommonMark.Document(String(contentsOf: $0)) }

                        let docs = try Docs(paths: options.docs)
                        let docsPages = docs.documents.map({ ($0.name, CommonMarkPage(module: module, document: $0)) })
                        pages.merge(docsPages, uniquingKeysWith: { existing, _ in existing })

                        pages["Home"] = HomePage(module: module, brief: brief)
                    }

                    try pages.map { $0 }.parallelForEach {
                        let filename: String
                        switch format {
                        case .commonmark:
                            filename = "\($0.key).md"
                        case .html where $0.key == "Home":
                            filename = "index.html"
                        case .html:
                            filename = "\($0.key)/index.html"
                        }

                        let url = outputDirectoryURL.appendingPathComponent(filename)
                        try $0.value.write(to: url, format: format, baseURL: options.baseURL)
                    }
                }
            } catch {
                logger.error("\(error)")
            }
        }
    }
}
