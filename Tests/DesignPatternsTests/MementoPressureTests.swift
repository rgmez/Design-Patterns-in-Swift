import Foundation
import DesignPatterns
import Testing

@Suite("Memento pressure")
struct MementoPressureTests {
    private static let originalTitle = "Northern Spain by rail"
    private static let replacementTitle = "Unsaved replacement route"
    private static let madrid = ItineraryStop(city: "Madrid", nights: 2)
    private static let bilbao = ItineraryStop(city: "Bilbao", nights: 3)
    private static let historyLimit = 4
    private static let largeItineraryStopCount = 250
    private static let unsupportedVersions = [0, 2]

    private static func makeEditor(
        title: String = originalTitle
    ) -> DirectItineraryDraftEditor {
        var editor = DirectItineraryDraftEditor(title: title)
        editor.appendStop(madrid)
        editor.appendStop(bilbao)
        editor.selectTransport(.driving)
        editor.preferScenicRoutes(true)
        editor.avoidTolls(true)
        return editor
    }

    private static func makeLargeEditor() -> DirectItineraryDraftEditor {
        var editor = DirectItineraryDraftEditor(title: originalTitle)
        for index in 0 ..< largeItineraryStopCount {
            editor.appendStop(
                ItineraryStop(city: "Waypoint \(index)", nights: 1)
            )
        }
        return editor
    }

    private static func encodedSnapshot(
        schemaVersion: Int
    ) throws -> Data {
        let snapshot = DirectItineraryDraftSnapshotV1(
            schemaVersion: schemaVersion,
            title: originalTitle,
            stops: [madrid, bilbao],
            transport: .driving,
            prefersScenicRoutes: true,
            avoidsTolls: true
        )
        return try JSONEncoder().encode(snapshot)
    }

    @Suite("External history ownership")
    struct ExternalHistoryOwnership {
        @Test("Restores a complete draft after the editor is recreated")
        func restoresRecreatedEditor() throws {
            let originalEditor = MementoPressureTests.makeEditor()
            let savedPreview = originalEditor.preview
            var archive = DirectItineraryDraftArchive()
            try archive.save(originalEditor)

            var recreatedEditor = MementoPressureTests.makeEditor(
                title: MementoPressureTests.replacementTitle
            )
            recreatedEditor.preferScenicRoutes(false)
            recreatedEditor.avoidTolls(false)
            let didRestore = try archive.restoreLatest(
                into: &recreatedEditor
            )

            #expect(didRestore)
            #expect(recreatedEditor.preview == savedPreview)
            #expect(recreatedEditor.preview.routeProfile == .scenicAndTollFree)
            #expect(archive.availableRestorePointCount == 0)
        }

        @Test("Retains one full encoded route for every restore point")
        func measuresFullSnapshotGrowth() throws {
            let editor = MementoPressureTests.makeLargeEditor()
            var archive = DirectItineraryDraftArchive(
                restorePointLimit: MementoPressureTests.historyLimit
            )
            try archive.save(editor)
            let oneSnapshotByteCount = archive.retainedEncodedByteCount

            for _ in 1 ..< MementoPressureTests.historyLimit {
                try archive.save(editor)
            }

            #expect(oneSnapshotByteCount > 0)
            #expect(
                archive.retainedEncodedByteCount
                    == oneSnapshotByteCount * MementoPressureTests.historyLimit
            )
            #expect(
                editor.preview.stops.count
                    == MementoPressureTests.largeItineraryStopCount
            )
        }
    }

    @Suite("Snapshot compatibility")
    struct SnapshotCompatibility {
        @Test(
            "Rejects unsupported versions without consuming the restore point",
            arguments: MementoPressureTests.unsupportedVersions
        )
        func rejectsUnsupportedVersion(_ schemaVersion: Int) throws {
            let encodedSnapshot = try MementoPressureTests.encodedSnapshot(
                schemaVersion: schemaVersion
            )
            var archive = DirectItineraryDraftArchive(
                encodedRestorePoints: [encodedSnapshot]
            )
            var editor = MementoPressureTests.makeEditor(
                title: MementoPressureTests.replacementTitle
            )
            let previewBeforeRestore = editor.preview

            #expect(
                throws: ItineraryDraftSnapshotError.unsupportedVersion(
                    schemaVersion
                )
            ) {
                try archive.restoreLatest(into: &editor)
            }

            #expect(editor.preview == previewBeforeRestore)
            #expect(archive.availableRestorePointCount == 1)
        }
    }
}
