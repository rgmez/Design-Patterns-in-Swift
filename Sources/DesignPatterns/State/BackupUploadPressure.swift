public struct BackupUploadFlagSnapshot: Codable, Equatable, Sendable {
    public let isPreparing: Bool
    public let isEncrypting: Bool
    public let isUploading: Bool
    public let isPaused: Bool
    public let needsRetry: Bool
    public let isCompleted: Bool

    public init(
        isPreparing: Bool = false,
        isEncrypting: Bool = false,
        isUploading: Bool = false,
        isPaused: Bool = false,
        needsRetry: Bool = false,
        isCompleted: Bool = false
    ) {
        self.isPreparing = isPreparing
        self.isEncrypting = isEncrypting
        self.isUploading = isUploading
        self.isPaused = isPaused
        self.needsRetry = needsRetry
        self.isCompleted = isCompleted
    }
}

public enum BackupUploadPrimaryAction: Equatable, Sendable {
    case start
    case pause
    case resume
    case retry
}

public enum BackupUploadBackgroundOperation: Equatable, Sendable {
    case prepare
    case encrypt
    case upload
}

public func backupUploadPrimaryAction(
    for snapshot: BackupUploadFlagSnapshot
) -> BackupUploadPrimaryAction? {
    if snapshot.isCompleted {
        return nil
    }
    if snapshot.needsRetry {
        return .retry
    }
    if snapshot.isPaused {
        return .resume
    }
    if snapshot.isUploading {
        return .pause
    }
    if snapshot.isPreparing || snapshot.isEncrypting {
        return nil
    }
    return .start
}

public func backupUploadBackgroundOperation(
    for snapshot: BackupUploadFlagSnapshot
) -> BackupUploadBackgroundOperation? {
    if snapshot.isCompleted || snapshot.needsRetry {
        return nil
    }
    if snapshot.isUploading {
        return .upload
    }
    if snapshot.isPaused {
        return nil
    }
    if snapshot.isEncrypting {
        return .encrypt
    }
    if snapshot.isPreparing {
        return .prepare
    }
    return nil
}
