import DesignPatterns
import Testing

@Suite("Mediator problem")
struct MediatorProblemTests {
    private static let expressSlotID = "express-45"
    private static let eveningSlotID = "evening-window"
    private static let outerSlotID = "outer-next-day"
    private static let promotionCode = "SCHEDULE10"
    private static let promotionDiscountCents = 1_000
    private static let centralAddress = CheckoutDeliveryAddress(
        postalCode: "28013",
        zone: .central
    )
    private static let outerAddress = CheckoutDeliveryAddress(
        postalCode: "28660",
        zone: .outer
    )
    private static let expressSlot = CheckoutDeliverySlot(
        id: expressSlotID,
        title: "Express · 45 minutes",
        supportedZones: [.central],
        paymentMethods: [.card]
    )
    private static let eveningSlot = CheckoutDeliverySlot(
        id: eveningSlotID,
        title: "Today · 19:00–21:00",
        supportedZones: [.central, .outer],
        paymentMethods: [.card, .cashOnDelivery]
    )
    private static let outerSlot = CheckoutDeliverySlot(
        id: outerSlotID,
        title: "Tomorrow · 10:00–12:00",
        supportedZones: [.outer],
        paymentMethods: [.card, .cashOnDelivery]
    )
    private static let scheduledPromotion = CheckoutPromotionOffer(
        code: promotionCode,
        discountCents: promotionDiscountCents,
        eligibleSlotIDs: [eveningSlotID, outerSlotID]
    )

    private static func makeForm() -> DirectDeliveryCheckoutForm {
        DirectDeliveryCheckoutForm(
            slots: [expressSlot, eveningSlot, outerSlot],
            promotions: [scheduledPromotion]
        )
    }

    @Suite("Address coordination")
    struct AddressCoordination {
        @Test("Exposes only delivery slots that serve the current address")
        func filtersSlotsByZone() {
            var form = MediatorProblemTests.makeForm()

            form.updateAddress(MediatorProblemTests.centralAddress)

            #expect(
                form.snapshot.availableSlots.map(\.id) == [
                    MediatorProblemTests.expressSlotID,
                    MediatorProblemTests.eveningSlotID
                ]
            )
        }

        @Test("Clears dependent selections when an address invalidates the slot")
        func clearsSelectionsForNewZone() {
            var form = MediatorProblemTests.makeForm()
            form.updateAddress(MediatorProblemTests.centralAddress)
            let didSelectSlot = form.selectDeliverySlot(
                id: MediatorProblemTests.expressSlotID
            )
            let didSelectPayment = form.selectPaymentMethod(.card)
            form.applyPromotionCode(MediatorProblemTests.promotionCode)

            #expect(didSelectSlot)
            #expect(didSelectPayment)

            form.updateAddress(MediatorProblemTests.outerAddress)

            #expect(form.snapshot.selectedSlotID == nil)
            #expect(form.snapshot.selectedPaymentMethod == nil)
            #expect(
                form.snapshot.promotionStatus == .unavailable(
                    code: MediatorProblemTests.promotionCode,
                    issue: .deliverySlotRequired
                )
            )
        }
    }

    @Suite("Delivery-slot coordination")
    struct DeliverySlotCoordination {
        @Test("Rejects selections that are unavailable in the current form")
        func rejectsUnavailableSelections() {
            var form = MediatorProblemTests.makeForm()
            form.updateAddress(MediatorProblemTests.outerAddress)

            let didSelectCentralSlot = form.selectDeliverySlot(
                id: MediatorProblemTests.expressSlotID
            )
            let didSelectPaymentWithoutSlot = form.selectPaymentMethod(.card)

            #expect(didSelectCentralSlot == false)
            #expect(didSelectPaymentWithoutSlot == false)
            #expect(form.snapshot.selectedSlotID == nil)
            #expect(form.snapshot.selectedPaymentMethod == nil)
        }

        @Test("Reevaluates promotion eligibility from the selected slot")
        func reevaluatesPromotion() {
            var form = MediatorProblemTests.makeForm()
            form.updateAddress(MediatorProblemTests.centralAddress)
            form.applyPromotionCode(MediatorProblemTests.promotionCode)

            #expect(
                form.snapshot.promotionStatus == .unavailable(
                    code: MediatorProblemTests.promotionCode,
                    issue: .deliverySlotRequired
                )
            )
            let didSelectEveningSlot = form.selectDeliverySlot(
                id: MediatorProblemTests.eveningSlotID
            )
            #expect(didSelectEveningSlot)
            #expect(
                form.snapshot.promotionStatus == .eligible(
                    code: MediatorProblemTests.promotionCode,
                    discountCents: MediatorProblemTests.promotionDiscountCents
                )
            )
            let didSelectExpressSlot = form.selectDeliverySlot(
                id: MediatorProblemTests.expressSlotID
            )
            #expect(didSelectExpressSlot)
            #expect(
                form.snapshot.promotionStatus == .unavailable(
                    code: MediatorProblemTests.promotionCode,
                    issue: .deliverySlotNotEligible
                )
            )
        }

        @Test("Drops cash when the new slot requires card payment")
        func dropsUnavailablePayment() {
            var form = MediatorProblemTests.makeForm()
            form.updateAddress(MediatorProblemTests.centralAddress)
            let didSelectEveningSlot = form.selectDeliverySlot(
                id: MediatorProblemTests.eveningSlotID
            )
            let didSelectCash = form.selectPaymentMethod(.cashOnDelivery)

            #expect(didSelectEveningSlot)
            #expect(didSelectCash)

            let didSelectExpressSlot = form.selectDeliverySlot(
                id: MediatorProblemTests.expressSlotID
            )

            #expect(didSelectExpressSlot)
            #expect(form.snapshot.availablePaymentMethods == [.card])
            #expect(form.snapshot.selectedPaymentMethod == nil)
        }
    }

    @Suite("Order readiness")
    struct OrderReadiness {
        @Test("Becomes ready only after address, slot, and payment agree")
        func requiresCoherentSelections() {
            var form = MediatorProblemTests.makeForm()

            #expect(form.snapshot.canPlaceOrder == false)
            form.updateAddress(MediatorProblemTests.outerAddress)
            #expect(form.snapshot.canPlaceOrder == false)
            let didSelectSlot = form.selectDeliverySlot(
                id: MediatorProblemTests.outerSlotID
            )
            #expect(didSelectSlot)
            #expect(form.snapshot.canPlaceOrder == false)
            let didSelectPayment = form.selectPaymentMethod(.cashOnDelivery)
            #expect(didSelectPayment)
            #expect(form.snapshot.canPlaceOrder)
        }
    }
}
