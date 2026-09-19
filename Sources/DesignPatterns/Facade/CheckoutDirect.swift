public struct CheckoutLineItem: Equatable, Sendable {
    public let sku: String
    public let quantity: Int
    public let unitPriceInMinorUnits: Int

    public init(
        sku: String,
        quantity: Int,
        unitPriceInMinorUnits: Int
    ) throws {
        guard !sku.isEmpty,
              quantity > 0,
              unitPriceInMinorUnits > 0 else {
            throw CheckoutError.invalidLineItem(sku: sku)
        }

        self.sku = sku
        self.quantity = quantity
        self.unitPriceInMinorUnits = unitPriceInMinorUnits
    }

    public var subtotalInMinorUnits: Int {
        quantity * unitPriceInMinorUnits
    }
}

public struct CheckoutSubmission: Equatable, Sendable {
    public let checkoutID: String
    public let customerID: String
    public let items: [CheckoutLineItem]
    public let paymentToken: String

    public init(
        checkoutID: String,
        customerID: String,
        items: [CheckoutLineItem],
        paymentToken: String
    ) throws {
        guard !checkoutID.isEmpty, !customerID.isEmpty else {
            throw CheckoutError.missingIdentity
        }
        guard !items.isEmpty else {
            throw CheckoutError.emptyCart
        }
        guard !paymentToken.isEmpty else {
            throw CheckoutError.missingPaymentToken
        }

        self.checkoutID = checkoutID
        self.customerID = customerID
        self.items = items
        self.paymentToken = paymentToken
    }

    public var totalInMinorUnits: Int {
        items.reduce(0) { total, item in
            total + item.subtotalInMinorUnits
        }
    }
}

public struct CheckoutInventoryReservation: Equatable, Sendable {
    public let id: String
    public let checkoutID: String
    public let items: [CheckoutLineItem]
}

public struct CheckoutInventory: Equatable, Sendable {
    public private(set) var reservationAttempts = 0
    public private(set) var releaseCount = 0

    private var availableQuantityBySKU: [String: Int]
    private var reservationsByID: [String: CheckoutInventoryReservation] = [:]

    public init(availableQuantityBySKU: [String: Int]) {
        self.availableQuantityBySKU = availableQuantityBySKU
    }

    public func availableQuantity(for sku: String) -> Int {
        availableQuantityBySKU[sku, default: 0]
    }

    public func hasReservation(id: String) -> Bool {
        reservationsByID[id] != nil
    }

    public mutating func reserve(
        _ items: [CheckoutLineItem],
        for checkoutID: String
    ) throws -> CheckoutInventoryReservation {
        reservationAttempts += 1

        var requestedQuantityBySKU: [String: Int] = [:]
        for item in items {
            requestedQuantityBySKU[item.sku, default: 0] += item.quantity
        }

        for (sku, requestedQuantity) in requestedQuantityBySKU {
            guard availableQuantity(for: sku) >= requestedQuantity else {
                throw CheckoutError.insufficientStock(sku: sku)
            }
        }

        for (sku, requestedQuantity) in requestedQuantityBySKU {
            availableQuantityBySKU[sku, default: 0] -= requestedQuantity
        }

        let reservation = CheckoutInventoryReservation(
            id: "reservation-\(checkoutID)",
            checkoutID: checkoutID,
            items: items
        )
        reservationsByID[reservation.id] = reservation
        return reservation
    }

    public mutating func release(reservationID: String) {
        guard let reservation = reservationsByID.removeValue(
            forKey: reservationID
        ) else {
            return
        }

        for item in reservation.items {
            availableQuantityBySKU[item.sku, default: 0] += item.quantity
        }
        releaseCount += 1
    }
}

public struct CheckoutPaymentAuthorization: Equatable, Sendable {
    public let id: String
    public let checkoutID: String
    public let amountInMinorUnits: Int
}

public struct CheckoutPayments: Equatable, Sendable {
    public private(set) var authorizationAttempts = 0
    public private(set) var authorizations: [CheckoutPaymentAuthorization] = []

    private let declinedTokens: Set<String>

    public init(declinedTokens: Set<String> = []) {
        self.declinedTokens = declinedTokens
    }

