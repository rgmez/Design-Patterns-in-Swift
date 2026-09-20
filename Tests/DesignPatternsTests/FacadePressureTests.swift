import DesignPatterns
import Testing

@Suite("Facade pressure")
struct FacadePressureTests {
    private static let checkoutID = "checkout-2048"
    private static let customerID = "customer-31"
    private static let sku = "espresso-machine"
    private static let quantity = 1
    private static let unitPrice = 24_999
    private static let initialStock = 2
    private static let acceptedToken = "card-token-approved"
    private static let declinedToken = "card-token-declined"
    private static let expectedReservationID = "reservation-checkout-2048"
    private static let expectedPaymentID = "payment-checkout-2048"
    private static let expectedOrderID = "order-checkout-2048"

    private static func makeSubmission(
        paymentToken: String = acceptedToken
    ) throws -> CheckoutSubmission {
        try CheckoutSubmission(
            checkoutID: checkoutID,
            customerID: customerID,
            items: [
                try CheckoutLineItem(
                    sku: sku,
                    quantity: quantity,
                    unitPriceInMinorUnits: unitPrice
                )
            ],
            paymentToken: paymentToken
        )
    }

    private static func makeInventory() -> CheckoutInventory {
        CheckoutInventory(availableQuantityBySKU: [sku: initialStock])
    }

    @Suite("Additional entry points")
    struct AdditionalEntryPoints {
        @Test("Buy Again repeats the complete successful checkout flow")
        func buyAgainCoordinatesSubsystems() throws {
            var shortcut = DirectBuyAgainShortcut(
                inventory: FacadePressureTests.makeInventory(),
                payments: CheckoutPayments()
            )

            let order = try shortcut.placeOrder(
                from: FacadePressureTests.makeSubmission()
            )

            #expect(order.id == FacadePressureTests.expectedOrderID)
            #expect(
                order.reservationID
                    == FacadePressureTests.expectedReservationID
            )
            #expect(
                order.paymentAuthorizationID
                    == FacadePressureTests.expectedPaymentID
            )
            #expect(shortcut.inventory.reservationAttempts == 1)
            #expect(shortcut.payments.authorizationAttempts == 1)
            #expect(shortcut.orders.orders == [order])
            #expect(
                shortcut.analytics.events == [
                    .completed(
                        checkoutID: FacadePressureTests.checkoutID,
                        orderID: FacadePressureTests.expectedOrderID,
                        totalInMinorUnits: FacadePressureTests.unitPrice
                    )
                ]
            )
        }

        @Test("Payment retry repeats the complete successful checkout flow")
        func paymentRetryCoordinatesSubsystems() throws {
            var banner = DirectPaymentRetryBanner(
                inventory: FacadePressureTests.makeInventory(),
                payments: CheckoutPayments()
            )

            let order = try banner.placeOrder(
                from: FacadePressureTests.makeSubmission()
            )

            #expect(order.id == FacadePressureTests.expectedOrderID)
            #expect(
                banner.inventory.availableQuantity(
                    for: FacadePressureTests.sku
                ) == FacadePressureTests.initialStock - 1
            )
            #expect(
                banner.inventory.hasReservation(
                    id: FacadePressureTests.expectedReservationID
                )
            )
            #expect(banner.payments.authorizations.count == 1)
            #expect(banner.orders.orders == [order])
            #expect(banner.analytics.events.count == 1)
        }
    }

    @Suite("Duplicated compensation")
    struct DuplicatedCompensation {
        @Test("Buy Again restores stock after payment declines")
        func buyAgainReleasesReservation() throws {
            var shortcut = DirectBuyAgainShortcut(
                inventory: FacadePressureTests.makeInventory(),
                payments: CheckoutPayments(
                    declinedTokens: [FacadePressureTests.declinedToken]
                )
            )

            #expect(throws: CheckoutError.paymentDeclined) {
                try shortcut.placeOrder(
                    from: FacadePressureTests.makeSubmission(
                        paymentToken: FacadePressureTests.declinedToken
                    )
                )
            }

            #expect(shortcut.inventory.releaseCount == 1)
            #expect(
                shortcut.inventory.availableQuantity(
                    for: FacadePressureTests.sku
                ) == FacadePressureTests.initialStock
            )
            #expect(shortcut.orders.orders.isEmpty)
            #expect(
                shortcut.analytics.events == [
                    .failed(
                        checkoutID: FacadePressureTests.checkoutID,
                        reason: .paymentDeclined
                    )
                ]
            )
        }

        @Test("Payment retry restores stock after another decline")
        func paymentRetryReleasesReservation() throws {
            var banner = DirectPaymentRetryBanner(
                inventory: FacadePressureTests.makeInventory(),
                payments: CheckoutPayments(
                    declinedTokens: [FacadePressureTests.declinedToken]
                )
            )

            #expect(throws: CheckoutError.paymentDeclined) {
                try banner.placeOrder(
                    from: FacadePressureTests.makeSubmission(
                        paymentToken: FacadePressureTests.declinedToken
                    )
                )
            }

            #expect(banner.inventory.releaseCount == 1)
            #expect(
                banner.inventory.hasReservation(
                    id: FacadePressureTests.expectedReservationID
                ) == false
            )
            #expect(banner.orders.orders.isEmpty)
            #expect(
                banner.analytics.events == [
                    .failed(
                        checkoutID: FacadePressureTests.checkoutID,
                        reason: .paymentDeclined
                    )
                ]
            )
        }
    }
}
