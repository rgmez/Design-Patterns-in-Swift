import Foundation

public struct BackupUploadProgress: Equatable, Sendable {
    public let uploadedBytes: Int
    public let totalBytes: Int

    public init(uploadedBytes: Int, totalBytes: Int) throws {
        guard totalBytes > 0,
              uploadedBytes >= 0,
              uploadedBytes <= totalBytes else {
            throw BackupUploadError.invalidProgress(
                uploadedBytes: uploadedBytes,
                totalBytes: totalBytes
            )
        }

        self.uploadedBytes = uploadedBytes
        self.totalBytes = totalBytes
    }
}

public enum BackupUploadFailure: Equatable, Sendable {
    case insufficientLocalSpace
    case encryptionUnavailable
    case connectionLost
}

public enum BackupUploadRecoveryPoint: Equatable, Sendable {
    case preparing
    case encrypting
    case uploading(BackupUploadProgress)
}

public enum BackupUploadPhase: Equatable, Sendable {
    case ready
    case preparing
    case encrypting
    case uploading(BackupUploadProgress)
    case paused(BackupUploadProgress)
    case failed(
        BackupUploadFailure,
        retryFrom: BackupUploadRecoveryPoint
    )
    case completed(remoteBackupID: String)
}

public enum BackupUploadEvent: Equatable, Sendable {
    case start
    case preparationFinished
    case encryptionFinished(totalBytes: Int)
    case uploadAdvanced(uploadedBytes: Int)
    case pause
    case resume
    case fail(BackupUploadFailure)
    case retry
    case finish(remoteBackupID: String)
}

public enum BackupUploadError: Error, Equatable, Sendable {
    case invalidTransition(
        event: BackupUploadEvent,
        from: BackupUploadPhase
    )
    case invalidProgress(uploadedBytes: Int, totalBytes: Int)
    case regressedProgress(previousBytes: Int, attemptedBytes: Int)
    case incompleteUpload(uploadedBytes: Int, totalBytes: Int)
    case missingRemoteBackupID
}

public func transitionBackupUpload(
    from phase: BackupUploadPhase,
    on event: BackupUploadEvent
) throws -> BackupUploadPhase {
    switch phase {
    case .ready:
        return try transitionFromReady(on: event)
    case .preparing:
        return try transitionFromPreparing(on: event)
    case .encrypting:
        return try transitionFromEncrypting(on: event)
    case let .uploading(progress):
        return try transitionFromUploading(progress, on: event)
    case let .paused(progress):
        return try transitionFromPaused(progress, on: event)
    case let .failed(failure, recoveryPoint):
        return try transitionFromFailure(
            failure,
            recoveryPoint: recoveryPoint,
            on: event
        )
    case .completed:
        throw invalidTransition(event, from: phase)
    }
}

private func transitionFromReady(
    on event: BackupUploadEvent
) throws -> BackupUploadPhase {
    guard event == .start else {
        throw invalidTransition(event, from: .ready)
    }
    return .preparing
}

private func transitionFromPreparing(
    on event: BackupUploadEvent
) throws -> BackupUploadPhase {
    switch event {
    case .preparationFinished:
        return .encrypting
    case let .fail(failure):
        return .failed(failure, retryFrom: .preparing)
    default:
        throw invalidTransition(event, from: .preparing)
    }
}

private func transitionFromEncrypting(
    on event: BackupUploadEvent
) throws -> BackupUploadPhase {
    switch event {
    case let .encryptionFinished(totalBytes):
        let progress = try BackupUploadProgress(
            uploadedBytes: 0,
            totalBytes: totalBytes
        )
        return .uploading(progress)
    case let .fail(failure):
        return .failed(failure, retryFrom: .encrypting)
    default:
        throw invalidTransition(event, from: .encrypting)
    }
}

private func transitionFromUploading(
    _ progress: BackupUploadProgress,
    on event: BackupUploadEvent
) throws -> BackupUploadPhase {
    switch event {
    case let .uploadAdvanced(uploadedBytes):
        return try advanceUpload(progress, to: uploadedBytes)
    case .pause:
        return .paused(progress)
    case let .fail(failure):
        return .failed(failure, retryFrom: .uploading(progress))
    case let .finish(remoteBackupID):
        guard progress.uploadedBytes == progress.totalBytes else {
            throw BackupUploadError.incompleteUpload(
                uploadedBytes: progress.uploadedBytes,
                totalBytes: progress.totalBytes
            )
        }
        guard !remoteBackupID.trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty else {
            throw BackupUploadError.missingRemoteBackupID
        }
        return .completed(remoteBackupID: remoteBackupID)
    default:
        throw invalidTransition(event, from: .uploading(progress))
    }
}

private func advanceUpload(
    _ progress: BackupUploadProgress,
    to uploadedBytes: Int
) throws -> BackupUploadPhase {
    guard uploadedBytes >= progress.uploadedBytes else {
        throw BackupUploadError.regressedProgress(
            previousBytes: progress.uploadedBytes,
            attemptedBytes: uploadedBytes
        )
    }
    return .uploading(
        try BackupUploadProgress(
            uploadedBytes: uploadedBytes,
            totalBytes: progress.totalBytes
        )
    )
}

private func transitionFromPaused(
    _ progress: BackupUploadProgress,
    on event: BackupUploadEvent
) throws -> BackupUploadPhase {
    guard event == .resume else {
        throw invalidTransition(event, from: .paused(progress))
    }
    return .uploading(progress)
}

private func transitionFromFailure(
    _ failure: BackupUploadFailure,
    recoveryPoint: BackupUploadRecoveryPoint,
    on event: BackupUploadEvent
) throws -> BackupUploadPhase {
    guard event == .retry else {
        throw invalidTransition(
            event,
            from: .failed(failure, retryFrom: recoveryPoint)
        )
    }

    switch recoveryPoint {
    case .preparing:
        return .preparing
    case .encrypting:
        return .encrypting
    case let .uploading(progress):
        return .uploading(progress)
    }
}

private func invalidTransition(
    _ event: BackupUploadEvent,
    from phase: BackupUploadPhase
) -> BackupUploadError {
    .invalidTransition(event: event, from: phase)
}
