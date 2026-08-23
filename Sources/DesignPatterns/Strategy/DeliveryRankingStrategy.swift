public struct DeliveryRankingStrategy: Sendable {
    private enum Direction: Sendable {
        case ascending
        case descending
    }

    private let direction: Direction
    private let score: @Sendable (DeliveryOption) -> Int

    private init(
        direction: Direction,
        score: @escaping @Sendable (DeliveryOption) -> Int
    ) {
        self.direction = direction
        self.score = score
    }

    public static let lowestCost = DeliveryRankingStrategy(direction: .ascending) {
        $0.feeInMinorUnits
    }

    public static let earliestArrival = DeliveryRankingStrategy(direction: .ascending) {
        $0.estimatedArrivalDays
    }

    public static let lowestCarbon = DeliveryRankingStrategy(direction: .ascending) {
        $0.carbonGrams
    }

    public static func partnerSponsored(
        pointsByOptionID: [String: Int]
    ) -> DeliveryRankingStrategy {
        DeliveryRankingStrategy(direction: .descending) { option in
            pointsByOptionID[option.id, default: 0]
        }
    }

    fileprivate func orders(
        _ first: DeliveryOption,
        before second: DeliveryOption
    ) -> Bool {
        let firstScore = score(first)
        let secondScore = score(second)

        guard firstScore != secondScore else {
            return first.id < second.id
        }

        switch direction {
        case .ascending:
            return firstScore < secondScore
        case .descending:
            return firstScore > secondScore
        }
    }
}

public func rankDeliveryOptions(
    _ options: [DeliveryOption],
    using strategy: DeliveryRankingStrategy
) -> [DeliveryOption] {
    options.sorted { first, second in
        strategy.orders(first, before: second)
    }
}
