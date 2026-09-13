import DesignPatterns
import Testing

@Suite("State problem")
struct StateProblemTests {
    private static let totalBytes = 1_024
    private static let uploadedBytes = 640
    private static let remoteBackupID = "backup-eu-2048"
    private static let blankRemoteBackupID = "   "

    struct InvalidTransitionScenario: Sendable {
        let phase: BackupUploadPhase
        let event: BackupUploadEvent
    }

    struct InvalidProgressScenario: Sendable {
        let uploadedBytes: Int
        let totalBytes: Int
    }

    private static let invalidTransitionScenarios = [
        InvalidTransitionScenario(phase: .ready, event: .pause),
        InvalidTransitionScenario(phase: .preparing, event: .resume),
        InvalidTransitionScenario(
            phase: .encrypting,
            event: .finish(remoteBackupID: remoteBackupID)
        ),
        InvalidTransitionScenario(
            phase: .completed(remoteBackupID: remoteBackupID),
            event: .start
        )
    ]

    private static let invalidProgressScenarios = [
        InvalidProgressScenario(uploadedBytes: -1, totalBytes: totalBytes),
        InvalidProgressScenario(
            uploadedBytes: totalBytes + 1,
            totalBytes: totalBytes
        ),
        InvalidProgressScenario(uploadedBytes: 0, totalBytes: 0)
    ]

    private static func uploadingPhase() throws -> BackupUploadPhase {
        let preparing = try transitionBackupUpload(from: .ready, on: .start)
        let encrypting = try transitionBackupUpload(
            from: preparing,
            on: .preparationFinished
        )
        let uploadStart = try transitionBackupUpload(
            from: encrypting,
            on: .encryptionFinished(totalBytes: totalBytes)
        )
        return try transitionBackupUpload(
            from: uploadStart,
            on: .uploadAdvanced(uploadedBytes: uploadedBytes)
        )
    }

    @Suite("Valid transitions")
    struct ValidTransitions {
        @Test("Completes only after encrypting and uploading every byte")
        func completesLifecycle() throws {
            let preparing = try transitionBackupUpload(
                from: .ready,
                on: .start
            )
            let encrypting = try transitionBackupUpload(
                from: preparing,
                on: .preparationFinished
            )
            let uploading = try transitionBackupUpload(
                from: encrypting,
                on: .encryptionFinished(
                    totalBytes: StateProblemTests.totalBytes
                )
            )
            let uploaded = try transitionBackupUpload(
                from: uploading,
                on: .uploadAdvanced(
                    uploadedBytes: StateProblemTests.totalBytes
                )
            )
            let completed = try transitionBackupUpload(
                from: uploaded,
                on: .finish(
                    remoteBackupID: StateProblemTests.remoteBackupID
                )
            )

            #expect(preparing == .preparing)
            #expect(encrypting == .encrypting)
            #expect(
                completed
                    == .completed(
                        remoteBackupID: StateProblemTests.remoteBackupID
                    )
            )
        }

        @Test("Pauses and resumes from the same upload checkpoint")
        func preservesPauseCheckpoint() throws {
            let uploading = try StateProblemTests.uploadingPhase()
            let paused = try transitionBackupUpload(
                from: uploading,
                on: .pause
            )
            let resumed = try transitionBackupUpload(
                from: paused,
                on: .resume
            )

            #expect(resumed == uploading)
        }

        @Test("Retries a connection failure from its upload checkpoint")
        func retriesFromFailureCheckpoint() throws {
            let uploading = try StateProblemTests.uploadingPhase()
            let failed = try transitionBackupUpload(
                from: uploading,
                on: .fail(.connectionLost)
            )
            let retried = try transitionBackupUpload(
                from: failed,
                on: .retry
            )

            #expect(retried == uploading)
        }
    }

    @Suite("Invalid transitions")
    struct InvalidTransitions {
        @Test(
            "Rejects lifecycle jumps",
            arguments: StateProblemTests.invalidTransitionScenarios
        )
        func rejectsLifecycleJump(
            _ scenario: StateProblemTests.InvalidTransitionScenario
        ) {
            #expect(
                throws: BackupUploadError.invalidTransition(
                    event: scenario.event,
                    from: scenario.phase
                )
            ) {
                try transitionBackupUpload(
                    from: scenario.phase,
                    on: scenario.event
                )
            }
        }

        @Test("Rejects completion before every byte is uploaded")
        func rejectsIncompleteUpload() throws {
            let uploading = try StateProblemTests.uploadingPhase()

            #expect(
                throws: BackupUploadError.incompleteUpload(
                    uploadedBytes: StateProblemTests.uploadedBytes,
                    totalBytes: StateProblemTests.totalBytes
                )
            ) {
                try transitionBackupUpload(
                    from: uploading,
                    on: .finish(
                        remoteBackupID: StateProblemTests.remoteBackupID
                    )
                )
            }
        }

        @Test("Rejects progress that moves backwards")
        func rejectsRegressedProgress() throws {
            let uploading = try StateProblemTests.uploadingPhase()
            let attemptedBytes = StateProblemTests.uploadedBytes - 1

            #expect(
                throws: BackupUploadError.regressedProgress(
                    previousBytes: StateProblemTests.uploadedBytes,
                    attemptedBytes: attemptedBytes
                )
            ) {
                try transitionBackupUpload(
                    from: uploading,
                    on: .uploadAdvanced(uploadedBytes: attemptedBytes)
                )
            }
        }

        @Test(
            "Rejects progress outside the encrypted payload",
            arguments: StateProblemTests.invalidProgressScenarios
        )
        func rejectsInvalidProgress(
            _ scenario: StateProblemTests.InvalidProgressScenario
        ) {
            #expect(
                throws: BackupUploadError.invalidProgress(
                    uploadedBytes: scenario.uploadedBytes,
                    totalBytes: scenario.totalBytes
                )
            ) {
                try BackupUploadProgress(
                    uploadedBytes: scenario.uploadedBytes,
                    totalBytes: scenario.totalBytes
                )
            }
        }

        @Test("Rejects a blank remote identifier after upload")
        func rejectsBlankRemoteBackupID() throws {
            let uploading = try StateProblemTests.uploadingPhase()
            let uploaded = try transitionBackupUpload(
                from: uploading,
                on: .uploadAdvanced(
                    uploadedBytes: StateProblemTests.totalBytes
                )
            )

            #expect(throws: BackupUploadError.missingRemoteBackupID) {
                try transitionBackupUpload(
                    from: uploaded,
                    on: .finish(
                        remoteBackupID: StateProblemTests.blankRemoteBackupID
                    )
                )
            }
        }
    }
}
