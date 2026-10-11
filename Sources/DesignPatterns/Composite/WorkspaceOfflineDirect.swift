public struct WorkspaceFile: Equatable, Sendable {
    public let id: String
    public let name: String
    public let byteCount: Int
    public let isDownloadable: Bool
    public let isStoredOffline: Bool

    public init(
        id: String,
        name: String,
        byteCount: Int,
        isDownloadable: Bool,
        isStoredOffline: Bool = false
    ) {
        precondition(!id.isEmpty, "A workspace file needs an identifier")
        precondition(!name.isEmpty, "A workspace file needs a name")
        precondition(byteCount >= 0, "A workspace file size cannot be negative")

        self.id = id
        self.name = name
        self.byteCount = byteCount
        self.isDownloadable = isDownloadable
        self.isStoredOffline = isStoredOffline
    }
}

public struct WorkspaceFolder: Equatable, Sendable {
    public let name: String
    public let entries: [DirectWorkspaceEntry]

    public init(
        name: String,
        entries: [DirectWorkspaceEntry]
    ) {
        precondition(!name.isEmpty, "A workspace folder needs a name")

        self.name = name
        self.entries = entries
    }
}

public indirect enum DirectWorkspaceEntry: Equatable, Sendable {
    case file(WorkspaceFile)
    case folder(WorkspaceFolder)
}

public struct OfflineSelectionSummary: Equatable, Sendable {
    public let fileCount: Int
    public let byteCount: Int
    public let isDownloadable: Bool

    public init(
        fileCount: Int,
        byteCount: Int,
        isDownloadable: Bool
    ) {
        self.fileCount = fileCount
        self.byteCount = byteCount
        self.isDownloadable = isDownloadable
    }
}

public struct DirectOfflineSelectionPreview: Sendable {
    public init() {}

    public func summary(
        for entry: DirectWorkspaceEntry
    ) -> OfflineSelectionSummary {
        switch entry {
        case let .file(file):
            return OfflineSelectionSummary(
                fileCount: 1,
                byteCount: file.byteCount,
                isDownloadable: file.isDownloadable
            )
        case let .folder(folder):
            guard !folder.entries.isEmpty else {
                return OfflineSelectionSummary(
                    fileCount: 0,
                    byteCount: 0,
                    isDownloadable: false
                )
            }

            return folder.entries.reduce(
                OfflineSelectionSummary(
                    fileCount: 0,
                    byteCount: 0,
                    isDownloadable: true
                )
            ) { partialSummary, entry in
                let entrySummary = summary(for: entry)

                return OfflineSelectionSummary(
                    fileCount: partialSummary.fileCount + entrySummary.fileCount,
                    byteCount: partialSummary.byteCount + entrySummary.byteCount,
                    isDownloadable: partialSummary.isDownloadable
                        && entrySummary.isDownloadable
                )
            }
        }
    }
}
