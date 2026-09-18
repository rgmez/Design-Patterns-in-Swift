import Foundation
import DesignPatterns
import Testing

@Suite("Command")
struct CommandTests {
    private static let clipID = "interview-opening"
    private static let splitClipID = "interview-answer"
    private static let assetID = "interview-4k"
    private static let assetDurationFrames = 900
    private static let initialSourceStartFrame = 120
    private static let initialSourceDurationFrames = 360
    private static let trimmedSourceStartFrame = 150
    private static let trimmedSourceDurationFrames = 240
    private static let movedTimelineStartFrame = 90
    private static let splitSourceFrame = 300
    private static let caption = "A safer rollout starts with evidence."
    private static let replacementCaption = "Ship the smallest safe edit."
    private static let missingClipID = "missing-clip"
    private static let historyLimit = 4
    private static let largeTimelineClipCount = 1_000

    private static let commandSequence: [TimelineCommand] = [
        .trim(
            clipID: clipID,
            sourceStartFrame: trimmedSourceStartFrame,
            durationFrames: trimmedSourceDurationFrames
        ),
        .move(
            clipID: clipID,
            timelineStartFrame: movedTimelineStartFrame
        ),
        .caption(clipID: clipID, text: caption),
        .split(
            clipID: clipID,
            sourceFrame: splitSourceFrame,
            newClipID: splitClipID
        )
    ]

    private static func makeClip(
        id: String = clipID,
        timelineStartFrame: Int = 0
    ) throws -> TimelineClip {
        try TimelineClip(
            id: id,
            assetID: assetID,
            assetDurationFrames: assetDurationFrames,
            sourceStartFrame: initialSourceStartFrame,
            sourceDurationFrames: initialSourceDurationFrames,
            timelineStartFrame: timelineStartFrame
        )
    }

    private static func makeTimeline(clipCount: Int = 1) throws -> VideoTimeline {
        let clips = try (0 ..< clipCount).map { index in
            try makeClip(
                id: index == 0 ? clipID : "\(clipID)-\(index)",
                timelineStartFrame: index * assetDurationFrames
            )
        }
        return try VideoTimeline(clips: clips)
    }

    private static func makeEditor(
        timeline: VideoTimeline? = nil,
        historyLimit: Int = historyLimit
    ) throws -> TimelineCommandEditor {
        TimelineCommandEditor(
            timeline: try timeline ?? makeTimeline(),
            historyLimit: historyLimit
        )
    }

    @Suite("Execution and reversal")
    struct ExecutionAndReversal {
        @Test("Executes, undoes, and redoes one shared command sequence")
        func roundTripsCommandSequence() throws {
            let initialTimeline = try CommandTests.makeTimeline()
            let editor = try CommandTests.makeEditor(timeline: initialTimeline)

            for command in CommandTests.commandSequence {
                try editor.execute(command)
            }
            let editedTimeline = editor.timeline

            for _ in CommandTests.commandSequence {
                #expect(try editor.undo())
            }
            #expect(editor.timeline == initialTimeline)
            #expect(try editor.undo() == false)

            for _ in CommandTests.commandSequence {
                #expect(try editor.redo())
            }
            #expect(editor.timeline == editedTimeline)
            #expect(try editor.redo() == false)
        }

