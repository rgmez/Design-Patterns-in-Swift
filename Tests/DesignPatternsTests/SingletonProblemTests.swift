import DesignPatterns
import Testing

@Suite("Singleton problem")
struct SingletonProblemTests {
    private static let recorderID = "voice-note-recorder"
    private static let previewID = "voice-note-preview"
    private static let recorderRequest = AudioSessionRequest(
        ownerID: recorderID,
        purpose: .recording
    )
    private static let previewRequest = AudioSessionRequest(
        ownerID: previewID,
        purpose: .previewPlayback
    )

    @Suite("Exclusive ownership")
    struct ExclusiveOwnership {
        @Test("Configures and releases one injected process resource")
        func activatesAndDeactivates() async throws {
            let systemSession = AudioSessionPlatformSpy()
            let controller = AudioSessionController.isolated(
                systemSession: systemSession
            )

            try await controller.acquire(
                SingletonProblemTests.recorderRequest
            )

            #expect(
                await controller.activeRequest()
                    == SingletonProblemTests.recorderRequest
            )
            #expect(
                await systemSession.operations()
                    == [.activate(.recording)]
            )

            try await controller.release(
                ownerID: SingletonProblemTests.recorderID
            )

            #expect(await controller.activeRequest() == nil)
            #expect(
                await systemSession.operations()
                    == [.activate(.recording), .deactivate]
            )
        }

        @Test("Rejects another feature while recording owns the session")
        func rejectsCompetingOwner() async throws {
            let systemSession = AudioSessionPlatformSpy()
            let controller = AudioSessionController.isolated(
                systemSession: systemSession
            )

            try await controller.acquire(
                SingletonProblemTests.recorderRequest
            )

            await #expect(
                throws: AudioSessionControllerError.occupied(
                    activeOwnerID: SingletonProblemTests.recorderID,
                    requestedOwnerID: SingletonProblemTests.previewID
                )
            ) {
                try await controller.acquire(
                    SingletonProblemTests.previewRequest
                )
            }
            #expect(
                await systemSession.operations()
                    == [.activate(.recording)]
            )
        }

        @Test("Only the active feature can release the session")
        func rejectsReleaseFromAnotherOwner() async throws {
            let systemSession = AudioSessionPlatformSpy()
            let controller = AudioSessionController.isolated(
                systemSession: systemSession
            )

            try await controller.acquire(
                SingletonProblemTests.recorderRequest
            )

            await #expect(
                throws: AudioSessionControllerError.notOwner(
                    activeOwnerID: SingletonProblemTests.recorderID,
                    requestedOwnerID: SingletonProblemTests.previewID
                )
            ) {
                try await controller.release(
                    ownerID: SingletonProblemTests.previewID
                )
            }
            #expect(
                await controller.activeRequest()
                    == SingletonProblemTests.recorderRequest
            )
        }
    }

    @Suite("Concurrent requests")
    struct ConcurrentRequests {
        @Test("Reserves ownership before platform activation finishes")
        func reservesBeforeSuspension() async throws {
            let systemSession = AudioSessionPlatformSpy(
                suspendsActivation: true
            )
            let controller = AudioSessionController.isolated(
                systemSession: systemSession
            )

            async let recorderActivation: Void = controller.acquire(
                SingletonProblemTests.recorderRequest
            )
            await systemSession.waitUntilActivationStarts()

            await #expect(
                throws: AudioSessionControllerError.occupied(
                    activeOwnerID: SingletonProblemTests.recorderID,
                    requestedOwnerID: SingletonProblemTests.previewID
                )
            ) {
                try await controller.acquire(
                    SingletonProblemTests.previewRequest
                )
            }

            await systemSession.resumeActivation()
            try await recorderActivation

            #expect(
                await controller.activeRequest()
                    == SingletonProblemTests.recorderRequest
            )
        }
    }

    @Suite("Independent composition roots")
    struct IndependentCompositionRoots {
        @Test("One injected controller protects the process resource")
        func sharedReferenceRejectsCompetingRoot() async throws {
            let systemSession = AudioSessionPlatformSpy()
            let appController = AudioSessionController.isolated(
                systemSession: systemSession
            )
            let callbackController = appController

            try await appController.acquire(
                SingletonProblemTests.recorderRequest
            )

            await #expect(
                throws: AudioSessionControllerError.occupied(
                    activeOwnerID: SingletonProblemTests.recorderID,
                    requestedOwnerID: SingletonProblemTests.previewID
                )
            ) {
                try await callbackController.acquire(
                    SingletonProblemTests.previewRequest
                )
            }
            #expect(
                await systemSession.operations()
                    == [.activate(.recording)]
            )
        }

        @Test("Two roots can unknowingly activate the same process resource")
        func separateControllersBypassExclusiveOwnership() async throws {
            let systemSession = AudioSessionPlatformSpy()
            let appController = AudioSessionController.isolated(
                systemSession: systemSession
            )
            let callbackController = AudioSessionController.isolated(
                systemSession: systemSession
            )

            try await appController.acquire(
                SingletonProblemTests.recorderRequest
            )
            try await callbackController.acquire(
                SingletonProblemTests.previewRequest
            )

            #expect(
                await appController.activeRequest()
                    == SingletonProblemTests.recorderRequest
            )
            #expect(
                await callbackController.activeRequest()
                    == SingletonProblemTests.previewRequest
            )
            #expect(
                await systemSession.operations()
                    == [
                        .activate(.recording),
                        .activate(.previewPlayback)
                    ]
            )
        }
    }

    @Suite("Platform failures")
    struct PlatformFailures {
        @Test("Releases its reservation when system activation fails")
        func rollsBackFailedActivation() async throws {
            let systemSession = AudioSessionPlatformSpy(
                activationFailures: 1
            )
            let controller = AudioSessionController.isolated(
                systemSession: systemSession
            )

            await #expect(throws: AudioSessionPlatformSpy.Failure.activation) {
                try await controller.acquire(
                    SingletonProblemTests.recorderRequest
                )
            }

            try await controller.acquire(
                SingletonProblemTests.previewRequest
            )

            #expect(
                await controller.activeRequest()
                    == SingletonProblemTests.previewRequest
            )
        }

        @Test("Retains ownership when system deactivation fails")
        func keepsOwnershipAfterFailedDeactivation() async throws {
            let systemSession = AudioSessionPlatformSpy(
                deactivationFailures: 1
            )
            let controller = AudioSessionController.isolated(
                systemSession: systemSession
            )
            try await controller.acquire(
                SingletonProblemTests.recorderRequest
            )

            await #expect(
                throws: AudioSessionPlatformSpy.Failure.deactivation
            ) {
                try await controller.release(
                    ownerID: SingletonProblemTests.recorderID
                )
            }

            #expect(
                await controller.activeRequest()
                    == SingletonProblemTests.recorderRequest
            )
        }
    }
}

