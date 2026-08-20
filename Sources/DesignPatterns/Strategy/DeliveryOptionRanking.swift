public enum DeliverySortPreference: Equatable, Sendable {
    case lowestCost
    case earliestArrival
    case lowestCarbon
}

public func rankDeliveryOptions(
    _ options: [DeliveryOption],
    by preference: DeliverySortPreference
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
        }

        if firstValue == secondValue {
            return first.id < second.id
        }

        return firstValue < secondValue
    }
}
