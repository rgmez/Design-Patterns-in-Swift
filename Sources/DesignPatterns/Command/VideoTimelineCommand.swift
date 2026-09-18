public enum TimelineCommand: Codable, Equatable, Sendable {
    case trim(
        clipID: String,
        sourceStartFrame: Int,
        durationFrames: Int
    )
    case move(clipID: String, timelineStartFrame: Int)
    case caption(clipID: String, text: String?)
    case split(clipID: String, sourceFrame: Int, newClipID: String)

    fileprivate func execute(
        on timeline: inout VideoTimeline
    ) throws -> TimelineCommandReversal {
        switch self {
        case let .trim(clipID, sourceStartFrame, durationFrames):
            let clip = try timeline.clip(id: clipID)
            try timeline.trimClip(
                id: clipID,
                toStartFrame: sourceStartFrame,
                durationFrames: durationFrames
            )
            return .trim(
                clipID: clipID,
                sourceStartFrame: clip.sourceStartFrame,
                durationFrames: clip.sourceDurationFrames
            )
        case let .move(clipID, timelineStartFrame):
            let clip = try timeline.clip(id: clipID)
            try timeline.moveClip(
                id: clipID,
                toTimelineStartFrame: timelineStartFrame
            )
            return .move(
                clipID: clipID,
                timelineStartFrame: clip.timelineStartFrame
            )
        case let .caption(clipID, text):
            let clip = try timeline.clip(id: clipID)
            try timeline.updateCaption(text, onClip: clipID)
            return .caption(clipID: clipID, text: clip.caption)
        case let .split(clipID, sourceFrame, newClipID):
            let originalClip = try timeline.clip(id: clipID)
            try timeline.splitClip(
                id: clipID,
                atSourceFrame: sourceFrame,
                newClipID: newClipID
            )
            return .split(
                originalClip: originalClip,
                newClipID: newClipID
            )
        }
    }
}

public final class TimelineCommandEditor {
    public private(set) var timeline: VideoTimeline
    public var canUndo: Bool { !undoHistory.isEmpty }
    public var canRedo: Bool { !redoHistory.isEmpty }
    public var undoDepth: Int { undoHistory.count }
    public var redoDepth: Int { redoHistory.count }
    public var retainedReversalCount: Int {
        undoHistory.count + redoHistory.count
    }

    private let historyLimit: Int
    private var undoHistory: [ExecutedTimelineCommand] = []
    private var redoHistory: [ExecutedTimelineCommand] = []

    public init(timeline: VideoTimeline, historyLimit: Int) {
        precondition(historyLimit > 0, "History must retain at least one edit.")
        self.timeline = timeline
        self.historyLimit = historyLimit
    }

    public func execute(_ command: TimelineCommand) throws {
        var candidate = timeline
        let reversal = try command.execute(on: &candidate)
        guard candidate != timeline else { return }

        undoHistory.append(
            ExecutedTimelineCommand(command: command, reversal: reversal)
        )
        trimUndoHistoryToLimit()
        redoHistory.removeAll(keepingCapacity: true)
        timeline = candidate
    }

    @discardableResult
    public func undo() throws -> Bool {
        guard let entry = undoHistory.last else { return false }

        var candidate = timeline
        try entry.reversal.apply(to: &candidate)
        undoHistory.removeLast()
        redoHistory.append(entry)
        timeline = candidate
        return true
    }

    @discardableResult
    public func redo() throws -> Bool {
        guard let entry = redoHistory.last else { return false }

        var candidate = timeline
        let reversal = try entry.command.execute(on: &candidate)
        redoHistory.removeLast()
        undoHistory.append(
            ExecutedTimelineCommand(
                command: entry.command,
                reversal: reversal
            )
        )
        trimUndoHistoryToLimit()
        timeline = candidate
        return true
    }

    private func trimUndoHistoryToLimit() {
        let overflow = undoHistory.count - historyLimit
        if overflow > 0 {
            undoHistory.removeFirst(overflow)
        }
    }
}

private struct ExecutedTimelineCommand: Sendable {
    let command: TimelineCommand
    let reversal: TimelineCommandReversal
}

private enum TimelineCommandReversal: Sendable {
    case trim(
        clipID: String,
        sourceStartFrame: Int,
        durationFrames: Int
    )
    case move(clipID: String, timelineStartFrame: Int)
    case caption(clipID: String, text: String?)
    case split(originalClip: TimelineClip, newClipID: String)

    func apply(to timeline: inout VideoTimeline) throws {
        switch self {
        case let .trim(clipID, sourceStartFrame, durationFrames):
            try timeline.trimClip(
                id: clipID,
                toStartFrame: sourceStartFrame,
                durationFrames: durationFrames
            )
        case let .move(clipID, timelineStartFrame):
            try timeline.moveClip(
                id: clipID,
                toTimelineStartFrame: timelineStartFrame
            )
        case let .caption(clipID, text):
            try timeline.updateCaption(text, onClip: clipID)
        case let .split(originalClip, newClipID):
            try timeline.restoreSplit(
                originalClip: originalClip,
                newClipID: newClipID
            )
        }
    }
}

private extension VideoTimeline {
    func clip(id: String) throws -> TimelineClip {
        guard let clip = clips.first(where: { $0.id == id }) else {
            throw TimelineEditError.clipNotFound(id)
        }
        return clip
    }

    mutating func restoreSplit(
        originalClip: TimelineClip,
        newClipID: String
    ) throws {
        guard let leadingIndex = clips.firstIndex(
            where: { $0.id == originalClip.id }
        ) else {
            throw TimelineEditError.clipNotFound(originalClip.id)
        }
        let trailingIndex = clips.index(after: leadingIndex)
        guard trailingIndex < clips.endIndex,
              clips[trailingIndex].id == newClipID else {
            throw TimelineEditError.clipNotFound(newClipID)
        }

        var restoredClips = clips
        restoredClips.replaceSubrange(
            leadingIndex ... trailingIndex,
            with: [originalClip]
        )
        self = try VideoTimeline(clips: restoredClips)
    }
}
