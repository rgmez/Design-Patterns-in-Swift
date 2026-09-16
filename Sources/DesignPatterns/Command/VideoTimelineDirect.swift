public struct TimelineClip: Equatable, Sendable {
    public let id: String
    public let assetID: String
    public let assetDurationFrames: Int
    public private(set) var sourceStartFrame: Int
    public private(set) var sourceDurationFrames: Int
    public private(set) var timelineStartFrame: Int
    public private(set) var caption: String?

    public init(
        id: String,
        assetID: String,
        assetDurationFrames: Int,
        sourceStartFrame: Int,
        sourceDurationFrames: Int,
        timelineStartFrame: Int,
        caption: String? = nil
    ) throws {
        guard assetDurationFrames > 0,
              sourceStartFrame >= 0,
              sourceStartFrame <= assetDurationFrames,
              sourceDurationFrames > 0,
              sourceDurationFrames
                <= assetDurationFrames - sourceStartFrame else {
            throw TimelineEditError.invalidSourceRange(
                startFrame: sourceStartFrame,
                durationFrames: sourceDurationFrames,
                assetDurationFrames: assetDurationFrames
            )
        }
        guard timelineStartFrame >= 0 else {
            throw TimelineEditError.invalidTimelineStart(timelineStartFrame)
        }

        self.id = id
        self.assetID = assetID
        self.assetDurationFrames = assetDurationFrames
        self.sourceStartFrame = sourceStartFrame
        self.sourceDurationFrames = sourceDurationFrames
        self.timelineStartFrame = timelineStartFrame
        self.caption = caption
    }

    fileprivate mutating func trim(
        toStartFrame startFrame: Int,
        durationFrames: Int
    ) throws {
        guard startFrame >= 0,
              startFrame <= assetDurationFrames,
              durationFrames > 0,
              durationFrames <= assetDurationFrames - startFrame else {
            throw TimelineEditError.invalidSourceRange(
                startFrame: startFrame,
                durationFrames: durationFrames,
                assetDurationFrames: assetDurationFrames
            )
        }

        sourceStartFrame = startFrame
        sourceDurationFrames = durationFrames
    }

    fileprivate mutating func move(to startFrame: Int) throws {
        guard startFrame >= 0 else {
            throw TimelineEditError.invalidTimelineStart(startFrame)
        }
        timelineStartFrame = startFrame
    }

    fileprivate mutating func updateCaption(_ caption: String?) {
        self.caption = caption
    }

    fileprivate func split(
        atSourceFrame splitFrame: Int,
        newClipID: String
    ) throws -> (leading: TimelineClip, trailing: TimelineClip) {
        let sourceEndFrame = sourceStartFrame + sourceDurationFrames
        guard splitFrame > sourceStartFrame,
              splitFrame < sourceEndFrame else {
            throw TimelineEditError.invalidSplitFrame(
                clipID: id,
                splitFrame: splitFrame
            )
        }

        let leadingDuration = splitFrame - sourceStartFrame
        let trailingDuration = sourceEndFrame - splitFrame
        let leading = try TimelineClip(
            id: id,
            assetID: assetID,
            assetDurationFrames: assetDurationFrames,
            sourceStartFrame: sourceStartFrame,
            sourceDurationFrames: leadingDuration,
            timelineStartFrame: timelineStartFrame,
            caption: caption
        )
        let trailing = try TimelineClip(
            id: newClipID,
            assetID: assetID,
            assetDurationFrames: assetDurationFrames,
            sourceStartFrame: splitFrame,
            sourceDurationFrames: trailingDuration,
            timelineStartFrame: timelineStartFrame + leadingDuration,
            caption: caption
        )
        return (leading, trailing)
    }
}

public struct VideoTimeline: Equatable, Sendable {
    public private(set) var clips: [TimelineClip]

    public init(clips: [TimelineClip]) throws {
        var clipIDs: Set<String> = []
        for clip in clips where !clipIDs.insert(clip.id).inserted {
            throw TimelineEditError.duplicateClipID(clip.id)
        }
        self.clips = clips
    }

    fileprivate mutating func trimClip(
        id: String,
        toStartFrame startFrame: Int,
        durationFrames: Int
    ) throws {
        let index = try index(ofClip: id)
        try clips[index].trim(
            toStartFrame: startFrame,
            durationFrames: durationFrames
        )
    }

    fileprivate mutating func moveClip(
        id: String,
        toTimelineStartFrame startFrame: Int
    ) throws {
        let index = try index(ofClip: id)
        try clips[index].move(to: startFrame)
    }

    fileprivate mutating func updateCaption(
        _ caption: String?,
        onClip id: String
    ) throws {
        let index = try index(ofClip: id)
        clips[index].updateCaption(caption)
    }

    fileprivate mutating func splitClip(
        id: String,
        atSourceFrame splitFrame: Int,
        newClipID: String
    ) throws {
        guard !clips.contains(where: { $0.id == newClipID }) else {
            throw TimelineEditError.duplicateClipID(newClipID)
        }

        let index = try index(ofClip: id)
        let splitClips = try clips[index].split(
            atSourceFrame: splitFrame,
            newClipID: newClipID
        )
        clips.replaceSubrange(
            index ... index,
            with: [splitClips.leading, splitClips.trailing]
        )
    }

    private func index(ofClip id: String) throws -> Int {
        guard let index = clips.firstIndex(where: { $0.id == id }) else {
            throw TimelineEditError.clipNotFound(id)
        }
        return index
    }
}

public enum TimelineEditError: Error, Equatable, Sendable {
    case clipNotFound(String)
    case duplicateClipID(String)
    case invalidSourceRange(
        startFrame: Int,
        durationFrames: Int,
        assetDurationFrames: Int
    )
    case invalidTimelineStart(Int)
    case invalidSplitFrame(clipID: String, splitFrame: Int)
}

public final class DirectTimelineEditor {
    public private(set) var timeline: VideoTimeline
    public var canUndo: Bool { previousTimeline != nil }

    private var previousTimeline: VideoTimeline?

    public init(timeline: VideoTimeline) {
        self.timeline = timeline
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
        guard let previousTimeline else { return false }

        timeline = previousTimeline
        self.previousTimeline = nil
        return true
    }

    private func applyEdit(
        _ edit: (inout VideoTimeline) throws -> Void
    ) throws {
        var candidate = timeline
        try edit(&candidate)
        guard candidate != timeline else { return }

        previousTimeline = timeline
        timeline = candidate
    }
}