private actor AudioSessionPlatformSpy: SystemAudioSessionApplying {
    enum Failure: Error {
        case activation
        case deactivation
    }

    enum Operation: Equatable {
        case activate(AudioSessionPurpose)
        case deactivate
    }

    private var remainingActivationFailures: Int
    private var remainingDeactivationFailures: Int
    private let suspendsActivation: Bool
    private var recordedOperations: [Operation] = []
    private var activationHasStarted = false
    private var activationStartedContinuation: CheckedContinuation<Void, Never>?
    private var activationContinuation: CheckedContinuation<Void, Never>?

    init(
        activationFailures: Int = 0,
        deactivationFailures: Int = 0,
        suspendsActivation: Bool = false
    ) {
        remainingActivationFailures = activationFailures
        remainingDeactivationFailures = deactivationFailures
        self.suspendsActivation = suspendsActivation
    }

    func activate(for purpose: AudioSessionPurpose) async throws {
        recordedOperations.append(.activate(purpose))
        activationHasStarted = true
        activationStartedContinuation?.resume()
        activationStartedContinuation = nil

        if suspendsActivation {
            await withCheckedContinuation { continuation in
                activationContinuation = continuation
            }
        }

        guard remainingActivationFailures == 0 else {
            remainingActivationFailures -= 1
            throw Failure.activation
        }
    }

    func deactivate() async throws {
        recordedOperations.append(.deactivate)
        guard remainingDeactivationFailures == 0 else {
            remainingDeactivationFailures -= 1
            throw Failure.deactivation
        }
    }

    func operations() -> [Operation] {
        recordedOperations
    }

    func waitUntilActivationStarts() async {
        guard !activationHasStarted else {
            return
        }

        await withCheckedContinuation { continuation in
            activationStartedContinuation = continuation
        }
    }

    func resumeActivation() {
        activationContinuation?.resume()
        activationContinuation = nil
    }
}
