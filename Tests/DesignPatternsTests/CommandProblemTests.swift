import DesignPatterns
import Testing

@Suite("Command problem")
struct CommandProblemTests {
    private static let clipID = "interview-opening"
    private static let splitClipID = "interview-answer"
    private static let assetID = "interview-4k"
    private static let assetDurationFrames = 900
    private static let initialSourceStartFrame = 120
    private static let initialSourceDurationFrames = 360
    private static let initialTimelineStartFrame = 0
    private static let trimmedSourceStartFrame = 150
    private static let trimmedSourceDurationFrames = 240
    private static let movedTimelineStartFrame = 90
    private static let splitSourceFrame = 300
    private static let caption = "A safer rollout starts with evidence."
    private static let missingClipID = "missing-clip"

    struct InvalidClipScenario: Sendable, CustomTestStringConvertible {
        let name: String
        let sourceStartFrame: Int
        let sourceDurationFrames: Int
        let timelineStartFrame: Int
        let expectedError: TimelineEditError

        var testDescription: String { name }
    }

    private static let invalidClipScenarios = [
        InvalidClipScenario(
            name: "negative source start",
            sourceStartFrame: -1,
            sourceDurationFrames: initialSourceDurationFrames,
            timelineStartFrame: initialTimelineStartFrame,
            expectedError: .invalidSourceRange(
                startFrame: -1,
                durationFrames: initialSourceDurationFrames,
                assetDurationFrames: assetDurationFrames
            )
        ),
        InvalidClipScenario(
            name: "source end outside asset",
            sourceStartFrame: assetDurationFrames - 10,
            sourceDurationFrames: 20,
            timelineStartFrame: initialTimelineStartFrame,
            expectedError: .invalidSourceRange(
                startFrame: assetDurationFrames - 10,
                durationFrames: 20,
                assetDurationFrames: assetDurationFrames
            )
        ),
        InvalidClipScenario(
            name: "negative timeline start",
            sourceStartFrame: initialSourceStartFrame,
            sourceDurationFrames: initialSourceDurationFrames,
            timelineStartFrame: -1,
            expectedError: .invalidTimelineStart(-1)
        )
    ]

    private static func makeClip(id: String = clipID) throws -> TimelineClip {
        try TimelineClip(
            id: id,
            assetID: assetID,
            assetDurationFrames: assetDurationFrames,
            sourceStartFrame: initialSourceStartFrame,
            sourceDurationFrames: initialSourceDurationFrames,
            timelineStartFrame: initialTimelineStartFrame
        )
    }

    private static func makeTimeline() throws -> VideoTimeline {
        try VideoTimeline(clips: [makeClip()])
    }

    @Suite("Direct edit actions")
    struct DirectEditActions {
        @Test("Trims the selected source range")
        func trimsClip() throws {
            let editor = DirectTimelineEditor(
                timeline: try CommandProblemTests.makeTimeline()
            )

            try editor.trimClip(
                id: CommandProblemTests.clipID,
                toStartFrame: CommandProblemTests.trimmedSourceStartFrame,
                durationFrames: CommandProblemTests.trimmedSourceDurationFrames
            )

            let clip = try #require(editor.timeline.clips.first)
            #expect(
                clip.sourceStartFrame
                    == CommandProblemTests.trimmedSourceStartFrame
            )
            #expect(
                clip.sourceDurationFrames
                    == CommandProblemTests.trimmedSourceDurationFrames
            )
        }

        @Test("Moves a clip without changing its source range")
        func movesClip() throws {
            let editor = DirectTimelineEditor(
                timeline: try CommandProblemTests.makeTimeline()
            )

            try editor.moveClip(
                id: CommandProblemTests.clipID,
                toTimelineStartFrame: CommandProblemTests.movedTimelineStartFrame
            )

            let clip = try #require(editor.timeline.clips.first)
            #expect(
                clip.timelineStartFrame
                    == CommandProblemTests.movedTimelineStartFrame
            )
            #expect(
                clip.sourceStartFrame
                    == CommandProblemTests.initialSourceStartFrame
            )
            #expect(
                clip.sourceDurationFrames
                    == CommandProblemTests.initialSourceDurationFrames
            )
        }

        @Test("Updates the clip caption")
        func updatesCaption() throws {
            let editor = DirectTimelineEditor(
                timeline: try CommandProblemTests.makeTimeline()
            )

            try editor.updateCaption(
                CommandProblemTests.caption,
                onClip: CommandProblemTests.clipID
            )

            #expect(
                editor.timeline.clips.first?.caption
                    == CommandProblemTests.caption
            )
        }

        @Test("Splits a clip into contiguous source and timeline ranges")
        func splitsClip() throws {
            let editor = DirectTimelineEditor(
                timeline: try CommandProblemTests.makeTimeline()
            )

            try editor.splitClip(
                id: CommandProblemTests.clipID,
                atSourceFrame: CommandProblemTests.splitSourceFrame,
                newClipID: CommandProblemTests.splitClipID
            )

            let leading = try #require(editor.timeline.clips.first)
            let trailing = try #require(editor.timeline.clips.last)
            #expect(editor.timeline.clips.count == 2)
            #expect(leading.id == CommandProblemTests.clipID)
            #expect(
                leading.sourceDurationFrames
                    == CommandProblemTests.splitSourceFrame
                        - CommandProblemTests.initialSourceStartFrame
            )
            #expect(trailing.id == CommandProblemTests.splitClipID)
            #expect(
                trailing.sourceStartFrame
                    == CommandProblemTests.splitSourceFrame
            )
            #expect(
                trailing.timelineStartFrame
                    == leading.timelineStartFrame
                        + leading.sourceDurationFrames
            )
        }
    }

    @Suite("One-step snapshot undo")
    struct OneStepSnapshotUndo {
        @Test("Restores the complete timeline before the latest edit")
        func undoesLatestEdit() throws {
            let initialTimeline = try CommandProblemTests.makeTimeline()
            let editor = DirectTimelineEditor(timeline: initialTimeline)
            try editor.updateCaption(
                CommandProblemTests.caption,
                onClip: CommandProblemTests.clipID
            )

            let didUndo = editor.undoLastEdit()

            #expect(didUndo)
            #expect(editor.timeline == initialTimeline)
            #expect(editor.canUndo == false)
        }

        @Test("Keeps only the snapshot before the most recent edit")
        func keepsOnlyLatestSnapshot() throws {
            let editor = DirectTimelineEditor(
                timeline: try CommandProblemTests.makeTimeline()
            )
            try editor.updateCaption(
                CommandProblemTests.caption,
                onClip: CommandProblemTests.clipID
            )
            let timelineBeforeMove = editor.timeline
            try editor.moveClip(
                id: CommandProblemTests.clipID,
                toTimelineStartFrame: CommandProblemTests.movedTimelineStartFrame
            )

            let firstUndo = editor.undoLastEdit()
            let secondUndo = editor.undoLastEdit()

            #expect(firstUndo)
            #expect(editor.timeline == timelineBeforeMove)
            #expect(secondUndo == false)
        }
    }
}