    public mutating func authorize(
        amountInMinorUnits: Int,
        paymentToken: String,
        checkoutID: String
    ) throws -> CheckoutPaymentAuthorization {
        authorizationAttempts += 1
        guard !declinedTokens.contains(paymentToken) else {
            throw CheckoutError.paymentDeclined
        }

        let authorization = CheckoutPaymentAuthorization(
            id: "payment-\(checkoutID)",
            checkoutID: checkoutID,
            amountInMinorUnits: amountInMinorUnits
        )
        authorizations.append(authorization)
        return authorization
    }
}

public struct CheckoutOrder: Equatable, Sendable {
    public let id: String
    public let checkoutID: String
    public let customerID: String
    public let reservationID: String
    public let paymentAuthorizationID: String
    public let totalInMinorUnits: Int
}

public struct CheckoutOrders: Equatable, Sendable {
    public private(set) var orders: [CheckoutOrder] = []

    public init() {}

    public mutating func create(
        from submission: CheckoutSubmission,
        reservation: CheckoutInventoryReservation,
        authorization: CheckoutPaymentAuthorization
    ) -> CheckoutOrder {
        let order = CheckoutOrder(
            id: "order-\(submission.checkoutID)",
            checkoutID: submission.checkoutID,
            customerID: submission.customerID,
            reservationID: reservation.id,
            paymentAuthorizationID: authorization.id,
            totalInMinorUnits: submission.totalInMinorUnits
        )
        orders.append(order)
        return order
    }
}

public enum CheckoutFailureReason: Equatable, Sendable {
    case inventoryUnavailable
    case paymentDeclined
}

public enum CheckoutAnalyticsEvent: Equatable, Sendable {
    case completed(
        checkoutID: String,
        orderID: String,
        totalInMinorUnits: Int
    )
    case failed(checkoutID: String, reason: CheckoutFailureReason)
}

public struct CheckoutAnalytics: Equatable, Sendable {
    public private(set) var events: [CheckoutAnalyticsEvent] = []

    public init() {}

    public mutating func record(_ event: CheckoutAnalyticsEvent) {
        events.append(event)
    }
}

public enum CheckoutError: Error, Equatable, Sendable {
    case missingIdentity
    case emptyCart
    case missingPaymentToken
    case invalidLineItem(sku: String)
    case insufficientStock(sku: String)
    case paymentDeclined
}

public struct DirectCheckoutScreen: Sendable {
    public private(set) var inventory: CheckoutInventory
    public private(set) var payments: CheckoutPayments
    public private(set) var orders: CheckoutOrders
    public private(set) var analytics: CheckoutAnalytics

    public init(
        inventory: CheckoutInventory,
        payments: CheckoutPayments,
        orders: CheckoutOrders = CheckoutOrders(),
        analytics: CheckoutAnalytics = CheckoutAnalytics()
    ) {
        self.inventory = inventory
        self.payments = payments
        self.orders = orders
        self.analytics = analytics
    }

    public mutating func placeOrder(
        from submission: CheckoutSubmission
    ) throws -> CheckoutOrder {
        let reservation: CheckoutInventoryReservation
        do {
            reservation = try inventory.reserve(
                submission.items,
                for: submission.checkoutID
            )
        } catch {
            analytics.record(
                .failed(
                    checkoutID: submission.checkoutID,
                    reason: .inventoryUnavailable
                )
            )
            throw error
        }

        let authorization: CheckoutPaymentAuthorization
        do {
            authorization = try payments.authorize(
                amountInMinorUnits: submission.totalInMinorUnits,
                paymentToken: submission.paymentToken,
                checkoutID: submission.checkoutID
            )
        } catch {
            inventory.release(reservationID: reservation.id)
            analytics.record(
                .failed(
                    checkoutID: submission.checkoutID,
                    reason: .paymentDeclined
                )
            )
            throw error
        }

        let order = orders.create(
            from: submission,
            reservation: reservation,
            authorization: authorization
        )
        analytics.record(
            .completed(
                checkoutID: submission.checkoutID,
                orderID: order.id,
                totalInMinorUnits: order.totalInMinorUnits
            )
        )
        return order
    }
}
