import DesignPatterns
import Testing

@Suite("Flyweight problem")
struct FlyweightProblemTests {
    private static let builder = DirectFestivalMapBuilder()
    private static let northStage = FestivalMapLocation(
        id: "venue-north-stage",
        name: "North Stage",
        coordinate: FestivalCoordinate(
            latitude: 41.389_07,
            longitude: 2.154_01
        ),
        category: .mainStage,
        crowdStatus: .busy
    )
    private static let sunsetStage = FestivalMapLocation(
        id: "venue-sunset-stage",
        name: "Sunset Stage",
        coordinate: FestivalCoordinate(
            latitude: 41.388_42,
            longitude: 2.156_34
        ),
        category: .mainStage,
        crowdStatus: .quiet
    )
    private static let marketFoodCourt = FestivalMapLocation(
        id: "venue-market-food",
        name: "Market Food Court",
        coordinate: FestivalCoordinate(
            latitude: 41.387_91,
            longitude: 2.155_26
        ),
        category: .foodCourt,
        crowdStatus: .full
    )

    @Test("Preserves location order and unique map state")
    func preservesExtrinsicMapState() {
        let annotations = Self.builder.annotations(
            for: [Self.northStage, Self.marketFoodCourt, Self.sunsetStage]
        )

        #expect(annotations.map(\.id) == [
            Self.northStage.id,
            Self.marketFoodCourt.id,
            Self.sunsetStage.id
        ])
        #expect(annotations[0].coordinate == Self.northStage.coordinate)
        #expect(annotations[0].crowdStatus == .busy)
        #expect(annotations[1].coordinate == Self.marketFoodCourt.coordinate)
        #expect(annotations[1].crowdStatus == .full)
        #expect(annotations[2].coordinate == Self.sunsetStage.coordinate)
        #expect(annotations[2].crowdStatus == .quiet)
    }

    @Test("Builds category-specific visual and accessibility metadata")
    func buildsCategoryMetadata() {
        let annotations = Self.builder.annotations(
            for: [Self.northStage, Self.marketFoodCourt]
        )

        #expect(annotations[0].artwork.categoryLabel == "Main stage")
        #expect(annotations[0].artwork.iconRGBABytes.count == 4_096)
        #expect(
            annotations[0].accessibilityLabel
                == "North Stage, Main stage, busy"
        )
        #expect(annotations[1].artwork.categoryLabel == "Food court")
        #expect(annotations[1].artwork.iconRGBABytes.count == 4_096)
        #expect(
            annotations[1].accessibilityLabel
                == "Market Food Court, Food court, full"
        )
        #expect(
            annotations[0].artwork.iconRGBABytes
                != annotations[1].artwork.iconRGBABytes
        )
    }

    @Test("Rebuilds equivalent artwork for every annotation")
    func repeatsArtworkPerAnnotation() {
        let annotations = Self.builder.annotations(
            for: [Self.northStage, Self.sunsetStage]
        )
        let northArtwork = annotations[0].artwork
        let sunsetArtwork = annotations[1].artwork

        #expect(northArtwork == sunsetArtwork)
        #expect(northArtwork !== sunsetArtwork)
        #expect(northArtwork.iconRGBABytes.count == 4_096)
        #expect(sunsetArtwork.iconRGBABytes.count == 4_096)
    }

    @Test("Handles an empty festival feed without special infrastructure")
    func handlesEmptyFeed() {
        #expect(Self.builder.annotations(for: []).isEmpty)
    }
}
