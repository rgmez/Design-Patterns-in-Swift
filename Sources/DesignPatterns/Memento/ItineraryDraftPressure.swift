import Foundation

public struct DirectItineraryDraftArchive: Sendable {
    private var encodedRestorePoints: [Data]
    private let restorePointLimit: Int

    public init(
        encodedRestorePoints: [Data] = [],
        restorePointLimit: Int = 5
    ) {
        precondition(
            restorePointLimit > 0,
            "An itinerary archive needs room for at least one restore point"
        )
        self.encodedRestorePoints = Array(
            encodedRestorePoints.suffix(restorePointLimit)
        )
        self.restorePointLimit = restorePointLimit
    }

    public var availableRestorePointCount: Int {
        encodedRestorePoints.count
    }

    public var retainedEncodedByteCount: Int {
        encodedRestorePoints.reduce(0) { $0 + $1.count }
    }

    public mutating func save(
        _ editor: DirectItineraryDraftEditor
    ) throws {
        let snapshot = editor.makeVersionedSnapshot()
        let encodedSnapshot = try JSONEncoder().encode(snapshot)

        if encodedRestorePoints.count == restorePointLimit {
            encodedRestorePoints.removeFirst()
        }
        encodedRestorePoints.append(encodedSnapshot)
    }

    @discardableResult
    public mutating func restoreLatest(
        into editor: inout DirectItineraryDraftEditor
    ) throws -> Bool {
        guard let encodedSnapshot = encodedRestorePoints.last else {
            return false
        }

        let snapshot = try JSONDecoder().decode(
            DirectItineraryDraftSnapshotV1.self,
            from: encodedSnapshot
        )
        try editor.restore(snapshot)
        encodedRestorePoints.removeLast()
        return true
    }
}
