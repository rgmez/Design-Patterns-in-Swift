import Foundation
import DesignPatterns
import Testing

@Suite("Command pressure")
struct CommandPressureTests {
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
    private static let missingClipID = "missing-clip"
    private static let historyLimit = 4
    private static let largeTimelineClipCount = 1_000

    private static let toolbarSequence: [TimelineToolbarEdit] = [
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

    private static let keyboardSequence: [TimelineKeyboardEdit] = [
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

    private static let queuedSequence: [QueuedTimelineEdit] = [
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
    ) throws -> DirectTimelineHistoryEditor {
        DirectTimelineHistoryEditor(
            timeline: try timeline ?? makeTimeline(),
            historyLimit: historyLimit
        )
    }

    @Suite("Bounded snapshot history")
    struct BoundedSnapshotHistory {
        @Test("Undoes and redoes the complete edit sequence")
        func restoresSnapshotsInBothDirections() throws {
            let initialTimeline = try CommandPressureTests.makeTimeline()
            let editor = try CommandPressureTests.makeEditor(
                timeline: initialTimeline,
                historyLimit: 3
            )

            try editor.updateCaption(
                CommandPressureTests.caption,
                onClip: CommandPressureTests.clipID
            )
            let captionedTimeline = editor.timeline
            try editor.moveClip(
                id: CommandPressureTests.clipID,
                toTimelineStartFrame:
                    CommandPressureTests.movedTimelineStartFrame
            )
            let movedTimeline = editor.timeline
            try editor.trimClip(
                id: CommandPressureTests.clipID,
                toStartFrame: CommandPressureTests.trimmedSourceStartFrame,
                durationFrames:
                    CommandPressureTests.trimmedSourceDurationFrames
            )
            let trimmedTimeline = editor.timeline

            #expect(editor.undoLastEdit())
            #expect(editor.timeline == movedTimeline)
            #expect(editor.undoLastEdit())
            #expect(editor.timeline == captionedTimeline)
            #expect(editor.undoLastEdit())
            #expect(editor.timeline == initialTimeline)
            #expect(editor.undoLastEdit() == false)

            #expect(editor.redoLastEdit())
            #expect(editor.timeline == captionedTimeline)
            #expect(editor.redoLastEdit())
            #expect(editor.timeline == movedTimeline)
            #expect(editor.redoLastEdit())
            #expect(editor.timeline == trimmedTimeline)
            #expect(editor.redoLastEdit() == false)
        }

        @Test("A new edit after undo discards the redo branch")
        func invalidatesRedoAfterNewEdit() throws {
            let editor = try CommandPressureTests.makeEditor()
            try editor.updateCaption(
                CommandPressureTests.caption,
                onClip: CommandPressureTests.clipID
            )
            try editor.moveClip(
                id: CommandPressureTests.clipID,
                toTimelineStartFrame:
                    CommandPressureTests.movedTimelineStartFrame
            )
            #expect(editor.undoLastEdit())
            #expect(editor.canRedo)

            try editor.trimClip(
                id: CommandPressureTests.clipID,
                toStartFrame: CommandPressureTests.trimmedSourceStartFrame,
                durationFrames:
                    CommandPressureTests.trimmedSourceDurationFrames
            )

            #expect(editor.canRedo == false)
            #expect(editor.redoDepth == 0)
        }

        @Test("Five edits retain only four complete thousand-clip snapshots")
        func exposesSnapshotRetention() throws {
            let timeline = try CommandPressureTests.makeTimeline(
                clipCount: CommandPressureTests.largeTimelineClipCount
            )
            let editor = try CommandPressureTests.makeEditor(
                timeline: timeline
            )

            for startFrame in 1 ... CommandPressureTests.historyLimit + 1 {
                try editor.moveClip(
                    id: CommandPressureTests.clipID,
                    toTimelineStartFrame: startFrame
                )
            }

            #expect(editor.undoDepth == CommandPressureTests.historyLimit)
            #expect(
                editor.retainedSnapshotClipCount
                    == CommandPressureTests.largeTimelineClipCount
                        * CommandPressureTests.historyLimit
            )
        }

        @Test("A rejected edit preserves both history directions")
        func rejectsEditWithoutChangingHistory() throws {
            let editor = try CommandPressureTests.makeEditor()
            try editor.updateCaption(
                CommandPressureTests.caption,
                onClip: CommandPressureTests.clipID
            )
            try editor.moveClip(
                id: CommandPressureTests.clipID,
                toTimelineStartFrame:
                    CommandPressureTests.movedTimelineStartFrame
            )
            #expect(editor.undoLastEdit())
            let timelineBeforeRejection = editor.timeline
            let undoDepthBeforeRejection = editor.undoDepth
            let redoDepthBeforeRejection = editor.redoDepth

            #expect(
                throws: TimelineEditError.clipNotFound(
                    CommandPressureTests.missingClipID
                )
            ) {
                try editor.moveClip(
                    id: CommandPressureTests.missingClipID,
                    toTimelineStartFrame:
                        CommandPressureTests.movedTimelineStartFrame
                )
            }

            #expect(editor.timeline == timelineBeforeRejection)
            #expect(editor.undoDepth == undoDepthBeforeRejection)
            #expect(editor.redoDepth == redoDepthBeforeRejection)
        }
    }

    @Suite("Duplicated input routes")
    struct DuplicatedInputRoutes {
        @Test("Toolbar, keyboard, and replay duplicate the same four edits")
        func routesProduceTheSameTimeline() throws {
            let toolbarEditor = try CommandPressureTests.makeEditor()
            let keyboardEditor = try CommandPressureTests.makeEditor()
            let replayEditor = try CommandPressureTests.makeEditor()
            let toolbarRouter = DirectTimelineInputRouter(
                editor: toolbarEditor
            )
            let keyboardRouter = DirectTimelineInputRouter(
                editor: keyboardEditor
            )
            let replayRouter = DirectTimelineInputRouter(editor: replayEditor)

            for edit in CommandPressureTests.toolbarSequence {
                try toolbarRouter.perform(edit)
            }
            for edit in CommandPressureTests.keyboardSequence {
                try keyboardRouter.perform(edit)
            }
            for edit in CommandPressureTests.queuedSequence {
                try replayRouter.replay(edit)
            }

            #expect(toolbarEditor.timeline == keyboardEditor.timeline)
            #expect(toolbarEditor.timeline == replayEditor.timeline)
            #expect(toolbarEditor.undoDepth == CommandPressureTests.historyLimit)
            #expect(keyboardEditor.undoDepth == CommandPressureTests.historyLimit)
            #expect(replayEditor.undoDepth == CommandPressureTests.historyLimit)
        }

        @Test("Offline records serialize intent without local snapshots")
        func serializesQueuedIntent() throws {
            let data = try JSONEncoder().encode(
                CommandPressureTests.queuedSequence
            )

            let decoded = try JSONDecoder().decode(
                [QueuedTimelineEdit].self,
                from: data
            )

            #expect(decoded == CommandPressureTests.queuedSequence)
        }
    }
}