extension CommandProblemTests {
    @Suite("Rejected edits")
    struct RejectedEdits {
        @Test(
            "Rejects invalid clip boundaries",
            arguments: CommandProblemTests.invalidClipScenarios
        )
        func rejectsInvalidClipBoundary(
            _ scenario: CommandProblemTests.InvalidClipScenario
        ) {
            #expect(throws: scenario.expectedError) {
                try TimelineClip(
                    id: CommandProblemTests.clipID,
                    assetID: CommandProblemTests.assetID,
                    assetDurationFrames:
                        CommandProblemTests.assetDurationFrames,
                    sourceStartFrame: scenario.sourceStartFrame,
                    sourceDurationFrames: scenario.sourceDurationFrames,
                    timelineStartFrame: scenario.timelineStartFrame
                )
            }
        }

        @Test("Rejects duplicate clip identifiers")
        func rejectsDuplicateClipID() throws {
            let firstClip = try CommandProblemTests.makeClip()
            let duplicateClip = try CommandProblemTests.makeClip()

            #expect(
                throws: TimelineEditError.duplicateClipID(
                    CommandProblemTests.clipID
                )
            ) {
                try VideoTimeline(clips: [firstClip, duplicateClip])
            }
        }

        @Test("Leaves timeline and undo state untouched after a rejected edit")
        func rejectsMissingClipAtomically() throws {
            let initialTimeline = try CommandProblemTests.makeTimeline()
            let editor = DirectTimelineEditor(timeline: initialTimeline)
            try editor.updateCaption(
                CommandProblemTests.caption,
                onClip: CommandProblemTests.clipID
            )
            let timelineBeforeRejectedEdit = editor.timeline

            #expect(
                throws: TimelineEditError.clipNotFound(
                    CommandProblemTests.missingClipID
                )
            ) {
                try editor.moveClip(
                    id: CommandProblemTests.missingClipID,
                    toTimelineStartFrame:
                    CommandProblemTests.movedTimelineStartFrame
                )
            }
            #expect(editor.timeline == timelineBeforeRejectedEdit)
            #expect(editor.canUndo)
            #expect(editor.undoLastEdit())
            #expect(editor.timeline == initialTimeline)
        }

        @Test("Rejects a split at the source-range boundary")
        func rejectsBoundarySplit() throws {
            let editor = DirectTimelineEditor(
                timeline: try CommandProblemTests.makeTimeline()
            )

            #expect(
                throws: TimelineEditError.invalidSplitFrame(
                    clipID: CommandProblemTests.clipID,
                    splitFrame:
                        CommandProblemTests.initialSourceStartFrame
                )
            ) {
                try editor.splitClip(
                    id: CommandProblemTests.clipID,
                    atSourceFrame:
                        CommandProblemTests.initialSourceStartFrame,
                    newClipID: CommandProblemTests.splitClipID
                )
            }
        }
    }
}
