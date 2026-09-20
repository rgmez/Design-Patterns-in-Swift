public struct DirectBuyAgainShortcut: Sendable {
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

public struct DirectPaymentRetryBanner: Sendable {
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
