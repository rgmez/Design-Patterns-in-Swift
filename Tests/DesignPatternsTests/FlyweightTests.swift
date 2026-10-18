import DesignPatterns
import Testing

@Suite("Flyweight")
struct FlyweightTests {
    private static let builder = FestivalMapBuilder()
    private static let directBuilder = DirectFestivalMapBuilder()
    private static let locationCount = 20_000
    private static let bytesPerIcon = 32 * 32 * 4
    private static let northStage = location(
        index: 0,
        name: "North Stage",
        category: .mainStage,
        status: .busy
    )
    private static let sunsetStage = location(
        index: 1,
        name: "Sunset Stage",
        category: .mainStage,
        status: .quiet
    )
    private static let marketFoodCourt = location(
        index: 2,
        name: "Market Food Court",
        category: .foodCourt,
        status: .full
    )

    @Suite("Shared intrinsic artwork")
    struct SharedIntrinsicArtwork {
        @Test("Reuses one artwork identity within a category")
        func reusesCategoryArtwork() throws {
            let annotations = FlyweightTests.builder.annotations(
                for: [FlyweightTests.northStage, FlyweightTests.sunsetStage]
            )

            try #require(annotations.count == 2)
            #expect(annotations[0].artwork === annotations[1].artwork)
            #expect(annotations[0].artwork.iconRGBABytes.count == 4_096)
        }

        @Test("Keeps resources distinct between categories")
        func separatesCategoryArtwork() throws {
            let annotations = FlyweightTests.builder.annotations(
                for: [
                    FlyweightTests.northStage,
                    FlyweightTests.marketFoodCourt
                ]
            )

            try #require(annotations.count == 2)
            #expect(annotations[0].artwork !== annotations[1].artwork)
            #expect(
                annotations[0].artwork.iconRGBABytes
                    != annotations[1].artwork.iconRGBABytes
            )
        }

        @Test("Preserves unique map and accessibility state")
        func preservesExtrinsicState() throws {
            let locations = [
                FlyweightTests.northStage,
                FlyweightTests.marketFoodCourt,
                FlyweightTests.sunsetStage
            ]
            let annotations = FlyweightTests.builder.annotations(for: locations)

            try #require(annotations.count == locations.count)
            #expect(annotations.map(\.id) == locations.map(\.id))
            #expect(annotations.map(\.coordinate) == locations.map(\.coordinate))
            #expect(annotations.map(\.crowdStatus) == locations.map(\.crowdStatus))
            #expect(
                annotations.map(\.accessibilityLabel) == [
                    "North Stage, Main stage, busy",
                    "Market Food Court, Food court, full",
                    "Sunset Stage, Main stage, quiet"
                ]
            )
        }

        @Test("Builds no shared resources for an empty feed")
        func handlesEmptyFeed() {
            #expect(FlyweightTests.builder.annotations(for: []).isEmpty)
        }
    }

    @Suite("Measured benefit")
    struct MeasuredBenefit {
        @Test("Reduces twenty thousand artwork resources to four")
        func reducesRepresentativePixelPayload() {
            let locations = FlyweightTests.representativeLocations
            let direct = FlyweightTests.directBuilder.profiledAnnotations(
                for: locations
            )
            let shared = FlyweightTests.builder.annotations(for: locations)
            var uniqueArtwork: [
                ObjectIdentifier: FestivalMarkerArtwork
            ] = [:]

            for annotation in shared {
                uniqueArtwork[ObjectIdentifier(annotation.artwork)] =
                    annotation.artwork
            }

            let sharedPixelBytes = uniqueArtwork.values.reduce(0) {
                $0 + $1.iconRGBABytes.count
            }

            #expect(shared.count == FlyweightTests.locationCount)
            #expect(
                direct.memory.artworkObjectCount
                    == FlyweightTests.locationCount
            )
            #expect(
                direct.memory.decodedPixelBytes
                    == FlyweightTests.locationCount * FlyweightTests.bytesPerIcon
            )
            #expect(
                uniqueArtwork.count
                    == FestivalVenueCategory.allCases.count
            )
            #expect(
                sharedPixelBytes
                    == FestivalVenueCategory.allCases.count
                        * FlyweightTests.bytesPerIcon
            )
            #expect(
                direct.memory.decodedPixelBytes - sharedPixelBytes
                    == 81_903_616
            )
        }
    }

    private static let representativeLocations: [FestivalMapLocation] =
        (0..<locationCount).map { index in
            let category = FestivalVenueCategory.allCases[
                index % FestivalVenueCategory.allCases.count
            ]
            let statuses = [
                FestivalCrowdStatus.quiet,
                .busy,
                .full,
                .closed
            ]

            return location(
                index: index,
                name: "Festival location \(index)",
                category: category,
                status: statuses[index % statuses.count]
            )
        }

    private static func location(
        index: Int,
        name: String,
        category: FestivalVenueCategory,
        status: FestivalCrowdStatus
    ) -> FestivalMapLocation {
        FestivalMapLocation(
            id: "venue-\(index)",
            name: name,
            coordinate: FestivalCoordinate(
                latitude: 41.380 + Double(index % 1_000) / 100_000,
                longitude: 2.150 + Double(index / 1_000) / 100_000
            ),
            category: category,
            crowdStatus: status
        )
    }
}
