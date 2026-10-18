public struct FestivalCoordinate: Equatable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(
        latitude: Double,
        longitude: Double
    ) {
        precondition(
            (-90.0...90.0).contains(latitude),
            "Latitude must be between -90 and 90 degrees"
        )
        precondition(
            (-180.0...180.0).contains(longitude),
            "Longitude must be between -180 and 180 degrees"
        )

        self.latitude = latitude
        self.longitude = longitude
    }
}

public enum FestivalVenueCategory: CaseIterable, Equatable, Hashable, Sendable {
    case mainStage
    case foodCourt
    case restroom
    case firstAid
}

public enum FestivalCrowdStatus: String, Equatable, Sendable {
    case quiet
    case busy
    case full
    case closed
}

public struct FestivalMapLocation: Equatable, Sendable {
    public let id: String
    public let name: String
    public let coordinate: FestivalCoordinate
    public let category: FestivalVenueCategory
    public let crowdStatus: FestivalCrowdStatus

    public init(
        id: String,
        name: String,
        coordinate: FestivalCoordinate,
        category: FestivalVenueCategory,
        crowdStatus: FestivalCrowdStatus
    ) {
        precondition(!id.isEmpty, "A festival location needs an identifier")
        precondition(!name.isEmpty, "A festival location needs a name")

        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.category = category
        self.crowdStatus = crowdStatus
    }
}

public struct FestivalMarkerColor: Equatable, Sendable {
    public let red: UInt8
    public let green: UInt8
    public let blue: UInt8
    public let alpha: UInt8

    public init(
        red: UInt8,
        green: UInt8,
        blue: UInt8,
        alpha: UInt8 = 255
    ) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

public final class DirectFestivalMarkerArtwork: Equatable, Sendable {
    public let iconRGBABytes: [UInt8]
    public let fillColor: FestivalMarkerColor
    public let borderColor: FestivalMarkerColor
    public let categoryLabel: String
    public let accessibilityHint: String

    public init(
        iconRGBABytes: [UInt8],
        fillColor: FestivalMarkerColor,
        borderColor: FestivalMarkerColor,
        categoryLabel: String,
        accessibilityHint: String
    ) {
        precondition(!iconRGBABytes.isEmpty, "Marker artwork needs icon pixels")
        precondition(
            iconRGBABytes.count.isMultiple(of: 4),
            "RGBA artwork needs four bytes per pixel"
        )

        self.iconRGBABytes = iconRGBABytes
        self.fillColor = fillColor
        self.borderColor = borderColor
        self.categoryLabel = categoryLabel
        self.accessibilityHint = accessibilityHint
    }

    public static func == (
        lhs: DirectFestivalMarkerArtwork,
        rhs: DirectFestivalMarkerArtwork
    ) -> Bool {
        lhs.iconRGBABytes == rhs.iconRGBABytes
            && lhs.fillColor == rhs.fillColor
            && lhs.borderColor == rhs.borderColor
            && lhs.categoryLabel == rhs.categoryLabel
            && lhs.accessibilityHint == rhs.accessibilityHint
    }
}

public struct DirectFestivalMapAnnotation: Equatable, Sendable {
    public let id: String
    public let title: String
    public let coordinate: FestivalCoordinate
    public let crowdStatus: FestivalCrowdStatus
    public let accessibilityLabel: String
    public let artwork: DirectFestivalMarkerArtwork

    public init(
        id: String,
        title: String,
        coordinate: FestivalCoordinate,
        crowdStatus: FestivalCrowdStatus,
        accessibilityLabel: String,
        artwork: DirectFestivalMarkerArtwork
    ) {
        self.id = id
        self.title = title
        self.coordinate = coordinate
        self.crowdStatus = crowdStatus
        self.accessibilityLabel = accessibilityLabel
        self.artwork = artwork
    }
}

public struct DirectFestivalMapBuilder: Sendable {
    public init() {}

    public func annotations(
        for locations: [FestivalMapLocation]
    ) -> [DirectFestivalMapAnnotation] {
        locations.map { location in
            let artwork = makeArtwork(for: location.category)

            return DirectFestivalMapAnnotation(
                id: location.id,
                title: location.name,
                coordinate: location.coordinate,
                crowdStatus: location.crowdStatus,
                accessibilityLabel: [
                    location.name,
                    artwork.categoryLabel,
                    location.crowdStatus.rawValue
                ].joined(separator: ", "),
                artwork: artwork
            )
        }
    }

    private func makeArtwork(
        for category: FestivalVenueCategory
    ) -> DirectFestivalMarkerArtwork {
        let descriptor = category.markerDescriptor

        return DirectFestivalMarkerArtwork(
            iconRGBABytes: decodeFestivalMarkerIcon(seed: descriptor.iconSeed),
            fillColor: descriptor.fillColor,
            borderColor: descriptor.borderColor,
            categoryLabel: descriptor.categoryLabel,
            accessibilityHint: descriptor.accessibilityHint
        )
    }
}

extension FestivalVenueCategory {
    var markerDescriptor: FestivalMarkerDescriptor {
        switch self {
        case .mainStage:
            FestivalMarkerDescriptor(
                iconSeed: 17,
                fillColor: FestivalMarkerColor(red: 183, green: 43, blue: 32),
                borderColor: FestivalMarkerColor(red: 255, green: 220, blue: 210),
                categoryLabel: "Main stage",
                accessibilityHint: "Double-tap for the current performance"
            )
        case .foodCourt:
            FestivalMarkerDescriptor(
                iconSeed: 41,
                fillColor: FestivalMarkerColor(red: 210, green: 89, blue: 38),
                borderColor: FestivalMarkerColor(red: 255, green: 226, blue: 190),
                categoryLabel: "Food court",
                accessibilityHint: "Double-tap for vendors and dietary filters"
            )
        case .restroom:
            FestivalMarkerDescriptor(
                iconSeed: 73,
                fillColor: FestivalMarkerColor(red: 72, green: 72, blue: 72),
                borderColor: FestivalMarkerColor(red: 235, green: 235, blue: 235),
                categoryLabel: "Restroom",
                accessibilityHint: "Double-tap for accessibility facilities"
            )
        case .firstAid:
            FestivalMarkerDescriptor(
                iconSeed: 109,
                fillColor: FestivalMarkerColor(red: 132, green: 24, blue: 24),
                borderColor: FestivalMarkerColor(red: 255, green: 238, blue: 230),
                categoryLabel: "First aid",
                accessibilityHint: "Double-tap for opening hours"
            )
        }
    }
}

func decodeFestivalMarkerIcon(seed: UInt8) -> [UInt8] {
    let byteCount = 32 * 32 * 4

    return (0..<byteCount).map { offset in
        UInt8(truncatingIfNeeded: Int(seed) + (offset * 31))
    }
}

struct FestivalMarkerDescriptor {
    let iconSeed: UInt8
    let fillColor: FestivalMarkerColor
    let borderColor: FestivalMarkerColor
    let categoryLabel: String
    let accessibilityHint: String
}
