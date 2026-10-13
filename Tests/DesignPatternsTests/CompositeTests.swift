import DesignPatterns
import Testing

@Suite("Composite")
struct CompositeTests {
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
    private static let briefingFolder = WorkspaceFolder(
        name: "Briefing",
        children: [
            inspectionPlan,
            safetyVideo
        ]
    )
    private static let visitFolder = WorkspaceFolder(
        name: "Site visit",
        children: [
            briefingFolder,
            checklist,
            restrictedBlueprint
        ]
    )
    private static let offlinePreview = WorkspaceOfflineSelectionPreview()
    private static let searchIndexer = WorkspaceSearchIndexer()
    private static let cleanupPreview = WorkspaceCleanupPreview()

    @Suite("Uniform traversal")
    struct UniformTraversal {
        @Test("Accepts a file and nested folder through one component boundary")
        func substitutesLeafAndComposite() {
            let selections: [any WorkspaceComponent] = [
                CompositeTests.inspectionPlan,
                CompositeTests.visitFolder
            ]
            let summaries = selections.map { component in
                CompositeTests.offlinePreview.summary(for: component)
            }
            let folderBytes = CompositeTests.inspectionPlan.byteCount
                + CompositeTests.safetyVideo.byteCount
                + CompositeTests.checklist.byteCount
                + CompositeTests.restrictedBlueprint.byteCount

            #expect(
                summaries == [
                    OfflineSelectionSummary(
                        fileCount: 1,
                        byteCount: CompositeTests.inspectionPlan.byteCount,
                        isDownloadable: true
                    ),
                    OfflineSelectionSummary(
                        fileCount: 4,
                        byteCount: folderBytes,
                        isDownloadable: false
                    )
                ]
            )
        }

        @Test("Keeps an empty folder explicit and unavailable")
        func summarizesEmptyFolder() {
            let emptyFolder = WorkspaceFolder(
                name: "Coming soon",
                children: []
            )

            #expect(emptyFolder.fileLocations.isEmpty)
            #expect(
                CompositeTests.offlinePreview.summary(for: emptyFolder)
                    == OfflineSelectionSummary(
                        fileCount: 0,
                        byteCount: 0,
                        isDownloadable: false
                    )
            )
        }

        @Test("Keeps a reused subtree contextual to each parent")
        func reusesSubtreeWithoutParentState() {
            let northVisit = WorkspaceFolder(
                name: "North visit",
                children: [CompositeTests.briefingFolder]
            )
            let southVisit = WorkspaceFolder(
                name: "South visit",
                children: [CompositeTests.briefingFolder]
            )

            #expect(
                northVisit.fileLocations.map(\.displayPath) == [
                    "North visit / Briefing / Inspection plan.pdf",
                    "North visit / Briefing / Safety briefing.mov"
                ]
            )
            #expect(
                southVisit.fileLocations.map(\.displayPath) == [
                    "South visit / Briefing / Inspection plan.pdf",
                    "South visit / Briefing / Safety briefing.mov"
                ]
            )
            #expect(
                CompositeTests.briefingFolder.fileLocations.map(\.displayPath) == [
                    "Briefing / Inspection plan.pdf",
                    "Briefing / Safety briefing.mov"
                ]
            )
        }
    }

    @Suite("Consumer policies")
    struct ConsumerPolicies {
        @Test("Preserves depth-first paths without client branching")
        func indexesNestedFiles() {
            let records = CompositeTests.searchIndexer.records(
                in: CompositeTests.visitFolder
            )

            #expect(
                records.map(\.displayPath) == [
                    "Site visit / Briefing / Inspection plan.pdf",
                    "Site visit / Briefing / Safety briefing.mov",
                    "Site visit / Site checklist.pdf",
                    "Site visit / Restricted blueprint.pdf"
                ]
            )
        }

        @Test("Keeps cleanup independent from download permission")
        func sumsStoredFiles() {
            let bytes = CompositeTests.cleanupPreview.reclaimableBytes(
                in: CompositeTests.visitFolder
            )
            let expectedBytes = CompositeTests.inspectionPlan.byteCount
                + CompositeTests.checklist.byteCount
                + CompositeTests.restrictedBlueprint.byteCount

            #expect(bytes == expectedBytes)
        }
    }

    @Suite("Leaf-only operations")
    struct LeafOnlyOperations {
        @Test("Creates an open request only from a concrete file")
        func opensConcreteFile() {
            #expect(
                CompositeTests.inspectionPlan.openRequest()
                    == WorkspaceFileOpenRequest(
                        fileID: CompositeTests.inspectionPlan.id
                    )
            )
        }
    }
}
