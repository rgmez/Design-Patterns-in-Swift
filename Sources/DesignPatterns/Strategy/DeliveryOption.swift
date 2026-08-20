public struct DeliveryOption: Equatable, Sendable {
    public let id: String
    public let feeInMinorUnits: Int
    public let estimatedArrivalDays: Int
    public let carbonGrams: Int

    public init(
        id: String,
        feeInMinorUnits: Int,
        estimatedArrivalDays: Int,
        carbonGrams: Int
    ) {
        self.id = id
        self.feeInMinorUnits = feeInMinorUnits
        self.estimatedArrivalDays = estimatedArrivalDays
        self.carbonGrams = carbonGrams
    }
}
