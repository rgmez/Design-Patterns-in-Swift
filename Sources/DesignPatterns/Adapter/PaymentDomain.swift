public struct PaymentRequest: Equatable, Sendable {
    public let orderID: String
    public let amountInMinorUnits: Int
    public let currency: String
    public let paymentToken: String

    public init(
        orderID: String,
        amountInMinorUnits: Int,
        currency: String,
        paymentToken: String
    ) {
        self.orderID = orderID
        self.amountInMinorUnits = amountInMinorUnits
        self.currency = currency
        self.paymentToken = paymentToken
    }
}

public struct PaymentAuthorization: Equatable, Sendable {
    public let paymentID: String
    public let orderID: String

    public init(paymentID: String, orderID: String) {
        self.paymentID = paymentID
        self.orderID = orderID
    }
}

public enum PaymentError: Error, Equatable, Sendable {
    case declined
    case temporarilyUnavailable
    case invalidRequest
}
