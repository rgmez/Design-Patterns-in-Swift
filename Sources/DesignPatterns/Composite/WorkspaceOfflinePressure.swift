public struct DirectWorkspaceSearchIndexer: Sendable {
    public init() {}

    public func records(
        in entry: DirectWorkspaceEntry
    ) -> [WorkspaceSearchRecord] {
        records(in: entry, parentPath: [])
    }

    private func records(
        in entry: DirectWorkspaceEntry,
        parentPath: [String]
    ) -> [WorkspaceSearchRecord] {
        switch entry {
        case let .file(file):
            return [
                WorkspaceSearchRecord(
                    fileID: file.id,
                    displayPath: (parentPath + [file.name])
                        .joined(separator: " / ")
                )
            ]
        case let .folder(folder):
            let folderPath = parentPath + [folder.name]

            return folder.entries.flatMap { child in
                records(in: child, parentPath: folderPath)
            }
        }
    }
}

public struct DirectWorkspaceCleanupPreview: Sendable {
    public init() {}

    public func reclaimableBytes(
        in entry: DirectWorkspaceEntry
    ) -> Int {
        switch entry {
        case let .file(file):
            return file.isStoredOffline ? file.byteCount : 0
        case let .folder(folder):
            return folder.entries.reduce(0) { bytes, child in
                bytes + reclaimableBytes(in: child)
            }
        }
    }
}
