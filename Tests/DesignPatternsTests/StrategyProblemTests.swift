import DesignPatterns
import Testing

@Suite("Strategy problem")
struct StrategyProblemTests {
    private let options = [
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
        let rankedOptions = rankDeliveryOptions(options, by: preference)

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
        let sourceOptions = options

        _ = rankDeliveryOptions(options, by: .earliestArrival)

        #expect(options == sourceOptions)
    }
}
