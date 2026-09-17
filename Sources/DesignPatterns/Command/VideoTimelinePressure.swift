public final class DirectTimelineHistoryEditor {
    public private(set) var timeline: VideoTimeline
    public var canUndo: Bool { !undoHistory.isEmpty }
    public var canRedo: Bool { !redoHistory.isEmpty }
    public var undoDepth: Int { undoHistory.count }
    public var redoDepth: Int { redoHistory.count }
    public var retainedSnapshotClipCount: Int {
        undoHistory.reduce(0) { $0 + $1.clips.count }
            + redoHistory.reduce(0) { $0 + $1.clips.count }
    }

    private let historyLimit: Int
    private var undoHistory: [VideoTimeline] = []
    private var redoHistory: [VideoTimeline] = []

    public init(timeline: VideoTimeline, historyLimit: Int) {
        precondition(historyLimit > 0, "History must retain at least one edit.")
        self.timeline = timeline
        self.historyLimit = historyLimit
    }

    public func trimClip(
        id: String,
        toStartFrame startFrame: Int,
        durationFrames: Int
    ) throws {
        try applyEdit { timeline in
            try timeline.trimClip(
                id: id,
                toStartFrame: startFrame,
                durationFrames: durationFrames
            )
        }
    }

    public func moveClip(
        id: String,
        toTimelineStartFrame startFrame: Int
    ) throws {
        try applyEdit { timeline in
            try timeline.moveClip(
                id: id,
                toTimelineStartFrame: startFrame
            )
        }
    }

    public func updateCaption(
        _ caption: String?,
        onClip id: String
    ) throws {
        try applyEdit { timeline in
            try timeline.updateCaption(caption, onClip: id)
        }
    }

    public func splitClip(
        id: String,
        atSourceFrame splitFrame: Int,
        newClipID: String
    ) throws {
        try applyEdit { timeline in
            try timeline.splitClip(
                id: id,
                atSourceFrame: splitFrame,
                newClipID: newClipID
            )
        }
    }

    @discardableResult
    public func undoLastEdit() -> Bool {
        guard let previousTimeline = undoHistory.popLast() else { return false }

        redoHistory.append(timeline)
        timeline = previousTimeline
        return true
    }

    @discardableResult
    public func redoLastEdit() -> Bool {
        guard let nextTimeline = redoHistory.popLast() else { return false }

        undoHistory.append(timeline)
        timeline = nextTimeline
        return true
    }

    private func applyEdit(
        _ edit: (inout VideoTimeline) throws -> Void
    ) throws {
        var candidate = timeline
        try edit(&candidate)
        guard candidate != timeline else { return }

        undoHistory.append(timeline)
        let overflow = undoHistory.count - historyLimit
        if overflow > 0 {
            undoHistory.removeFirst(overflow)
        }
        redoHistory.removeAll(keepingCapacity: true)
        timeline = candidate
    }
}

public enum TimelineToolbarEdit: Equatable, Sendable {
    case trim(
        clipID: String,
        sourceStartFrame: Int,
        durationFrames: Int
    )
    case move(clipID: String, timelineStartFrame: Int)
    case caption(clipID: String, text: String?)
    case split(clipID: String, sourceFrame: Int, newClipID: String)
}

public enum TimelineKeyboardEdit: Equatable, Sendable {
    case trim(
        clipID: String,
        sourceStartFrame: Int,
        durationFrames: Int
    )
    case move(clipID: String, timelineStartFrame: Int)
    case caption(clipID: String, text: String?)
    case split(clipID: String, sourceFrame: Int, newClipID: String)
}

public enum QueuedTimelineEdit: Codable, Equatable, Sendable {
    case trim(
        clipID: String,
        sourceStartFrame: Int,
        durationFrames: Int
    )
    case move(clipID: String, timelineStartFrame: Int)
    case caption(clipID: String, text: String?)
    case split(clipID: String, sourceFrame: Int, newClipID: String)
}

public final class DirectTimelineInputRouter {
    private let editor: DirectTimelineHistoryEditor

    public init(editor: DirectTimelineHistoryEditor) {
        self.editor = editor
    }

    public func perform(_ edit: TimelineToolbarEdit) throws {
        switch edit {
        case let .trim(clipID, sourceStartFrame, durationFrames):
            try editor.trimClip(
                id: clipID,
                toStartFrame: sourceStartFrame,
                durationFrames: durationFrames
            )
        case let .move(clipID, timelineStartFrame):
            try editor.moveClip(
                id: clipID,
                toTimelineStartFrame: timelineStartFrame
            )
        case let .caption(clipID, text):
            try editor.updateCaption(text, onClip: clipID)
        case let .split(clipID, sourceFrame, newClipID):
            try editor.splitClip(
                id: clipID,
                atSourceFrame: sourceFrame,
                newClipID: newClipID
            )
        }
    }

    public func perform(_ edit: TimelineKeyboardEdit) throws {
        switch edit {
        case let .trim(clipID, sourceStartFrame, durationFrames):
            try editor.trimClip(
                id: clipID,
                toStartFrame: sourceStartFrame,
                durationFrames: durationFrames
            )
        case let .move(clipID, timelineStartFrame):
            try editor.moveClip(
                id: clipID,
                toTimelineStartFrame: timelineStartFrame
            )
        case let .caption(clipID, text):
            try editor.updateCaption(text, onClip: clipID)
        case let .split(clipID, sourceFrame, newClipID):
            try editor.splitClip(
                id: clipID,
                atSourceFrame: sourceFrame,
                newClipID: newClipID
            )
        }
    }

    public func replay(_ edit: QueuedTimelineEdit) throws {
        switch edit {
        case let .trim(clipID, sourceStartFrame, durationFrames):
            try editor.trimClip(
                id: clipID,
                toStartFrame: sourceStartFrame,
                durationFrames: durationFrames
            )
        case let .move(clipID, timelineStartFrame):
            try editor.moveClip(
                id: clipID,
                toTimelineStartFrame: timelineStartFrame
            )
        case let .caption(clipID, text):
            try editor.updateCaption(text, onClip: clipID)
        case let .split(clipID, sourceFrame, newClipID):
            try editor.splitClip(
                id: clipID,
                atSourceFrame: sourceFrame,
                newClipID: newClipID
            )
        }
    }
}
