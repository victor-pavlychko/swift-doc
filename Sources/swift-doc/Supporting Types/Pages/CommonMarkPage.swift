import SwiftSemantics
import SwiftDoc
import CommonMarkBuilder
import HypertextLiteral

struct CommonMarkPage: Page {
    let module: Module
    let name: String
    let content: CommonMark.Document

    init(module: Module, name: String, content: CommonMark.Document) {
        self.module = module
        self.name = name
        self.content = content
    }

    // MARK: - Page

    var title: String {
        return name
    }

    var document: CommonMark.Document {
        return content
    }

    var html: HypertextLiteral.HTML {
        return content.html
    }
}
