public enum DeliverySortPreference: Equatable, Sendable {
    case lowestCost
    case earliestArrival
    case lowestCarbon
    case partnerSponsored
}

public func rankDeliveryOptions(
    _ options: [DeliveryOption],
    by preference: DeliverySortPreference
) -> [DeliveryOption] {
    rankDeliveryOptions(options, by: preference, context: .empty)
}

public struct DeliveryRankingContext: Equatable, Sendable {
    public let partnerPointsByOptionID: [String: Int]

    public init(partnerPointsByOptionID: [String: Int] = [:]) {
        self.partnerPointsByOptionID = partnerPointsByOptionID
    }

    fileprivate static let empty = DeliveryRankingContext()
}

public func rankDeliveryOptions(
    _ options: [DeliveryOption],
    by preference: DeliverySortPreference,
    context: DeliveryRankingContext
) -> [DeliveryOption] {
    options.sorted { first, second in
        let firstValue: Int
        let secondValue: Int

        switch preference {
        case .lowestCost:
            firstValue = first.feeInMinorUnits
            secondValue = second.feeInMinorUnits
        case .earliestArrival:
            firstValue = first.estimatedArrivalDays
            secondValue = second.estimatedArrivalDays
        case .lowestCarbon:
            firstValue = first.carbonGrams
            secondValue = second.carbonGrams
        case .partnerSponsored:
            firstValue = context.partnerPointsByOptionID[first.id, default: 0]
            secondValue = context.partnerPointsByOptionID[second.id, default: 0]
        }

        if firstValue == secondValue {
            return first.id < second.id
        }

        if preference == .partnerSponsored {
            return firstValue > secondValue
        }

        return firstValue < secondValue
    }
}
