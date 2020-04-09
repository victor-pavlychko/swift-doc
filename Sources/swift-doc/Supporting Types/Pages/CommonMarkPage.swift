import SwiftSemantics
import SwiftDoc
import CommonMarkBuilder
import HypertextLiteral

struct CommonMarkPage: Page {
    let module: Module
    let doc: Doc

    init(module: Module, doc: Doc) {
        self.module = module
        self.doc = doc
    }

    // MARK: - Page

    var title: String {
        return doc.name
    }

    var document: CommonMark.Document {
        return doc.document
    }

    var html: HypertextLiteral.HTML {
        return #"""
        <section id="introduction">
            \#(doc.document.html)
        </section>
        """#
    }
}
