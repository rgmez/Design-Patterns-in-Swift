import Foundation
@testable import DesignPatterns
import Testing

@Suite("Memento")
struct MementoTests {
    private static let originalTitle = "Northern Spain by rail"
    private static let replacementTitle = "Unsaved replacement route"
    private static let madrid = ItineraryStop(city: "Madrid", nights: 2)
    private static let bilbao = ItineraryStop(city: "Bilbao", nights: 3)
    private static let porto = ItineraryStop(city: "Porto", nights: 2)
    private static let unsupportedVersions = [0, 2]

    private static func makeEditor(
        title: String = originalTitle
    ) -> ItineraryDraftEditor {
        var editor = ItineraryDraftEditor(title: title)
        editor.appendStop(madrid)
        editor.appendStop(bilbao)
        editor.selectTransport(.driving)
        editor.preferScenicRoutes(true)
        editor.avoidTolls(true)
        return editor
    }

    private static func incompatibleMemento(
        schemaVersion: Int
    ) throws -> ItineraryDraftMemento {
        struct RoutingPreferences: Codable {
            let prefersScenicRoutes: Bool
            let avoidsTolls: Bool
        }

        struct DraftState: Codable {
            let title: String
            let stops: [ItineraryStop]
            let transport: ItineraryTransport
            let routingPreferences: RoutingPreferences
        }

        struct Snapshot: Codable {
            let schemaVersion: Int
            let draft: DraftState
        }

        let snapshot = Snapshot(
            schemaVersion: schemaVersion,
            draft: DraftState(
                title: originalTitle,
                stops: [madrid, bilbao],
                transport: .driving,
                routingPreferences: RoutingPreferences(
                    prefersScenicRoutes: true,
                    avoidsTolls: true
                )
            )
        )
        return try ItineraryDraftMemento(
            serializedState: JSONEncoder().encode(snapshot)
        )
    }

    @Suite("Opaque external history")
    struct OpaqueExternalHistory {
        @Test("Restores a complete draft after the editor is recreated")
        func restoresRecreatedEditor() throws {
            let originalEditor = MementoTests.makeEditor()
            let savedPreview = originalEditor.preview
            var history = ItineraryDraftHistory()
            try history.save(originalEditor)

            var recreatedEditor = MementoTests.makeEditor(
                title: MementoTests.replacementTitle
            )
            recreatedEditor.appendStop(MementoTests.porto)
            recreatedEditor.selectTransport(.flight)
            recreatedEditor.preferScenicRoutes(false)
            recreatedEditor.avoidTolls(false)
            let didRestore = try history.restoreLatest(
                into: &recreatedEditor
            )

            #expect(didRestore)
            #expect(recreatedEditor.preview == savedPreview)
            #expect(history.availableRestorePointCount == 0)
        }

        @Test("Keeps a checkpoint independent from later editor mutations")
        func preservesCapturedState() throws {
            var editor = MementoTests.makeEditor()
            let capturedPreview = editor.preview
            var history = ItineraryDraftHistory()
            try history.save(editor)

            editor.rename(to: MementoTests.replacementTitle)
            editor.appendStop(MementoTests.porto)
            editor.selectTransport(.flight)
            editor.preferScenicRoutes(false)
            editor.avoidTolls(false)

            #expect(editor.preview != capturedPreview)
            #expect(try history.restoreLatest(into: &editor))
            #expect(editor.preview == capturedPreview)
            #expect(history.availableRestorePointCount == 0)
        }

        @Test("Restores newest checkpoints first and evicts the oldest")
        func boundsHistory() throws {
            var editor = MementoTests.makeEditor()
            var history = ItineraryDraftHistory(restorePointLimit: 2)
            try history.save(editor)

            editor.rename(to: "Second draft")
            try history.save(editor)

            editor.rename(to: "Third draft")
            try history.save(editor)
            editor.rename(to: "Unsaved edits")

            #expect(history.availableRestorePointCount == 2)
            #expect(try history.restoreLatest(into: &editor))
            #expect(editor.preview.title == "Third draft")
            #expect(try history.restoreLatest(into: &editor))
            #expect(editor.preview.title == "Second draft")
            #expect(try history.restoreLatest(into: &editor) == false)
        }

        @Test("Retains one complete opaque payload per restore point")
        func measuresFullSnapshotGrowth() throws {
            var editor = ItineraryDraftEditor(title: originalTitle)
            for index in 0 ..< 250 {
                editor.appendStop(
                    ItineraryStop(city: "Waypoint \(index)", nights: 1)
                )
            }
            var history = ItineraryDraftHistory(restorePointLimit: 4)
            try history.save(editor)
            let oneMementoByteCount = history.retainedEncodedByteCount

            for _ in 1 ..< 4 {
                try history.save(editor)
            }

            #expect(oneMementoByteCount > 0)
            #expect(
                history.retainedEncodedByteCount == oneMementoByteCount * 4
            )
        }
    }

    @Suite("Compatibility and atomic restoration")
    struct CompatibilityAndAtomicRestoration {
        @Test(
            "Rejects unsupported versions without changing the editor",
            arguments: MementoTests.unsupportedVersions
        )
        func rejectsUnsupportedVersion(_ schemaVersion: Int) throws {
            let memento = try MementoTests.incompatibleMemento(
                schemaVersion: schemaVersion
            )
            var history = ItineraryDraftHistory(restorePoints: [memento])
            var editor = MementoTests.makeEditor(
                title: MementoTests.replacementTitle
            )
            let previewBeforeRestore = editor.preview

            #expect(
                throws: ItineraryDraftSnapshotError.unsupportedVersion(
                    schemaVersion
                )
            ) {
                try history.restoreLatest(into: &editor)
            }
            #expect(editor.preview == previewBeforeRestore)
            #expect(history.availableRestorePointCount == 1)
        }

        @Test("Rejects malformed data without consuming the restore point")
        func rejectsMalformedData() {
            let memento = ItineraryDraftMemento(
                serializedState: Data("not a snapshot".utf8)
            )
            var history = ItineraryDraftHistory(restorePoints: [memento])
            var editor = MementoTests.makeEditor(
                title: MementoTests.replacementTitle
            )
            let previewBeforeRestore = editor.preview

            #expect(throws: DecodingError.self) {
                try history.restoreLatest(into: &editor)
            }
            #expect(editor.preview == previewBeforeRestore)
            #expect(history.availableRestorePointCount == 1)
        }
    }
}
