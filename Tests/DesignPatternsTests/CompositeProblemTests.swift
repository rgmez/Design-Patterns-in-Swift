import DesignPatterns
import Testing

@Suite("Composite problem")
struct CompositeProblemTests {
    private static let inspectionPlan = WorkspaceFile(
        id: "file-inspection-plan",
        name: "Inspection plan.pdf",
        byteCount: 240_000,
        isDownloadable: true
    )
    private static let safetyVideo = WorkspaceFile(
        id: "file-safety-video",
        name: "Safety briefing.mov",
        byteCount: 8_200_000,
        isDownloadable: true
    )
    private static let checklist = WorkspaceFile(
        id: "file-checklist",
        name: "Site checklist.pdf",
        byteCount: 85_000,
        isDownloadable: true
    )
    private static let restrictedBlueprint = WorkspaceFile(
        id: "file-blueprint",
        name: "Restricted blueprint.pdf",
        byteCount: 1_600_000,
        isDownloadable: false
    )
    private static let briefingFolder = DirectWorkspaceEntry.folder(
        WorkspaceFolder(
            name: "Briefing",
            entries: [
                .file(inspectionPlan),
                .file(safetyVideo)
            ]
        )
    )
    private static let siteVisitFolder = DirectWorkspaceEntry.folder(
        WorkspaceFolder(
            name: "Site visit",
            entries: [
                briefingFolder,
                .file(checklist)
            ]
        )
    )
    private static let preview = DirectOfflineSelectionPreview()

    @Suite("Individual files")
    struct IndividualFiles {
        @Test("Summarizes one file without hierarchy machinery")
        func summarizesOneFile() {
            let summary = CompositeProblemTests.preview.summary(
                for: .file(CompositeProblemTests.inspectionPlan)
            )

            #expect(
                summary == OfflineSelectionSummary(
                    fileCount: 1,
                    byteCount: CompositeProblemTests.inspectionPlan.byteCount,
                    isDownloadable: true
                )
            )
        }
    }

    @Suite("Nested folders")
    struct NestedFolders {
        @Test("Aggregates every file through arbitrarily nested folders")
        func summarizesNestedFolder() {
            let summary = CompositeProblemTests.preview.summary(
                for: CompositeProblemTests.siteVisitFolder
            )
            let expectedBytes = CompositeProblemTests.inspectionPlan.byteCount
                + CompositeProblemTests.safetyVideo.byteCount
                + CompositeProblemTests.checklist.byteCount

            #expect(
                summary == OfflineSelectionSummary(
                    fileCount: 3,
                    byteCount: expectedBytes,
                    isDownloadable: true
                )
            )
        }

        @Test("Propagates one restricted file through the complete folder")
        func propagatesRestrictedFile() {
            let folder = DirectWorkspaceEntry.folder(
                WorkspaceFolder(
                    name: "Complete visit pack",
                    entries: [
                        CompositeProblemTests.siteVisitFolder,
                        .file(CompositeProblemTests.restrictedBlueprint)
                    ]
                )
            )
            let summary = CompositeProblemTests.preview.summary(for: folder)
            let expectedBytes = CompositeProblemTests.inspectionPlan.byteCount
                + CompositeProblemTests.safetyVideo.byteCount
                + CompositeProblemTests.checklist.byteCount
                + CompositeProblemTests.restrictedBlueprint.byteCount

            #expect(
                summary == OfflineSelectionSummary(
                    fileCount: 4,
                    byteCount: expectedBytes,
                    isDownloadable: false
                )
            )
        }

        @Test("Treats an empty folder as unavailable for offline selection")
        func rejectsEmptyFolder() {
            let emptyFolder = DirectWorkspaceEntry.folder(
                WorkspaceFolder(
                    name: "Coming soon",
                    entries: []
                )
            )

            #expect(
                CompositeProblemTests.preview.summary(for: emptyFolder)
                    == OfflineSelectionSummary(
                        fileCount: 0,
                        byteCount: 0,
                        isDownloadable: false
                    )
            )
        }
    }
}