        @Test("Split restores the original clip and can execute again")
        func reversesSplitWithFocusedState() throws {
            let initialTimeline = try CommandTests.makeTimeline()
            let editor = try CommandTests.makeEditor(timeline: initialTimeline)
            let command = TimelineCommand.split(
                clipID: CommandTests.clipID,
                sourceFrame: CommandTests.splitSourceFrame,
                newClipID: CommandTests.splitClipID
            )

            try editor.execute(command)
            #expect(editor.timeline.clips.count == 2)
            #expect(try editor.undo())
            #expect(editor.timeline == initialTimeline)
            #expect(try editor.redo())
            #expect(editor.timeline.clips.map(\.id) == [
                CommandTests.clipID,
                CommandTests.splitClipID
            ])
        }
    }

    @Suite("Bounded focused history")
    struct BoundedFocusedHistory {
        @Test("History size follows edit count instead of timeline size")
        func retainsOneFocusedReversalPerEdit() throws {
            let timeline = try CommandTests.makeTimeline(
                clipCount: CommandTests.largeTimelineClipCount
            )
            let editor = try CommandTests.makeEditor(timeline: timeline)

            for startFrame in 1 ... CommandTests.historyLimit + 1 {
                try editor.execute(
                    .move(
                        clipID: CommandTests.clipID,
                        timelineStartFrame: startFrame
                    )
                )
            }

            #expect(editor.undoDepth == CommandTests.historyLimit)
            #expect(editor.retainedReversalCount == CommandTests.historyLimit)

            for _ in 0 ..< CommandTests.historyLimit {
                #expect(try editor.undo())
            }
            #expect(
                editor.timeline.clips.first?.timelineStartFrame == 1
            )
        }

        @Test("A new command after undo discards the redo branch")
        func invalidatesRedoAfterNewCommand() throws {
            let editor = try CommandTests.makeEditor()
            try editor.execute(
                .caption(
                    clipID: CommandTests.clipID,
                    text: CommandTests.caption
                )
            )
            try editor.execute(
                .move(
                    clipID: CommandTests.clipID,
                    timelineStartFrame: CommandTests.movedTimelineStartFrame
                )
            )
            #expect(try editor.undo())
            #expect(editor.canRedo)

            try editor.execute(
                .caption(
                    clipID: CommandTests.clipID,
                    text: CommandTests.replacementCaption
                )
            )

            #expect(editor.canRedo == false)
            #expect(editor.redoDepth == 0)
        }

        @Test("A no-op command preserves existing redo history")
        func ignoresNoOpWithoutChangingHistory() throws {
            let initialTimeline = try CommandTests.makeTimeline()
            let editor = try CommandTests.makeEditor(timeline: initialTimeline)
            try editor.execute(
                .caption(
                    clipID: CommandTests.clipID,
                    text: CommandTests.caption
                )
            )
            #expect(try editor.undo())

            try editor.execute(
                .move(
                    clipID: CommandTests.clipID,
                    timelineStartFrame: 0
                )
            )

            #expect(editor.timeline == initialTimeline)
            #expect(editor.undoDepth == 0)
            #expect(editor.redoDepth == 1)
        }

        @Test("A rejected command preserves timeline and both histories")
        func rejectsWithoutChangingHistory() throws {
            let editor = try CommandTests.makeEditor()
            try editor.execute(
                .caption(
                    clipID: CommandTests.clipID,
                    text: CommandTests.caption
                )
            )
            try editor.execute(
                .move(
                    clipID: CommandTests.clipID,
                    timelineStartFrame: CommandTests.movedTimelineStartFrame
                )
            )
            #expect(try editor.undo())
            let timelineBeforeRejection = editor.timeline
            let undoDepthBeforeRejection = editor.undoDepth
            let redoDepthBeforeRejection = editor.redoDepth

            #expect(
                throws: TimelineEditError.clipNotFound(
                    CommandTests.missingClipID
                )
            ) {
                try editor.execute(
                    .move(
                        clipID: CommandTests.missingClipID,
                        timelineStartFrame:
                            CommandTests.movedTimelineStartFrame
                    )
                )
            }

            #expect(editor.timeline == timelineBeforeRejection)
            #expect(editor.undoDepth == undoDepthBeforeRejection)
            #expect(editor.redoDepth == redoDepthBeforeRejection)
        }
    }

    @Suite("Portable intent")
    struct PortableIntent {
        @Test("The shared command vocabulary survives offline serialization")
        func codableRoundTrip() throws {
            let data = try JSONEncoder().encode(CommandTests.commandSequence)

            let decoded = try JSONDecoder().decode(
                [TimelineCommand].self,
                from: data
            )

            #expect(decoded == CommandTests.commandSequence)
        }
    }
}
