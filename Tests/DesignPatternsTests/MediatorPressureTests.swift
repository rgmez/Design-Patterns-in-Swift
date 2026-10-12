import DesignPatterns
import Testing

@Suite("Mediator pressure")
struct MediatorPressureTests {
    private static let central = CheckoutDeliveryAddress(postalCode: "28013", zone: .central)
    private static let outer = CheckoutDeliveryAddress(postalCode: "28660", zone: .outer)
    private static let code = "SCHEDULE10"
    private static let discount = 1_000
    private static let express = CheckoutDeliverySlot(
        id: "express", title: "Express", supportedZones: [.central], paymentMethods: [.card]
    )
    private static let evening = CheckoutDeliverySlot(
        id: "evening", title: "Evening", supportedZones: [.central],
        paymentMethods: [.card, .cashOnDelivery]
    )
    private static let nextDay = CheckoutDeliverySlot(
        id: "next-day", title: "Next day", supportedZones: [.outer], paymentMethods: [.card]
    )
    private static let offer = CheckoutPromotionOffer(
        code: code, discountCents: discount, eligibleSlotIDs: [evening.id, nextDay.id]
    )

    private static func makeCheckout() -> DirectDeliveryCheckoutModules {
        DirectDeliveryCheckoutModules(
            slots: [express, evening, nextDay], promotions: [offer]
        )
    }

