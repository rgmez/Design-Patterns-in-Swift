public struct WorkspaceFileLocation: Equatable, Sendable {
    public let file: WorkspaceFile
    public let pathComponents: [String]

    public var displayPath: String {
        pathComponents.joined(separator: " / ")
    }

    public init(
        file: WorkspaceFile,
        pathComponents: [String]
    ) {
        precondition(!pathComponents.isEmpty, "A file location needs a path")

        self.file = file
        self.pathComponents = pathComponents
    }

    fileprivate func prepending(
        _ component: String
    ) -> WorkspaceFileLocation {
        WorkspaceFileLocation(
            file: file,
            pathComponents: [component] + pathComponents
        )
    }
}

public protocol WorkspaceComponent: Sendable {
    var fileLocations: [WorkspaceFileLocation] { get }
}

extension WorkspaceFile: WorkspaceComponent {
    public var fileLocations: [WorkspaceFileLocation] {
        [
            WorkspaceFileLocation(
                file: self,
                pathComponents: [name]
            )
        ]
    }

    public func openRequest() -> WorkspaceFileOpenRequest {
        WorkspaceFileOpenRequest(fileID: id)
    }
}

public struct WorkspaceFolder: WorkspaceComponent, Sendable {
    public let name: String

    private let children: [any WorkspaceComponent]

    public init(
        name: String,
        children: [any WorkspaceComponent]
    ) {
        precondition(!name.isEmpty, "A workspace folder needs a name")

        self.name = name
        self.children = children
    }

    public var fileLocations: [WorkspaceFileLocation] {
        children.flatMap { child in
            child.fileLocations.map { location in
                location.prepending(name)
            }
        }
    }
}

public struct WorkspaceFileOpenRequest: Equatable, Sendable {
    public let fileID: String

    public init(fileID: String) {
        precondition(!fileID.isEmpty, "An open request needs a file identifier")
        self.fileID = fileID
    }
}

public struct WorkspaceOfflineSelectionPreview: Sendable {
    public init() {}

    public func summary(
        for component: any WorkspaceComponent
    ) -> OfflineSelectionSummary {
        let files = component.fileLocations.map(\.file)

        guard !files.isEmpty else {
            return OfflineSelectionSummary(
                fileCount: 0,
                byteCount: 0,
                isDownloadable: false
            )
        }

        return OfflineSelectionSummary(
            fileCount: files.count,
            byteCount: files.reduce(0) { $0 + $1.byteCount },
            isDownloadable: files.allSatisfy(\.isDownloadable)
        )
    }
}

public struct WorkspaceSearchIndexer: Sendable {
    public init() {}

    public func records(
        in component: any WorkspaceComponent
    ) -> [WorkspaceSearchRecord] {
        component.fileLocations.map { location in
            WorkspaceSearchRecord(
                fileID: location.file.id,
                displayPath: location.displayPath
            )
        }
    }
}

public struct WorkspaceCleanupPreview: Sendable {
    public init() {}

    public func reclaimableBytes(
        in component: any WorkspaceComponent
    ) -> Int {
        component.fileLocations.reduce(0) { bytes, location in
            bytes + (location.file.isStoredOffline ? location.file.byteCount : 0)
        }
    }
}
