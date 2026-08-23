import DesignPatterns
import Testing

@Suite("Strategy")
struct StrategyTests {
    struct RankingScenario: Sendable, CustomTestStringConvertible {
        let name: String
        let strategy: DeliveryRankingStrategy
        let expectedIDs: [String]

        var testDescription: String { name }
    }

    private static let options = [
        DeliveryOption(
            id: "express-courier",
            feeInMinorUnits: 1_299,
            estimatedArrivalDays: 1,
            carbonGrams: 2_400
        ),
        DeliveryOption(
            id: "parcel-locker",
            feeInMinorUnits: 499,
            estimatedArrivalDays: 3,
            carbonGrams: 420
        ),
        DeliveryOption(
            id: "standard-home",
            feeInMinorUnits: 299,
            estimatedArrivalDays: 5,
            carbonGrams: 1_100
        )
    ]
    private static let builtInScenarios = [
        RankingScenario(
            name: "lowest cost",
            strategy: .lowestCost,
            expectedIDs: ["standard-home", "parcel-locker", "express-courier"]
        ),
        RankingScenario(
            name: "earliest arrival",
            strategy: .earliestArrival,
            expectedIDs: ["express-courier", "parcel-locker", "standard-home"]
        ),
        RankingScenario(
            name: "lowest carbon",
            strategy: .lowestCarbon,
            expectedIDs: ["parcel-locker", "standard-home", "express-courier"]
        )
    ]
    private static let firstCampaignPoints = [
        "express-courier": 15,
        "parcel-locker": 80,
        "standard-home": 35
    ]
    private static let updatedCampaignPoints = [
        "express-courier": 95,
        "parcel-locker": 20,
        "standard-home": 35
    ]

    @Suite("Built-in strategies")
    struct BuiltInStrategies {
        @Test(
            "Ranks the same options with interchangeable strategies",
            arguments: StrategyTests.builtInScenarios
        )
        func ranksWithSelectedStrategy(_ scenario: RankingScenario) {
            let rankedOptions = rankDeliveryOptions(
                StrategyTests.options,
                using: scenario.strategy
            )

            #expect(rankedOptions.map(\.id) == scenario.expectedIDs)
        }

        @Test("Uses option identity as a deterministic tie-breaker")
        func resolvesTiesDeterministically() {
            let tiedOptions = [
                DeliveryOption(
                    id: "weekend-home",
                    feeInMinorUnits: 599,
                    estimatedArrivalDays: 2,
                    carbonGrams: 900
                ),
                DeliveryOption(
                    id: "collection-point",
                    feeInMinorUnits: 599,
                    estimatedArrivalDays: 4,
                    carbonGrams: 300
                )
            ]

            let rankedOptions = rankDeliveryOptions(tiedOptions, using: .lowestCost)

            #expect(rankedOptions.map(\.id) == ["collection-point", "weekend-home"])
        }

        @Test("Leaves the fulfillment response unchanged")
        func preservesSourceOptions() {
            let sourceOptions = StrategyTests.options

            _ = rankDeliveryOptions(StrategyTests.options, using: .earliestArrival)

            #expect(StrategyTests.options == sourceOptions)
        }
    }

    @Suite("Partner-sponsored strategy")
    struct PartnerSponsoredStrategy {
        @Test("Captures campaign scores inside the selected strategy")
        func ranksPartnerSponsoredOptions() {
            let strategy = DeliveryRankingStrategy.partnerSponsored(
                pointsByOptionID: StrategyTests.firstCampaignPoints
            )

            let rankedOptions = rankDeliveryOptions(
                StrategyTests.options,
                using: strategy
            )

            #expect(rankedOptions.map(\.id) == [
                "parcel-locker", "standard-home", "express-courier"
            ])
        }

        @Test("Uses zero points for an option missing from the campaign")
        func defaultsMissingPartnerScore() {
            let strategy = DeliveryRankingStrategy.partnerSponsored(
                pointsByOptionID: ["parcel-locker": 80]
            )

            let rankedOptions = rankDeliveryOptions(
                StrategyTests.options,
                using: strategy
            )

            #expect(rankedOptions.map(\.id) == [
                "parcel-locker", "express-courier", "standard-home"
            ])
        }

        @Test("A new campaign snapshot creates new behavior without editing the ranker")
        func respondsToUpdatedPartnerCampaign() {
            let firstStrategy = DeliveryRankingStrategy.partnerSponsored(
                pointsByOptionID: StrategyTests.firstCampaignPoints
            )
            let updatedStrategy = DeliveryRankingStrategy.partnerSponsored(
                pointsByOptionID: StrategyTests.updatedCampaignPoints
            )

            let firstRanking = rankDeliveryOptions(
                StrategyTests.options,
                using: firstStrategy
            )
            let updatedRanking = rankDeliveryOptions(
                StrategyTests.options,
                using: updatedStrategy
            )

            #expect(firstRanking.first?.id == "parcel-locker")
            #expect(updatedRanking.first?.id == "express-courier")
        }
    }
}
