public final class FestivalMarkerArtwork: Equatable, Sendable {
    public let iconRGBABytes: [UInt8]
    public let fillColor: FestivalMarkerColor
    public let borderColor: FestivalMarkerColor
    public let categoryLabel: String
    public let accessibilityHint: String

    init(descriptor: FestivalMarkerDescriptor) {
        iconRGBABytes = decodeFestivalMarkerIcon(seed: descriptor.iconSeed)
        fillColor = descriptor.fillColor
        borderColor = descriptor.borderColor
        categoryLabel = descriptor.categoryLabel
        accessibilityHint = descriptor.accessibilityHint
    }

    public static func == (
        lhs: FestivalMarkerArtwork,
        rhs: FestivalMarkerArtwork
    ) -> Bool {
        lhs.iconRGBABytes == rhs.iconRGBABytes
            && lhs.fillColor == rhs.fillColor
            && lhs.borderColor == rhs.borderColor
            && lhs.categoryLabel == rhs.categoryLabel
            && lhs.accessibilityHint == rhs.accessibilityHint
    }
}

public struct FestivalMapAnnotation: Equatable, Sendable {
    public let id: String
    public let title: String
    public let coordinate: FestivalCoordinate
    public let crowdStatus: FestivalCrowdStatus
    public let accessibilityLabel: String
    public let artwork: FestivalMarkerArtwork

    public init(
        id: String,
        title: String,
        coordinate: FestivalCoordinate,
        crowdStatus: FestivalCrowdStatus,
        accessibilityLabel: String,
        artwork: FestivalMarkerArtwork
    ) {
        self.id = id
        self.title = title
        self.coordinate = coordinate
        self.crowdStatus = crowdStatus
        self.accessibilityLabel = accessibilityLabel
        self.artwork = artwork
    }
}

public struct FestivalMapBuilder: Sendable {
    public init() {}

    public func annotations(
        for locations: [FestivalMapLocation]
    ) -> [FestivalMapAnnotation] {
        let usedCategories = Set(locations.map(\.category))
        let artworkCatalog = FestivalMarkerArtworkCatalog(
            categories: usedCategories
        )

        return locations.map { location in
            let artwork = artworkCatalog.artwork(for: location.category)

            return FestivalMapAnnotation(
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
}

struct FestivalMarkerArtworkCatalog: Sendable {
    private let artworkByCategory: [
        FestivalVenueCategory: FestivalMarkerArtwork
    ]

    init(categories: Set<FestivalVenueCategory>) {
        artworkByCategory = Dictionary(
            uniqueKeysWithValues: FestivalVenueCategory.allCases.compactMap {
                category in
                guard categories.contains(category) else {
                    return nil
                }

                return (
                    category,
                    FestivalMarkerArtwork(
                        descriptor: category.markerDescriptor
                    )
                )
            }
        )
    }

    func artwork(
        for category: FestivalVenueCategory
    ) -> FestivalMarkerArtwork {
        guard let artwork = artworkByCategory[category] else {
            preconditionFailure("Artwork requested for an unused category")
        }

        return artwork
    }
}
