public struct ItineraryStop: Codable, Equatable, Sendable {
    public let city: String
    public let nights: Int

    public init(city: String, nights: Int) {
        precondition(nights > 0, "A stop must include at least one night")
        self.city = city
        self.nights = nights
    }
}

public enum ItineraryTransport: Codable, Equatable, Sendable {
    case rail
    case driving
    case flight
    case ferry
}

public enum ItineraryRouteProfile: Equatable, Sendable {
    case fastest
    case scenic
    case tollFree
    case scenicAndTollFree
}

public struct ItineraryDraftPreview: Equatable, Sendable {
    public let title: String
    public let stops: [ItineraryStop]
    public let transport: ItineraryTransport
    public let routeProfile: ItineraryRouteProfile
}

public enum ItineraryDraftSnapshotError: Error, Equatable, Sendable {
    case unsupportedVersion(Int)
}

public struct DirectItineraryDraftSnapshotV1: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public let schemaVersion: Int
    public let title: String
    public let stops: [ItineraryStop]
    public let transport: ItineraryTransport
    public let prefersScenicRoutes: Bool
    public let avoidsTolls: Bool

    public init(
        schemaVersion: Int = currentSchemaVersion,
        title: String,
        stops: [ItineraryStop],
        transport: ItineraryTransport,
        prefersScenicRoutes: Bool,
        avoidsTolls: Bool
    ) {
        self.schemaVersion = schemaVersion
        self.title = title
        self.stops = stops
        self.transport = transport
        self.prefersScenicRoutes = prefersScenicRoutes
        self.avoidsTolls = avoidsTolls
    }
}

public struct DirectItineraryDraftEditor: Sendable {
    private struct RoutingPreferences: Equatable, Sendable {
        var prefersScenicRoutes = false
        var avoidsTolls = false
    }

    private struct DraftState: Equatable, Sendable {
        var title: String
        var stops: [ItineraryStop]
        var transport: ItineraryTransport
        var routingPreferences = RoutingPreferences()
    }

    private var draft: DraftState
    private var restorePoints: [DraftState] = []
    private let restorePointLimit: Int

    public init(
        title: String,
        transport: ItineraryTransport = .rail,
        restorePointLimit: Int = 3
    ) {
        precondition(
            restorePointLimit > 0,
            "An itinerary editor needs room for at least one restore point"
        )
        draft = DraftState(
            title: title,
            stops: [],
            transport: transport
        )
        self.restorePointLimit = restorePointLimit
    }

    public var preview: ItineraryDraftPreview {
        ItineraryDraftPreview(
            title: draft.title,
            stops: draft.stops,
            transport: draft.transport,
            routeProfile: routeProfile(for: draft.routingPreferences)
        )
    }

    public var availableRestorePointCount: Int {
        restorePoints.count
    }

    public func makeVersionedSnapshot() -> DirectItineraryDraftSnapshotV1 {
        DirectItineraryDraftSnapshotV1(
            title: draft.title,
            stops: draft.stops,
            transport: draft.transport,
            prefersScenicRoutes:
                draft.routingPreferences.prefersScenicRoutes,
            avoidsTolls: draft.routingPreferences.avoidsTolls
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

    public mutating func saveRestorePoint() {
        if restorePoints.count == restorePointLimit {
            restorePoints.removeFirst()
        }
        restorePoints.append(draft)
    }

    @discardableResult
    public mutating func restoreLatest() -> Bool {
        guard let savedDraft = restorePoints.popLast() else {
            return false
        }
        draft = savedDraft
        return true
    }

    public mutating func restore(
        _ snapshot: DirectItineraryDraftSnapshotV1
    ) throws {
        guard
            snapshot.schemaVersion
                == DirectItineraryDraftSnapshotV1.currentSchemaVersion
        else {
            throw ItineraryDraftSnapshotError.unsupportedVersion(
                snapshot.schemaVersion
            )
        }

        draft = DraftState(
            title: snapshot.title,
            stops: snapshot.stops,
            transport: snapshot.transport,
            routingPreferences: RoutingPreferences(
                prefersScenicRoutes: snapshot.prefersScenicRoutes,
                avoidsTolls: snapshot.avoidsTolls
            )
        )
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
