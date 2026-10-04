import Foundation

public struct ItineraryDraftMemento: Equatable, Sendable {
    fileprivate let serializedState: Data

    var encodedByteCount: Int {
        serializedState.count
    }

    init(serializedState: Data) {
        self.serializedState = serializedState
    }
}

public struct ItineraryDraftEditor: Sendable {
    private struct RoutingPreferences: Codable, Equatable, Sendable {
        var prefersScenicRoutes = false
        var avoidsTolls = false
    }

    private struct DraftState: Codable, Equatable, Sendable {
        var title: String
        var stops: [ItineraryStop]
        var transport: ItineraryTransport
        var routingPreferences = RoutingPreferences()
    }

    private struct SnapshotV1: Codable, Sendable {
        static let currentSchemaVersion = 1

        let schemaVersion: Int
        let draft: DraftState
    }

    private var draft: DraftState

    public init(
        title: String,
        transport: ItineraryTransport = .rail
    ) {
        draft = DraftState(
            title: title,
            stops: [],
            transport: transport
        )
    }

    public var preview: ItineraryDraftPreview {
        ItineraryDraftPreview(
            title: draft.title,
            stops: draft.stops,
            transport: draft.transport,
            routeProfile: routeProfile(for: draft.routingPreferences)
        )
    }

    public func makeMemento() throws -> ItineraryDraftMemento {
        let snapshot = SnapshotV1(
            schemaVersion: SnapshotV1.currentSchemaVersion,
            draft: draft
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try ItineraryDraftMemento(
            serializedState: encoder.encode(snapshot)
        )
    }

    public mutating func rename(to title: String) {
        draft.title = title
    }

    public mutating func appendStop(_ stop: ItineraryStop) {
        draft.stops.append(stop)
    }

    public mutating func selectTransport(_ transport: ItineraryTransport) {
        draft.transport = transport
    }

    public mutating func preferScenicRoutes(_ enabled: Bool) {
        draft.routingPreferences.prefersScenicRoutes = enabled
    }

    public mutating func avoidTolls(_ enabled: Bool) {
        draft.routingPreferences.avoidsTolls = enabled
    }

    public mutating func restore(
        _ memento: ItineraryDraftMemento
    ) throws {
        let snapshot = try JSONDecoder().decode(
            SnapshotV1.self,
            from: memento.serializedState
        )
        guard snapshot.schemaVersion == SnapshotV1.currentSchemaVersion else {
            throw ItineraryDraftSnapshotError.unsupportedVersion(
                snapshot.schemaVersion
            )
        }

        draft = snapshot.draft
    }

    private func routeProfile(
        for preferences: RoutingPreferences
    ) -> ItineraryRouteProfile {
        switch (
            preferences.prefersScenicRoutes,
            preferences.avoidsTolls
        ) {
        case (false, false):
            .fastest
        case (true, false):
            .scenic
        case (false, true):
            .tollFree
        case (true, true):
            .scenicAndTollFree
        }
    }
}

public struct ItineraryDraftHistory: Sendable {
    private var restorePoints: [ItineraryDraftMemento] = []
    private let restorePointLimit: Int

    public init(restorePointLimit: Int = 5) {
        precondition(
            restorePointLimit > 0,
            "Itinerary history needs room for at least one restore point"
        )
        self.restorePointLimit = restorePointLimit
    }

    init(
        restorePoints: [ItineraryDraftMemento],
        restorePointLimit: Int = 5
    ) {
        precondition(
            restorePointLimit > 0,
            "Itinerary history needs room for at least one restore point"
        )
        self.restorePoints = Array(restorePoints.suffix(restorePointLimit))
        self.restorePointLimit = restorePointLimit
    }

    public var availableRestorePointCount: Int {
        restorePoints.count
    }

    public var retainedEncodedByteCount: Int {
        restorePoints.reduce(0) { result, memento in
            result + memento.encodedByteCount
        }
    }

    public mutating func save(
        _ editor: ItineraryDraftEditor
    ) throws {
        let memento = try editor.makeMemento()
        if restorePoints.count == restorePointLimit {
            restorePoints.removeFirst()
        }
        restorePoints.append(memento)
    }

    @discardableResult
    public mutating func restoreLatest(
        into editor: inout ItineraryDraftEditor
    ) throws -> Bool {
        guard let memento = restorePoints.last else {
            return false
        }

        try editor.restore(memento)
        restorePoints.removeLast()
        return true
    }
}
