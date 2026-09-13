import DesignPatterns
import Testing

@Suite("State pressure")
struct StatePressureTests {
    struct DecisionScenario: Sendable {
        let snapshot: BackupUploadFlagSnapshot
        let primaryAction: BackupUploadPrimaryAction?
        let backgroundOperation: BackupUploadBackgroundOperation?
    }

    private static let coherentDecisionScenarios = [
        DecisionScenario(
            snapshot: BackupUploadFlagSnapshot(),
            primaryAction: .start,
            backgroundOperation: nil
        ),
        DecisionScenario(
            snapshot: BackupUploadFlagSnapshot(isPreparing: true),
            primaryAction: nil,
            backgroundOperation: .prepare
        ),
        DecisionScenario(
            snapshot: BackupUploadFlagSnapshot(isEncrypting: true),
            primaryAction: nil,
            backgroundOperation: .encrypt
        ),
        DecisionScenario(
            snapshot: BackupUploadFlagSnapshot(isUploading: true),
            primaryAction: .pause,
            backgroundOperation: .upload
        ),
        DecisionScenario(
            snapshot: BackupUploadFlagSnapshot(isPaused: true),
            primaryAction: .resume,
            backgroundOperation: nil
        ),
        DecisionScenario(
            snapshot: BackupUploadFlagSnapshot(needsRetry: true),
            primaryAction: .retry,
            backgroundOperation: nil
        ),
        DecisionScenario(
            snapshot: BackupUploadFlagSnapshot(isCompleted: true),
            primaryAction: nil,
            backgroundOperation: nil
        )
    ]

    @Suite("Coherent snapshots")
    struct CoherentSnapshots {
        @Test(
            "UI and worker decisions match a coherent lifecycle phase",
            arguments: StatePressureTests.coherentDecisionScenarios
        )
        func decisionsMatchPhase(
            _ scenario: StatePressureTests.DecisionScenario
        ) {
            #expect(
                backupUploadPrimaryAction(for: scenario.snapshot)
                    == scenario.primaryAction
            )
            #expect(
                backupUploadBackgroundOperation(for: scenario.snapshot)
                    == scenario.backgroundOperation
            )
        }
    }

    @Suite("Contradictory snapshots")
    struct ContradictorySnapshots {
        @Test("Paused and uploading flags disagree across consumers")
        func pauseDoesNotStopBackgroundUpload() {
            let snapshot = BackupUploadFlagSnapshot(
                isUploading: true,
                isPaused: true
            )

            #expect(backupUploadPrimaryAction(for: snapshot) == .resume)
            #expect(
                backupUploadBackgroundOperation(for: snapshot) == .upload
            )
        }

        @Test("Completion and retry can both be represented")
        func terminalAndRecoverableAtOnce() {
            let snapshot = BackupUploadFlagSnapshot(
                needsRetry: true,
                isCompleted: true
            )

            #expect(snapshot.needsRetry)
            #expect(snapshot.isCompleted)
            #expect(backupUploadPrimaryAction(for: snapshot) == nil)
        }
    }
}