    @Suite("Direct coordination")
    struct DirectCoordination {
        @Test("Address invalidation clears the slot, payment, and promotion eligibility")
        func invalidatesDependents() throws {
            let checkout = MediatorPressureTests.makeCheckout()
            checkout.address.update(MediatorPressureTests.central)
            try #require(checkout.delivery.select(id: MediatorPressureTests.evening.id))
            try #require(checkout.payment.select(.cashOnDelivery))
            checkout.promotion.apply(code: MediatorPressureTests.code)
            try #require(checkout.snapshot.canPlaceOrder)

            checkout.address.update(MediatorPressureTests.outer)

            #expect(checkout.snapshot.availableSlots == [MediatorPressureTests.nextDay])
            #expect(checkout.snapshot.selectedSlotID == nil)
            #expect(checkout.snapshot.selectedPaymentMethod == nil)
            #expect(checkout.snapshot.canPlaceOrder == false)
            #expect(checkout.snapshot.promotionStatus == .unavailable(
                code: MediatorPressureTests.code, issue: .deliverySlotRequired
            ))
        }

        @Test("Rejected choices leave the coherent snapshot unchanged")
        func rejectsUnavailableChoices() {
            let checkout = MediatorPressureTests.makeCheckout()
            checkout.address.update(MediatorPressureTests.outer)
            let before = checkout.snapshot
            #expect(checkout.delivery.select(id: MediatorPressureTests.express.id) == false)
            #expect(checkout.payment.select(.cashOnDelivery) == false)
            #expect(checkout.snapshot == before)
        }

        @Test("Unknown promotion codes do not change core checkout selections")
        func unknownPromotion() throws {
            let checkout = MediatorPressureTests.makeCheckout()
            checkout.address.update(MediatorPressureTests.central)
            try #require(checkout.delivery.select(id: MediatorPressureTests.express.id))
            try #require(checkout.payment.select(.card))
            checkout.promotion.apply(code: "UNKNOWN")
            checkout.promotion.preferEligibleDeliverySlot()
            #expect(checkout.snapshot.selectedSlotID == MediatorPressureTests.express.id)
            #expect(checkout.snapshot.canPlaceOrder)
            #expect(checkout.snapshot.promotionStatus == .unavailable(
                code: "UNKNOWN", issue: .unknownCode
            ))
        }
    }

    @Suite("Corrective callbacks")
    struct CorrectiveCallbacks {
        @Test("No eligible window leaves the current choice intact")
        func noEligibleWindow() throws {
            let checkout = DirectDeliveryCheckoutModules(
                slots: [MediatorPressureTests.express], promotions: [MediatorPressureTests.offer]
            )
            checkout.address.update(MediatorPressureTests.central)
            try #require(checkout.delivery.select(id: MediatorPressureTests.express.id))
            checkout.promotion.apply(code: MediatorPressureTests.code)
            let before = checkout.snapshot

            checkout.promotion.preferEligibleDeliverySlot()

            #expect(checkout.snapshot == before)
        }

        @Test("Promotion preference selects a compatible window without recursive notifications")
        func promotionSelectsWindow() throws {
            let checkout = MediatorPressureTests.makeCheckout()
            checkout.address.update(MediatorPressureTests.central)
            try #require(checkout.delivery.select(id: MediatorPressureTests.express.id))
            checkout.promotion.apply(code: MediatorPressureTests.code)

            checkout.promotion.preferEligibleDeliverySlot()

            #expect(checkout.snapshot.selectedSlotID == MediatorPressureTests.evening.id)
            #expect(checkout.snapshot.availablePaymentMethods == [.card, .cashOnDelivery])
            #expect(checkout.snapshot.promotionStatus == .eligible(
                code: MediatorPressureTests.code, discountCents: MediatorPressureTests.discount
            ))
        }

        @Test("A corrective slot change cannot leave payment state from the outer callback")
        func reentrantCorrectionKeepsPaymentCoherent() throws {
            let checkout = MediatorPressureTests.makeCheckout()
            checkout.address.update(MediatorPressureTests.central)
            checkout.promotion.apply(code: MediatorPressureTests.code)
            checkout.promotion.preferEligibleDeliverySlot()
            try #require(checkout.payment.select(.cashOnDelivery))

            try #require(checkout.delivery.select(id: MediatorPressureTests.express.id))

            #expect(checkout.snapshot.selectedSlotID == MediatorPressureTests.evening.id)
            #expect(checkout.snapshot.availablePaymentMethods == [.card, .cashOnDelivery])
            #expect(checkout.snapshot.selectedPaymentMethod == nil)
            #expect(checkout.snapshot.canPlaceOrder == false)
        }

        @Test("Preference follows the address and drops an incompatible payment")
        func preferenceFollowsNewZone() throws {
            let checkout = MediatorPressureTests.makeCheckout()
            checkout.address.update(MediatorPressureTests.central)
            checkout.promotion.apply(code: MediatorPressureTests.code)
            checkout.promotion.preferEligibleDeliverySlot()
            try #require(checkout.payment.select(.cashOnDelivery))

            checkout.address.update(MediatorPressureTests.outer)

            #expect(checkout.snapshot.selectedSlotID == MediatorPressureTests.nextDay.id)
            #expect(checkout.snapshot.availablePaymentMethods == [.card])
            #expect(checkout.snapshot.selectedPaymentMethod == nil)
        }

        @Test("Clearing the promotion also removes its delivery preference")
        func clearPreference() throws {
            let checkout = MediatorPressureTests.makeCheckout()
            checkout.address.update(MediatorPressureTests.central)
            checkout.promotion.apply(code: MediatorPressureTests.code)
            checkout.promotion.preferEligibleDeliverySlot()
            checkout.promotion.clear()

            try #require(checkout.delivery.select(id: MediatorPressureTests.express.id))

            #expect(checkout.snapshot.selectedSlotID == MediatorPressureTests.express.id)
            #expect(checkout.snapshot.promotionStatus == .notEntered)
        }

        @Test("Selecting the current slot does not emit another change")
        func unchangedSelectionDoesNotNotify() throws {
            let delivery = CheckoutDeliveryModule(slots: [MediatorPressureTests.evening])
            delivery.updateAddress(MediatorPressureTests.central)
            var changes = 0
            delivery.onChange = { _, _ in changes += 1 }
            try #require(delivery.select(id: MediatorPressureTests.evening.id))
            try #require(delivery.select(id: MediatorPressureTests.evening.id))
            #expect(changes == 1)
        }
    }

    @Suite("Ownership")
    struct Ownership {
        @Test("The callback cycle does not retain participants after checkout release")
        func releasesParticipants() {
            weak var address: CheckoutAddressModule?
            weak var delivery: CheckoutDeliveryModule?
            weak var promotion: CheckoutPromotionModule?
            weak var payment: CheckoutPaymentModule?
            do {
                let checkout = MediatorPressureTests.makeCheckout()
                address = checkout.address
                delivery = checkout.delivery
                promotion = checkout.promotion
                payment = checkout.payment
            }

            #expect(address == nil)
            #expect(delivery == nil)
            #expect(promotion == nil)
            #expect(payment == nil)
        }
    }
}
