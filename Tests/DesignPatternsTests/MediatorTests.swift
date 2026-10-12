import DesignPatterns
import Testing

@Suite("Mediator")
struct MediatorTests {
    private static let central = CheckoutDeliveryAddress(postalCode: "28013", zone: .central)
    private static let outer = CheckoutDeliveryAddress(postalCode: "28660", zone: .outer)
    private static let code = "SCHEDULE10"
    private static let discount = 1_000
    private static let unknownCode = "UNKNOWN"
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

    private static func makeCheckout() -> DeliveryCheckoutMediator {
        DeliveryCheckoutMediator(slots: [express, evening, nextDay], promotions: [offer])
    }

    @Suite("Coordination")
    struct Coordination {
        @Test("Address invalidation clears the slot, payment, and promotion eligibility")
        func invalidatesDependents() throws {
            let checkout = MediatorTests.makeCheckout()
            checkout.address.update(MediatorTests.central)
            try #require(checkout.delivery.select(id: MediatorTests.evening.id))
            try #require(checkout.payment.select(.cashOnDelivery))
            checkout.promotion.apply(code: MediatorTests.code)
            try #require(checkout.snapshot.canPlaceOrder)

            checkout.address.update(MediatorTests.outer)

            #expect(checkout.snapshot.availableSlots == [MediatorTests.nextDay])
            #expect(checkout.snapshot.selectedSlotID == nil)
            #expect(checkout.snapshot.selectedPaymentMethod == nil)
            #expect(checkout.snapshot.canPlaceOrder == false)
            #expect(checkout.snapshot.promotionStatus == .unavailable(
                code: MediatorTests.code, issue: .deliverySlotRequired
            ))
        }

        @Test("Rejected choices leave the coherent snapshot unchanged")
        func rejectsUnavailableChoices() {
            let checkout = MediatorTests.makeCheckout()
            checkout.address.update(MediatorTests.outer)
            let before = checkout.snapshot
            #expect(checkout.delivery.select(id: MediatorTests.express.id) == false)
            #expect(checkout.payment.select(.cashOnDelivery) == false)
            #expect(checkout.snapshot == before)
        }

        @Test("Unknown promotion codes do not change core checkout selections")
        func unknownPromotion() throws {
            let checkout = MediatorTests.makeCheckout()
            checkout.address.update(MediatorTests.central)
            try #require(checkout.delivery.select(id: MediatorTests.express.id))
            try #require(checkout.payment.select(.card))
            checkout.promotion.apply(code: MediatorTests.unknownCode)
            checkout.promotion.preferEligibleDeliverySlot()
            #expect(checkout.snapshot.selectedSlotID == MediatorTests.express.id)
            #expect(checkout.snapshot.canPlaceOrder)
            #expect(checkout.snapshot.promotionStatus == .unavailable(
                code: MediatorTests.unknownCode, issue: .unknownCode
            ))
        }
    }

    @Suite("Corrective callbacks")
    struct CorrectiveCallbacks {
        @Test("No eligible window leaves the current choice intact")
        func noEligibleWindow() throws {
            let checkout = DeliveryCheckoutMediator(
                slots: [MediatorTests.express], promotions: [MediatorTests.offer]
            )
            checkout.address.update(MediatorTests.central)
            try #require(checkout.delivery.select(id: MediatorTests.express.id))
            checkout.promotion.apply(code: MediatorTests.code)
            let before = checkout.snapshot

            checkout.promotion.preferEligibleDeliverySlot()

            #expect(checkout.snapshot == before)
        }

        @Test("Promotion preference selects a compatible window without recursive notifications")
        func promotionSelectsWindow() throws {
            let checkout = MediatorTests.makeCheckout()
            checkout.address.update(MediatorTests.central)
            try #require(checkout.delivery.select(id: MediatorTests.express.id))
            checkout.promotion.apply(code: MediatorTests.code)

            checkout.promotion.preferEligibleDeliverySlot()

            #expect(checkout.snapshot.selectedSlotID == MediatorTests.evening.id)
            #expect(checkout.snapshot.availablePaymentMethods == [.card, .cashOnDelivery])
            #expect(checkout.snapshot.promotionStatus == .eligible(
                code: MediatorTests.code, discountCents: MediatorTests.discount
            ))
        }

        @Test("A corrective slot change preserves cash after resolving the final slot")
        func reentrantCorrectionKeepsPaymentCoherent() throws {
            let checkout = MediatorTests.makeCheckout()
            checkout.address.update(MediatorTests.central)
            checkout.promotion.apply(code: MediatorTests.code)
            checkout.promotion.preferEligibleDeliverySlot()
            try #require(checkout.payment.select(.cashOnDelivery))

            try #require(checkout.delivery.select(id: MediatorTests.express.id))

            #expect(checkout.snapshot.selectedSlotID == MediatorTests.evening.id)
            #expect(checkout.snapshot.availablePaymentMethods == [.card, .cashOnDelivery])
            #expect(checkout.snapshot.selectedPaymentMethod == .cashOnDelivery)
            #expect(checkout.snapshot.canPlaceOrder)
        }

        @Test("Preference follows the address and drops an incompatible payment")
        func preferenceFollowsNewZone() throws {
            let checkout = MediatorTests.makeCheckout()
            checkout.address.update(MediatorTests.central)
            checkout.promotion.apply(code: MediatorTests.code)
            checkout.promotion.preferEligibleDeliverySlot()
            try #require(checkout.payment.select(.cashOnDelivery))

            checkout.address.update(MediatorTests.outer)

            #expect(checkout.snapshot.selectedSlotID == MediatorTests.nextDay.id)
            #expect(checkout.snapshot.availablePaymentMethods == [.card])
            #expect(checkout.snapshot.selectedPaymentMethod == nil)
            #expect(checkout.snapshot.promotionStatus == .eligible(
                code: MediatorTests.code, discountCents: MediatorTests.discount
            ))
        }

        @Test("Clearing promotion removes its delivery preference")
        func clearingPromotionRemovesPreference() throws {
            let checkout = MediatorTests.makeCheckout()
            checkout.address.update(MediatorTests.central)
            checkout.promotion.apply(code: MediatorTests.code)
            checkout.promotion.preferEligibleDeliverySlot()
            checkout.promotion.clear()

            try #require(checkout.delivery.select(id: MediatorTests.express.id))

            #expect(checkout.snapshot.selectedSlotID == MediatorTests.express.id)
            #expect(checkout.snapshot.promotionStatus == .notEntered)
        }

        @Test("Replacing the promotion code removes the previous preference")
        func replacingCodeRemovesPreference() throws {
            let checkout = MediatorTests.makeCheckout()
            checkout.address.update(MediatorTests.central)
            checkout.promotion.apply(code: MediatorTests.code)
            checkout.promotion.preferEligibleDeliverySlot()
            try #require(checkout.delivery.select(id: MediatorTests.evening.id))

            checkout.promotion.apply(code: MediatorTests.unknownCode)
            try #require(checkout.delivery.select(id: MediatorTests.express.id))

            #expect(checkout.snapshot.selectedSlotID == MediatorTests.express.id)
            #expect(checkout.snapshot.promotionStatus == .unavailable(
                code: MediatorTests.unknownCode, issue: .unknownCode
            ))
        }
    }

    @Suite("Ownership")
    struct Ownership {
        @Test("The callback cycle does not retain participants after checkout release")
        func releasesParticipants() {
            weak var mediator: DeliveryCheckoutMediator?
            weak var address: CheckoutAddressModule?
            weak var delivery: CheckoutDeliveryModule?
            weak var promotion: CheckoutPromotionModule?
            weak var payment: CheckoutPaymentModule?
            do {
                let checkout = MediatorTests.makeCheckout()
                mediator = checkout
                address = checkout.address
                delivery = checkout.delivery
                promotion = checkout.promotion
                payment = checkout.payment
            }

            #expect(mediator == nil)
            #expect(address == nil)
            #expect(delivery == nil)
            #expect(promotion == nil)
            #expect(payment == nil)
        }
    }
}
