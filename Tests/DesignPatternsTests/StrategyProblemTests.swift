import DesignPatterns
import Testing

@Suite("Strategy problem")
struct StrategyProblemTests {
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
    private static let firstCampaign = DeliveryRankingContext(partnerPointsByOptionID: [
        "express-courier": 15,
        "parcel-locker": 80,
        "standard-home": 35
    ])
    private static let updatedCampaign = DeliveryRankingContext(partnerPointsByOptionID: [
        "express-courier": 95,
        "parcel-locker": 20,
        "standard-home": 35
    ])

    @Suite("Built-in preferences")
    struct BuiltInPreferences {
        @Test("Ranks the same options by the selected checkout preference", arguments: [
            (DeliverySortPreference.lowestCost, [
                "standard-home", "parcel-locker", "express-courier"
            ]),
            (DeliverySortPreference.earliestArrival, [
                "express-courier", "parcel-locker", "standard-home"
            ]),
            (DeliverySortPreference.lowestCarbon, [
                "parcel-locker", "standard-home", "express-courier"
            ])
        ])
        func ranksBySelectedPreference(
            _ preference: DeliverySortPreference,
            expectedIDs: [String]
        ) {
            let rankedOptions = rankDeliveryOptions(StrategyProblemTests.options, by: preference)

            #expect(rankedOptions.map(\.id) == expectedIDs)
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

            let rankedOptions = rankDeliveryOptions(tiedOptions, by: .lowestCost)

            #expect(rankedOptions.map(\.id) == ["collection-point", "weekend-home"])
        }

        @Test("Leaves the fulfillment response unchanged")
        func preservesSourceOptions() {
            let sourceOptions = StrategyProblemTests.options

            _ = rankDeliveryOptions(StrategyProblemTests.options, by: .earliestArrival)

            #expect(StrategyProblemTests.options == sourceOptions)
        }
    }

    @Suite("Partner-sponsored preference")
    struct PartnerSponsoredPreference {
        @Test("Applies partner campaign scores supplied outside the ranking function")
        func ranksPartnerSponsoredOptions() {
            let rankedOptions = rankDeliveryOptions(
                StrategyProblemTests.options,
                by: .partnerSponsored,
                context: StrategyProblemTests.firstCampaign
            )

            #expect(rankedOptions.map(\.id) == [
                "parcel-locker", "standard-home", "express-courier"
            ])
        }

        @Test("Uses zero points for an option missing from the campaign")
        func defaultsMissingPartnerScore() {
            let campaign = DeliveryRankingContext(partnerPointsByOptionID: [
                "parcel-locker": 80
            ])

            let rankedOptions = rankDeliveryOptions(
                StrategyProblemTests.options,
                by: .partnerSponsored,
                context: campaign
            )

            #expect(rankedOptions.map(\.id) == [
                "parcel-locker", "express-courier", "standard-home"
            ])
        }

        @Test("Lets a campaign update change its policy without changing checkout code")
        func respondsToUpdatedPartnerCampaign() {
            let firstRanking = rankDeliveryOptions(
                StrategyProblemTests.options,
                by: .partnerSponsored,
                context: StrategyProblemTests.firstCampaign
            )
            let updatedRanking = rankDeliveryOptions(
                StrategyProblemTests.options,
                by: .partnerSponsored,
                context: StrategyProblemTests.updatedCampaign
            )

            #expect(firstRanking.first?.id == "parcel-locker")
            #expect(updatedRanking.first?.id == "express-courier")
        }
    }
}
