import DesignPatterns
import Testing

@Suite("Flyweight pressure")
struct FlyweightPressureTests {
    private static let locationCount = 20_000
    private static let bytesPerIcon = 32 * 32 * 4
    private static let builder = DirectFestivalMapBuilder()

    @Test("Quantifies repeated decoded pixels on a representative map")
    func quantifiesRepeatedPixelPayload() {
        let profile = Self.builder.profiledAnnotations(
            for: Self.representativeLocations
        )
        let expectedDirectBytes = Self.locationCount * Self.bytesPerIcon
        let expectedCategoryMinimum =
            FestivalVenueCategory.allCases.count * Self.bytesPerIcon

        #expect(profile.annotations.count == Self.locationCount)
        #expect(profile.memory.annotationCount == Self.locationCount)
        #expect(profile.memory.artworkObjectCount == Self.locationCount)
        #expect(
            profile.memory.decodedIconConstructionCount == Self.locationCount
        )
        #expect(profile.memory.decodedPixelBytes == expectedDirectBytes)
        #expect(
            profile.memory.minimumCategoryArtworkCount
                == FestivalVenueCategory.allCases.count
        )
        #expect(
            profile.memory.minimumCategoryPixelBytes
                == expectedCategoryMinimum
        )
        #expect(
            profile.memory.avoidableRepeatedPixelBytes
                == expectedDirectBytes - expectedCategoryMinimum
        )
    }

    @Test("Counts a distinct artwork identity for every location per category")
    func countsArtworkIdentitiesByCategory() {
        let memory = Self.builder.profiledAnnotations(
            for: Self.representativeLocations
        ).memory
        let locationsPerCategory =
            Self.locationCount / FestivalVenueCategory.allCases.count

        #expect(
            memory.categories.map(\.category)
                == FestivalVenueCategory.allCases
        )
        #expect(memory.categories.allSatisfy {
            $0.locationCount == locationsPerCategory
                && $0.artworkObjectCount == locationsPerCategory
                && $0.decodedPixelBytes
                    == locationsPerCategory * Self.bytesPerIcon
        })
    }

    @Test("Counts only categories present in a partial feed")
    func countsOnlyUsedCategories() {
        let memory = Self.builder.profiledAnnotations(
            for: Array(Self.representativeLocations.prefix(2))
        ).memory

        #expect(memory.annotationCount == 2)
        #expect(memory.minimumCategoryArtworkCount == 2)
        #expect(memory.minimumCategoryPixelBytes == 2 * Self.bytesPerIcon)
        #expect(memory.avoidableRepeatedPixelBytes == 0)
    }

    @Test("Reports zero pressure for an empty feed")
    func reportsEmptyProfile() {
        let profile = Self.builder.profiledAnnotations(for: [])

        #expect(profile.annotations.isEmpty)
        #expect(
            profile.memory == DirectFestivalMapMemoryProfile(
                annotationCount: 0,
                artworkObjectCount: 0,
                decodedIconConstructionCount: 0,
                decodedPixelBytes: 0,
                minimumCategoryArtworkCount: 0,
                minimumCategoryPixelBytes: 0,
                avoidableRepeatedPixelBytes: 0,
                categories: []
            )
        )
    }

    private static let representativeLocations: [FestivalMapLocation] =
        (0..<locationCount).map { index in
            let category = FestivalVenueCategory.allCases[
                index % FestivalVenueCategory.allCases.count
            ]
            let crowdStatuses = [
                FestivalCrowdStatus.quiet,
                .busy,
                .full,
                .closed
            ]

            return FestivalMapLocation(
                id: "venue-\(index)",
                name: "Festival location \(index)",
                coordinate: FestivalCoordinate(
                    latitude: 41.380 + Double(index % 1_000) / 100_000,
                    longitude: 2.150 + Double(index / 1_000) / 100_000
                ),
                category: category,
                crowdStatus: crowdStatuses[index % crowdStatuses.count]
            )
        }
}
