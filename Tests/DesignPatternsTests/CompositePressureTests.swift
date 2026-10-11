import DesignPatterns
import Testing

@Suite("Composite pressure")
struct CompositePressureTests {
    private static let inspectionPlan = WorkspaceFile(
        id: "file-inspection-plan",
        name: "Inspection plan.pdf",
        byteCount: 240_000,
        isDownloadable: true,
        isStoredOffline: true
    )
    private static let safetyVideo = WorkspaceFile(
        id: "file-safety-video",
        name: "Safety briefing.mov",
        byteCount: 8_200_000,
        isDownloadable: true,
        isStoredOffline: false
    )
    private static let checklist = WorkspaceFile(
        id: "file-checklist",
        name: "Site checklist.pdf",
        byteCount: 85_000,
        isDownloadable: true,
        isStoredOffline: true
    )
    private static let restrictedBlueprint = WorkspaceFile(
        id: "file-blueprint",
        name: "Restricted blueprint.pdf",
        byteCount: 1_600_000,
        isDownloadable: false,
        isStoredOffline: true
    )
    private static let visitFolder = DirectWorkspaceEntry.folder(
        DirectWorkspaceFolder(
            name: "Site visit",
            entries: [
                .folder(
                    DirectWorkspaceFolder(
                        name: "Briefing",
                        entries: [
                            .file(inspectionPlan),
                            .file(safetyVideo)
                        ]
                    )
                ),
                .file(checklist),
                .file(restrictedBlueprint)
            ]
        )
    )
    private static let searchIndexer = DirectWorkspaceSearchIndexer()
    private static let cleanupPreview = DirectWorkspaceCleanupPreview()

    @Suite("Search indexing")
    struct SearchIndexing {
        @Test("Builds depth-first records with complete workspace paths")
        func indexesNestedFiles() {
            let records = CompositePressureTests.searchIndexer.records(
                in: CompositePressureTests.visitFolder
            )

            #expect(
                records == [
                    WorkspaceSearchRecord(
                        fileID: CompositePressureTests.inspectionPlan.id,
                        displayPath: "Site visit / Briefing / Inspection plan.pdf"
                    ),
                    WorkspaceSearchRecord(
                        fileID: CompositePressureTests.safetyVideo.id,
                        displayPath: "Site visit / Briefing / Safety briefing.mov"
                    ),
                    WorkspaceSearchRecord(
                        fileID: CompositePressureTests.checklist.id,
                        displayPath: "Site visit / Site checklist.pdf"
                    ),
                    WorkspaceSearchRecord(
                        fileID: CompositePressureTests.restrictedBlueprint.id,
                        displayPath: "Site visit / Restricted blueprint.pdf"
                    )
                ]
            )
        }

        @Test("Indexes one file without inventing a folder path")
        func indexesOneFile() {
            let records = CompositePressureTests.searchIndexer.records(
                in: .file(CompositePressureTests.inspectionPlan)
            )

            #expect(
                records == [
                    WorkspaceSearchRecord(
                        fileID: CompositePressureTests.inspectionPlan.id,
                        displayPath: CompositePressureTests.inspectionPlan.name
                    )
                ]
            )
        }
    }

    @Suite("Storage cleanup")
    struct StorageCleanup {
        @Test("Sums only files currently stored offline")
        func sumsStoredFiles() {
            let bytes = CompositePressureTests.cleanupPreview.reclaimableBytes(
                in: CompositePressureTests.visitFolder
            )
            let expectedBytes = CompositePressureTests.inspectionPlan.byteCount
                + CompositePressureTests.checklist.byteCount
                + CompositePressureTests.restrictedBlueprint.byteCount

            #expect(bytes == expectedBytes)
        }

        @Test("Treats restricted stored data as reclaimable")
        func includesRestrictedStoredFile() {
            let bytes = CompositePressureTests.cleanupPreview.reclaimableBytes(
                in: .file(CompositePressureTests.restrictedBlueprint)
            )

            #expect(
                bytes == CompositePressureTests.restrictedBlueprint.byteCount
            )
        }
    }
}
