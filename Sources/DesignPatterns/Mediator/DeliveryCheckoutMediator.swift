/// Owns checkout interaction order; participants retain their domain validation.
public final class DeliveryCheckoutMediator {
    public let address: CheckoutAddressModule
    public let delivery: CheckoutDeliveryModule
    public let promotion: CheckoutPromotionModule
    public let payment: CheckoutPaymentModule
    private var isCoordinatingDelivery = false

    public init(
        slots: [CheckoutDeliverySlot],
        promotions: [CheckoutPromotionOffer]
    ) {
        address = CheckoutAddressModule()
        delivery = CheckoutDeliveryModule(slots: slots)
        promotion = CheckoutPromotionModule(offers: promotions)
        payment = CheckoutPaymentModule()

        address.onChange = { [weak self] address in
            self?.delivery.updateAddress(address)
        }
        delivery.onChange = { [weak self] _, _ in
            self?.coordinateDeliveryChange()
        }
        promotion.onSlotRequested = { [weak self] id in
            self?.delivery.select(id: id)
        }
    }

    public var snapshot: DeliveryCheckoutFormSnapshot {
        DeliveryCheckoutFormSnapshot(
            address: address.address,
            availableSlots: delivery.availableSlots,
            selectedSlotID: delivery.selectedSlot?.id,
            promotionStatus: promotion.status,
            availablePaymentMethods: payment.availableMethods,
            selectedPaymentMethod: payment.selectedMethod,
            canPlaceOrder: address.address != nil
                && delivery.selectedSlot != nil && payment.selectedMethod != nil
        )
    }

    private func coordinateDeliveryChange() {
        // A promotion can synchronously correct delivery. The outer transaction
        // reads that final selection; nested notifications must not commit payment.
        guard !isCoordinatingDelivery else { return }
        isCoordinatingDelivery = true
        defer { isCoordinatingDelivery = false }

        let initialSlot = delivery.selectedSlot
        promotion.updateSlot(initialSlot, availableSlots: delivery.availableSlots)

        if delivery.selectedSlot != initialSlot {
            // One correction is sufficient: promotion requests an available,
            // eligible slot and preserves it on refresh. No generic retry loop.
            promotion.updateSlot(
                delivery.selectedSlot,
                availableSlots: delivery.availableSlots
            )
        }
        payment.updateSlot(delivery.selectedSlot)
    }
}
