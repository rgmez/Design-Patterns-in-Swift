import DesignPatterns
import Foundation
import Testing

@Suite("State")
struct StateTests {
    private static let totalBytes = 2_048
    private static let uploadedBytes = 768
    private static let remoteBackupID = "backup-eu-4096"
    private static let blankRemoteBackupID = "   "

    struct RestoredDecisionScenario: Sendable {
        let phase: BackupUploadPhase
        let primaryAction: BackupUploadPrimaryAction?
        let backgroundOperation: BackupUploadBackgroundOperation?
    }

    struct UncheckedProgress: Encodable {
        let uploadedBytes: Int
        let totalBytes: Int
    }

    private static let restoredDecisionScenarios = [
        RestoredDecisionScenario(
            phase: .ready,
            primaryAction: .start,
            backgroundOperation: nil
        ),
        RestoredDecisionScenario(
            phase: .preparing,
            primaryAction: nil,
            backgroundOperation: .prepare
        ),
        RestoredDecisionScenario(
            phase: .encrypting,
            primaryAction: nil,
            backgroundOperation: .encrypt
        ),
        RestoredDecisionScenario(
            phase: .failed(.connectionLost, retryFrom: .encrypting),
            primaryAction: .retry,
            backgroundOperation: nil
        ),
        RestoredDecisionScenario(
            phase: .completed(remoteBackupID: remoteBackupID),
            primaryAction: nil,
            backgroundOperation: nil
        )
    ]

    private static func uploadingBackup() throws -> BackupUpload {
        var backup = BackupUpload()
        try backup.handle(.start)
        try backup.handle(.preparationFinished)
        try backup.handle(.encryptionFinished(totalBytes: totalBytes))
        try backup.handle(.uploadAdvanced(uploadedBytes: uploadedBytes))
        return backup
    }

    @Suite("State-owned behavior")
    struct StateOwnedBehavior {
        @Test(
            "Restored phases own their UI and worker decisions",
            arguments: StateTests.restoredDecisionScenarios
        )
        func restoredStateOwnsDecisions(
            _ scenario: StateTests.RestoredDecisionScenario
        ) throws {
            let backup = try BackupUpload(restoring: scenario.phase)

            #expect(backup.phase == scenario.phase)
            #expect(backup.primaryAction == scenario.primaryAction)
            #expect(backup.backgroundOperation == scenario.backgroundOperation)
        }

        @Test("Uploading and paused states expose opposite behavior")
        func transferStatesOwnDecisions() throws {
            let progress = try BackupUploadProgress(
                uploadedBytes: StateTests.uploadedBytes,
                totalBytes: StateTests.totalBytes
            )
            let uploading = try BackupUpload(
                restoring: .uploading(progress)
            )
            let paused = try BackupUpload(restoring: .paused(progress))

            #expect(uploading.primaryAction == .pause)
            #expect(uploading.backgroundOperation == .upload)
            #expect(paused.primaryAction == .resume)
            #expect(paused.backgroundOperation == nil)
        }

        @Test("Transitioning changes available behavior with the state")
        func behaviorChangesAfterTransition() throws {
            var backup = BackupUpload()

            #expect(backup.primaryAction == .start)
            #expect(backup.backgroundOperation == nil)

            try backup.handle(.start)

            #expect(backup.primaryAction == nil)
            #expect(backup.backgroundOperation == .prepare)
        }
    }

    @Suite("Lifecycle")
    struct Lifecycle {
        @Test("Completes the encrypted backup in legal order")
        func completesBackup() throws {
            var backup = BackupUpload()

            try backup.handle(.start)
            try backup.handle(.preparationFinished)
            try backup.handle(
                .encryptionFinished(totalBytes: StateTests.totalBytes)
            )
            try backup.handle(
                .uploadAdvanced(uploadedBytes: StateTests.totalBytes)
            )
            let phase = try backup.handle(
                .finish(remoteBackupID: StateTests.remoteBackupID)
            )

            #expect(
                phase
                    == .completed(
                        remoteBackupID: StateTests.remoteBackupID
                    )
            )
            #expect(backup.primaryAction == nil)
            #expect(backup.backgroundOperation == nil)
        }

        @Test("Pause and resume preserve the upload checkpoint")
        func pausePreservesCheckpoint() throws {
            var backup = try StateTests.uploadingBackup()
            let uploadingPhase = backup.phase

            try backup.handle(.pause)

            #expect(backup.primaryAction == .resume)
            #expect(backup.backgroundOperation == nil)

            try backup.handle(.resume)

            #expect(backup.phase == uploadingPhase)
            #expect(backup.backgroundOperation == .upload)
        }

        @Test("Retry restores the failed state's exact recovery point")
        func retryRestoresRecoveryPoint() throws {
            var backup = try StateTests.uploadingBackup()
            let uploadingPhase = backup.phase

            try backup.handle(.fail(.connectionLost))

            #expect(backup.primaryAction == .retry)
            #expect(backup.backgroundOperation == nil)

            try backup.handle(.retry)

            #expect(backup.phase == uploadingPhase)
            #expect(backup.backgroundOperation == .upload)
        }
    }

    @Suite("Persistence and rejection")
    struct PersistenceAndRejection {
        @Test("Codable restoration preserves one authoritative state")
        func codableRoundTrip() throws {
            let backup = try StateTests.uploadingBackup()
            let data = try JSONEncoder().encode(backup)
            let restored = try JSONDecoder().decode(
                BackupUpload.self,
                from: data
            )

            #expect(restored.phase == backup.phase)
            #expect(restored.primaryAction == backup.primaryAction)
            #expect(
                restored.backgroundOperation
                    == backup.backgroundOperation
            )
        }

        @Test("Rejected events leave the current state unchanged")
        func rejectedEventPreservesState() {
            var backup = BackupUpload()

            #expect(
                throws: BackupUploadError.invalidTransition(
                    event: .pause,
                    from: .ready
                )
            ) {
                try backup.handle(.pause)
            }
            #expect(backup.phase == .ready)
            #expect(backup.primaryAction == .start)
        }

        @Test("Restoration rejects an invalid terminal identifier")
        func rejectsInvalidRestoredCompletion() {
            #expect(throws: BackupUploadError.missingRemoteBackupID) {
                try BackupUpload(
                    restoring: .completed(
                        remoteBackupID: StateTests.blankRemoteBackupID
                    )
                )
            }
        }

        @Test("Decoding rejects persisted progress outside the payload")
        func rejectsInvalidPersistedProgress() throws {
            let invalidProgress = StateTests.UncheckedProgress(
                uploadedBytes: StateTests.totalBytes + 1,
                totalBytes: StateTests.totalBytes
            )
            let data = try JSONEncoder().encode(invalidProgress)

            #expect(throws: DecodingError.self) {
                try JSONDecoder().decode(
                    BackupUploadProgress.self,
                    from: data
                )
            }
        }
    }
}
