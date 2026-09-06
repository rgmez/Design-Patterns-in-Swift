public enum DocumentTextAlignment: Equatable, Sendable {
    case leading
    case centered
}

public struct DocumentTextStyle: Equatable, Sendable {
    public var fontName: String
    public var alignment: DocumentTextAlignment

    public init(fontName: String, alignment: DocumentTextAlignment) {
        self.fontName = fontName
        self.alignment = alignment
    }
}

public struct DocumentSectionConfiguration: Equatable, Sendable {
    public let id: String
    public var heading: String
    public var paragraphs: [String]

    public init(id: String, heading: String, paragraphs: [String]) {
        self.id = id
        self.heading = heading
        self.paragraphs = paragraphs
    }
}

public struct DocumentConfiguration: Equatable, Sendable {
    public var title: String
    public var textStyle: DocumentTextStyle
    public var sections: [DocumentSectionConfiguration]

    public init(
        title: String,
        textStyle: DocumentTextStyle,
        sections: [DocumentSectionConfiguration]
    ) {
        self.title = title
        self.textStyle = textStyle
        self.sections = sections
    }
}
