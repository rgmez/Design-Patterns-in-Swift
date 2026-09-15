import Foundation

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

public struct BackupUpload: Codable, Sendable {
    private var state: any BackupUploadState

    public var phase: BackupUploadPhase {
        state.phase
    }

    public var primaryAction: BackupUploadPrimaryAction? {
        state.primaryAction
    }

    public var backgroundOperation: BackupUploadBackgroundOperation? {
        state.backgroundOperation
    }

    public init() {
        state = ReadyBackupUploadState()
    }

    public init(restoring phase: BackupUploadPhase) throws {
        state = try backupUploadState(restoring: phase)
    }

    @discardableResult
    public mutating func handle(
        _ event: BackupUploadEvent
    ) throws -> BackupUploadPhase {
        let nextState = try state.handle(event)
        state = nextState
        return nextState.phase
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let phase = try container.decode(BackupUploadPhase.self)

        do {
            state = try backupUploadState(restoring: phase)
        } catch {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid persisted backup phase."
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(phase)
    }
}

private protocol BackupUploadState: Sendable {
    var phase: BackupUploadPhase { get }
    var primaryAction: BackupUploadPrimaryAction? { get }
    var backgroundOperation: BackupUploadBackgroundOperation? { get }

    func handle(
        _ event: BackupUploadEvent
    ) throws -> any BackupUploadState
}

private extension BackupUploadState {
    var primaryAction: BackupUploadPrimaryAction? {
        nil
    }

    var backgroundOperation: BackupUploadBackgroundOperation? {
        nil
    }

    func reject(
        _ event: BackupUploadEvent
    ) throws -> any BackupUploadState {
        throw BackupUploadError.invalidTransition(
            event: event,
            from: phase
        )
    }
}

private struct ReadyBackupUploadState: BackupUploadState {
    let phase = BackupUploadPhase.ready
    let primaryAction: BackupUploadPrimaryAction? = .start

    func handle(
        _ event: BackupUploadEvent
    ) throws -> any BackupUploadState {
        guard event == .start else {
            return try reject(event)
        }
        return PreparingBackupUploadState()
    }
}

private struct PreparingBackupUploadState: BackupUploadState {
    let phase = BackupUploadPhase.preparing
    let backgroundOperation: BackupUploadBackgroundOperation? = .prepare

    func handle(
        _ event: BackupUploadEvent
    ) throws -> any BackupUploadState {
        switch event {
        case .preparationFinished:
            return EncryptingBackupUploadState()
        case let .fail(failure):
            return FailedBackupUploadState(
                failure: failure,
                recoveryPoint: .preparing
            )
        default:
            return try reject(event)
        }
    }
}

private struct EncryptingBackupUploadState: BackupUploadState {
    let phase = BackupUploadPhase.encrypting
    let backgroundOperation: BackupUploadBackgroundOperation? = .encrypt

    func handle(
        _ event: BackupUploadEvent
    ) throws -> any BackupUploadState {
        switch event {
        case let .encryptionFinished(totalBytes):
            let progress = try BackupUploadProgress(
                uploadedBytes: 0,
                totalBytes: totalBytes
            )
            return UploadingBackupUploadState(progress: progress)
        case let .fail(failure):
            return FailedBackupUploadState(
                failure: failure,
                recoveryPoint: .encrypting
            )
        default:
            return try reject(event)
        }
    }
}

private struct UploadingBackupUploadState: BackupUploadState {
    let progress: BackupUploadProgress

    var phase: BackupUploadPhase {
        .uploading(progress)
    }

    let primaryAction: BackupUploadPrimaryAction? = .pause
    let backgroundOperation: BackupUploadBackgroundOperation? = .upload

