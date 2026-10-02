import DesignPatterns
import Testing

@Suite("Memento problem")
struct MementoProblemTests {
    private static let originalTitle = "Northern Spain by rail"
    private static let editedTitle = "Atlantic coast road trip"
    private static let madrid = ItineraryStop(city: "Madrid", nights: 2)
    private static let bilbao = ItineraryStop(city: "Bilbao", nights: 3)
    private static let porto = ItineraryStop(city: "Porto", nights: 2)

    private static func makeEditor(
        restorePointLimit: Int = 3
    ) -> DirectItineraryDraftEditor {
        var editor = DirectItineraryDraftEditor(
            title: originalTitle,
            restorePointLimit: restorePointLimit
        )
        editor.appendStop(madrid)
        editor.appendStop(bilbao)
        editor.preferScenicRoutes(true)
        return editor
    }

    @Suite("Private draft editing")
    struct PrivateDraftEditing {
        @Test("Exposes an immutable preview of the current draft")
        func exposesPreview() {
            var editor = MementoProblemTests.makeEditor()

            editor.selectTransport(.driving)
            editor.avoidTolls(true)

            #expect(editor.preview.title == MementoProblemTests.originalTitle)
            #expect(
                editor.preview.stops == [
                    MementoProblemTests.madrid,
                    MementoProblemTests.bilbao
                ]
            )
            #expect(editor.preview.transport == .driving)
            #expect(editor.preview.routeProfile == .scenicAndTollFree)
        }
    }

    @Suite("Restore-point ownership")
    struct RestorePointOwnership {
        @Test("Restores all draft fields from an independent value copy")
        func restoresIndependentCopy() {
            var editor = MementoProblemTests.makeEditor()
            let savedPreview = editor.preview
            editor.saveRestorePoint()

            editor.rename(to: MementoProblemTests.editedTitle)
            editor.appendStop(MementoProblemTests.porto)
            editor.selectTransport(.flight)
            editor.preferScenicRoutes(false)
            editor.avoidTolls(true)

            #expect(editor.preview != savedPreview)
            let didRestore = editor.restoreLatest()

            #expect(didRestore)
            #expect(editor.preview == savedPreview)
            #expect(editor.availableRestorePointCount == 0)
        }

        @Test("Restores newest checkpoints first and discards the oldest")
        func boundsRestoreHistory() {
            var editor = MementoProblemTests.makeEditor(
                restorePointLimit: 2
            )
            editor.saveRestorePoint()

            editor.rename(to: "Second draft")
            editor.saveRestorePoint()

            editor.rename(to: "Third draft")
            editor.saveRestorePoint()

            editor.rename(to: "Unsaved edits")

            #expect(editor.availableRestorePointCount == 2)
            let didRestoreThirdDraft = editor.restoreLatest()
            #expect(didRestoreThirdDraft)
            #expect(editor.preview.title == "Third draft")
            let didRestoreSecondDraft = editor.restoreLatest()
            #expect(didRestoreSecondDraft)
            #expect(editor.preview.title == "Second draft")
            let didRestoreDiscardedDraft = editor.restoreLatest()
            #expect(didRestoreDiscardedDraft == false)
        }

        @Test("Leaves the draft unchanged when no restore point exists")
        func preservesDraftWithoutRestorePoint() {
            var editor = MementoProblemTests.makeEditor()
            let currentPreview = editor.preview
            let didRestore = editor.restoreLatest()

            #expect(didRestore == false)
            #expect(editor.preview == currentPreview)
        }
    }
}
