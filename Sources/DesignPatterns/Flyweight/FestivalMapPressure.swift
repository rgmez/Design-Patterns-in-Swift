public struct FestivalCategoryArtworkProfile: Equatable, Sendable {
    public let category: FestivalVenueCategory
    public let locationCount: Int
    public let artworkObjectCount: Int
    public let decodedPixelBytes: Int

    public init(
        category: FestivalVenueCategory,
        locationCount: Int,
        artworkObjectCount: Int,
        decodedPixelBytes: Int
    ) {
        self.category = category
        self.locationCount = locationCount
        self.artworkObjectCount = artworkObjectCount
        self.decodedPixelBytes = decodedPixelBytes
    }
}

public struct DirectFestivalMapMemoryProfile: Equatable, Sendable {
    public let annotationCount: Int
    public let artworkObjectCount: Int
    public let decodedIconConstructionCount: Int
    public let decodedPixelBytes: Int
    public let minimumCategoryArtworkCount: Int
    public let minimumCategoryPixelBytes: Int
    public let avoidableRepeatedPixelBytes: Int
    public let categories: [FestivalCategoryArtworkProfile]

    public init(
        annotationCount: Int,
        artworkObjectCount: Int,
        decodedIconConstructionCount: Int,
        decodedPixelBytes: Int,
        minimumCategoryArtworkCount: Int,
        minimumCategoryPixelBytes: Int,
        avoidableRepeatedPixelBytes: Int,
        categories: [FestivalCategoryArtworkProfile]
    ) {
        self.annotationCount = annotationCount
        self.artworkObjectCount = artworkObjectCount
        self.decodedIconConstructionCount = decodedIconConstructionCount
        self.decodedPixelBytes = decodedPixelBytes
        self.minimumCategoryArtworkCount = minimumCategoryArtworkCount
        self.minimumCategoryPixelBytes = minimumCategoryPixelBytes
        self.avoidableRepeatedPixelBytes = avoidableRepeatedPixelBytes
        self.categories = categories
    }
}

public struct ProfiledDirectFestivalMap: Equatable, Sendable {
    public let annotations: [DirectFestivalMapAnnotation]
    public let memory: DirectFestivalMapMemoryProfile

    public init(
        annotations: [DirectFestivalMapAnnotation],
        memory: DirectFestivalMapMemoryProfile
    ) {
        self.annotations = annotations
        self.memory = memory
    }
}

public extension DirectFestivalMapBuilder {
    func profiledAnnotations(
        for locations: [FestivalMapLocation]
    ) -> ProfiledDirectFestivalMap {
        let annotations = annotations(for: locations)
        var artworkByCategory: [
            FestivalVenueCategory: [DirectFestivalMarkerArtwork]
        ] = [:]

        for (location, annotation) in zip(locations, annotations) {
            artworkByCategory[location.category, default: []]
                .append(annotation.artwork)
        }

        let categories = FestivalVenueCategory.allCases.compactMap {
            category -> FestivalCategoryArtworkProfile? in
            guard let artwork = artworkByCategory[category],
                  !artwork.isEmpty else {
                return nil
            }

            return FestivalCategoryArtworkProfile(
                category: category,
                locationCount: artwork.count,
                artworkObjectCount: Set(
                    artwork.map(ObjectIdentifier.init)
                ).count,
                decodedPixelBytes: artwork.reduce(0) {
                    $0 + $1.iconRGBABytes.count
                }
            )
        }
        let decodedPixelBytes = categories.reduce(0) {
            $0 + $1.decodedPixelBytes
        }
        let minimumCategoryPixelBytes = FestivalVenueCategory.allCases.reduce(
            0
        ) { partialResult, category in
            guard let artwork = artworkByCategory[category]?.first else {
                return partialResult
            }

            return partialResult + artwork.iconRGBABytes.count
        }

        return ProfiledDirectFestivalMap(
            annotations: annotations,
            memory: DirectFestivalMapMemoryProfile(
                annotationCount: annotations.count,
                artworkObjectCount: Set(
                    annotations.map { ObjectIdentifier($0.artwork) }
                ).count,
                decodedIconConstructionCount: annotations.count,
                decodedPixelBytes: decodedPixelBytes,
                minimumCategoryArtworkCount: categories.count,
                minimumCategoryPixelBytes: minimumCategoryPixelBytes,
                avoidableRepeatedPixelBytes:
                    decodedPixelBytes - minimumCategoryPixelBytes,
                categories: categories
            )
        )
    }
}