    func handle(
        _ event: BackupUploadEvent
    ) throws -> any BackupUploadState {
        switch event {
        case let .uploadAdvanced(uploadedBytes):
            guard uploadedBytes >= progress.uploadedBytes else {
                throw BackupUploadError.regressedProgress(
                    previousBytes: progress.uploadedBytes,
                    attemptedBytes: uploadedBytes
                )
            }
            let advancedProgress = try BackupUploadProgress(
                uploadedBytes: uploadedBytes,
                totalBytes: progress.totalBytes
            )
            return UploadingBackupUploadState(progress: advancedProgress)
        case .pause:
            return PausedBackupUploadState(progress: progress)
        case let .fail(failure):
            return FailedBackupUploadState(
                failure: failure,
                recoveryPoint: .uploading(progress)
            )
        case let .finish(remoteBackupID):
            guard progress.uploadedBytes == progress.totalBytes else {
                throw BackupUploadError.incompleteUpload(
                    uploadedBytes: progress.uploadedBytes,
                    totalBytes: progress.totalBytes
                )
            }
            try validate(remoteBackupID: remoteBackupID)
            return CompletedBackupUploadState(
                remoteBackupID: remoteBackupID
            )
        default:
            return try reject(event)
        }
    }
}

private struct PausedBackupUploadState: BackupUploadState {
    let progress: BackupUploadProgress

    var phase: BackupUploadPhase {
        .paused(progress)
    }

    let primaryAction: BackupUploadPrimaryAction? = .resume

    func handle(
        _ event: BackupUploadEvent
    ) throws -> any BackupUploadState {
        guard event == .resume else {
            return try reject(event)
        }
        return UploadingBackupUploadState(progress: progress)
    }
}

private struct FailedBackupUploadState: BackupUploadState {
    let failure: BackupUploadFailure
    let recoveryPoint: BackupUploadRecoveryPoint

    var phase: BackupUploadPhase {
        .failed(failure, retryFrom: recoveryPoint)
    }

    let primaryAction: BackupUploadPrimaryAction? = .retry

    func handle(
        _ event: BackupUploadEvent
    ) throws -> any BackupUploadState {
        guard event == .retry else {
            return try reject(event)
        }
        return try backupUploadState(restoring: recoveryPoint.phase)
    }
}

private struct CompletedBackupUploadState: BackupUploadState {
    let remoteBackupID: String

    var phase: BackupUploadPhase {
        .completed(remoteBackupID: remoteBackupID)
    }

    func handle(
        _ event: BackupUploadEvent
    ) throws -> any BackupUploadState {
        try reject(event)
    }
}

private extension BackupUploadRecoveryPoint {
    var phase: BackupUploadPhase {
        switch self {
        case .preparing:
            .preparing
        case .encrypting:
            .encrypting
        case let .uploading(progress):
            .uploading(progress)
        }
    }
}

private func backupUploadState(
    restoring phase: BackupUploadPhase
) throws -> any BackupUploadState {
    switch phase {
    case .ready:
        return ReadyBackupUploadState()
    case .preparing:
        return PreparingBackupUploadState()
    case .encrypting:
        return EncryptingBackupUploadState()
    case let .uploading(progress):
        return UploadingBackupUploadState(
            progress: try validated(progress)
        )
    case let .paused(progress):
        return PausedBackupUploadState(
            progress: try validated(progress)
        )
    case let .failed(failure, recoveryPoint):
        return FailedBackupUploadState(
            failure: failure,
            recoveryPoint: try validated(recoveryPoint)
        )
    case let .completed(remoteBackupID):
        try validate(remoteBackupID: remoteBackupID)
        return CompletedBackupUploadState(
            remoteBackupID: remoteBackupID
        )
    }
}

private func validated(
    _ progress: BackupUploadProgress
) throws -> BackupUploadProgress {
    try BackupUploadProgress(
        uploadedBytes: progress.uploadedBytes,
        totalBytes: progress.totalBytes
    )
}

private func validated(
    _ recoveryPoint: BackupUploadRecoveryPoint
) throws -> BackupUploadRecoveryPoint {
    switch recoveryPoint {
    case .preparing:
        .preparing
    case .encrypting:
        .encrypting
    case let .uploading(progress):
        .uploading(try validated(progress))
    }
}

private func validate(remoteBackupID: String) throws {
    guard !remoteBackupID.trimmingCharacters(in: .whitespacesAndNewlines)
        .isEmpty else {
        throw BackupUploadError.missingRemoteBackupID
    }
}
