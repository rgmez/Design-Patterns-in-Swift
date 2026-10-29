import DesignPatterns
import Testing

@Suite("Singleton")
struct SingletonTests {
    private static let recorderID = "voice-note-recorder"
    private static let previewID = "legacy-preview-resume"
    private static let recorderRequest = AudioSessionRequest(
        ownerID: recorderID,
        purpose: .recording
    )

    @Suite("Controlled production identity")
    struct ControlledProductionIdentity {
        @Test("Returns the same immutable process controller")
        func returnsOneSharedController() {
            #expect(
                AudioSessionController.shared === AudioSessionController.shared
            )
        }

        @Test("The runtime-created callback crosses the shared boundary")
        func callbackUsesSharedController() {
            let callback = LegacyPreviewResumeCallback()

            #expect(callback.controller === AudioSessionController.shared)
        }
    }

    @Suite("Injected clients")
    struct InjectedClients {
        @Test("An injected callback observes the controller's active owner")
        func injectedCallbackSharesOwnershipState() async throws {
            let systemSession = SingletonSystemAudioSessionSpy()
            let controller = AudioSessionController.isolated(
                systemSession: systemSession
            )
            let callback = LegacyPreviewResumeCallback(controller: controller)

            try await controller.acquire(SingletonTests.recorderRequest)

            await #expect(
                throws: AudioSessionControllerError.occupied(
                    activeOwnerID: SingletonTests.recorderID,
                    requestedOwnerID: SingletonTests.previewID
                )
            ) {
                try await callback.resumePreview(
                    ownerID: SingletonTests.previewID
                )
            }
            #expect(await systemSession.activations() == [.recording])
        }

        @Test("Fresh test instances never mutate the process singleton")
        func testInstancesRemainIsolated() async throws {
            let firstSystemSession = SingletonSystemAudioSessionSpy()
            let secondSystemSession = SingletonSystemAudioSessionSpy()
            let first = AudioSessionController.isolated(
                systemSession: firstSystemSession
            )
            let second = AudioSessionController.isolated(
                systemSession: secondSystemSession
            )

            try await first.acquire(SingletonTests.recorderRequest)

            #expect(first !== second)
            #expect(
                await first.activeRequest()
                    == SingletonTests.recorderRequest
            )
            #expect(await second.activeRequest() == nil)
            #expect(await firstSystemSession.activations() == [.recording])
            #expect(await secondSystemSession.activations().isEmpty)
        }
    }
}

private actor SingletonSystemAudioSessionSpy: SystemAudioSessionApplying {
    private var recordedActivations: [AudioSessionPurpose] = []

    func activate(for purpose: AudioSessionPurpose) {
        recordedActivations.append(purpose)
    }

    func deactivate() {}

    func activations() -> [AudioSessionPurpose] {
        recordedActivations
    }
}
