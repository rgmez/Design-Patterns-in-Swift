/// Synchronous teaching modules. Each checkout owns its instances and callbacks.
public final class CheckoutAddressModule {
    public private(set) var address: CheckoutDeliveryAddress?
    public var onChange: ((CheckoutDeliveryAddress) -> Void)?

    public init() {}

    public func update(_ address: CheckoutDeliveryAddress) {
        guard self.address != address else { return }
        self.address = address
        onChange?(address)
    }
}

public final class CheckoutDeliveryModule {
    private let slots: [CheckoutDeliverySlot]
    public private(set) var availableSlots: [CheckoutDeliverySlot] = []
    public private(set) var selectedSlot: CheckoutDeliverySlot?
    public var onChange: ((CheckoutDeliverySlot?, [CheckoutDeliverySlot]) -> Void)?

    public init(slots: [CheckoutDeliverySlot]) {
        precondition(Set(slots.map(\.id)).count == slots.count)
        self.slots = slots
    }

    public func updateAddress(_ address: CheckoutDeliveryAddress) {
        availableSlots = slots.filter { $0.supportedZones.contains(address.zone) }
        if let selectedSlot, !availableSlots.contains(selectedSlot) {
            self.selectedSlot = nil
        }
        onChange?(selectedSlot, availableSlots)
    }

    @discardableResult
    public func select(id: String) -> Bool {
        guard let slot = availableSlots.first(where: { $0.id == id }) else {
            return false
        }
        // Promotion refresh can request the slot that triggered that refresh.
        // Suppress unchanged writes before notifying to stop synchronous reentry.
        guard selectedSlot != slot else { return true }
        selectedSlot = slot
        onChange?(selectedSlot, availableSlots)
        return true
    }
}

public final class CheckoutPaymentModule {
    public private(set) var availableMethods: [CheckoutPaymentMethod] = []
    public private(set) var selectedMethod: CheckoutPaymentMethod?

    public init() {}

    public func updateSlot(_ slot: CheckoutDeliverySlot?) {
        availableMethods = slot?.paymentMethods ?? []
        if let selectedMethod, !availableMethods.contains(selectedMethod) {
            self.selectedMethod = nil
        }
    }

    @discardableResult
    public func select(_ method: CheckoutPaymentMethod) -> Bool {
        guard availableMethods.contains(method) else { return false }
        selectedMethod = method
        return true
    }
}

public final class CheckoutPromotionModule {
    private let offers: [CheckoutPromotionOffer]
    private var code: String?
    private var selectedSlot: CheckoutDeliverySlot?
    private var availableSlots: [CheckoutDeliverySlot] = []
    private var prefersEligibleSlot = false
    public var onSlotRequested: ((String) -> Void)?

    public init(offers: [CheckoutPromotionOffer]) {
        precondition(Set(offers.map(\.code)).count == offers.count)
        self.offers = offers
    }

    public var status: CheckoutPromotionStatus {
        guard let code else { return .notEntered }
        guard let offer = offers.first(where: { $0.code == code }) else {
            return .unavailable(code: code, issue: .unknownCode)
        }
        guard let selectedSlot else {
            return .unavailable(code: code, issue: .deliverySlotRequired)
        }
        guard offer.eligibleSlotIDs.contains(selectedSlot.id) else {
            return .unavailable(code: code, issue: .deliverySlotNotEligible)
        }
        return .eligible(code: code, discountCents: offer.discountCents)
    }

    public func apply(code: String) {
        precondition(!code.isEmpty)
        self.code = code
        prefersEligibleSlot = false
    }

    public func clear() {
        code = nil
        prefersEligibleSlot = false
    }

    /// The customer opts into keeping a window compatible with the promotion.
    public func preferEligibleDeliverySlot() {
        prefersEligibleSlot = true
        requestEligibleSlotIfNeeded()
    }

    public func updateSlot(
        _ slot: CheckoutDeliverySlot?,
        availableSlots: [CheckoutDeliverySlot]
    ) {
        selectedSlot = slot
        self.availableSlots = availableSlots
        requestEligibleSlotIfNeeded()
    }

    private func requestEligibleSlotIfNeeded() {
        guard prefersEligibleSlot,
              let offer = offers.first(where: { $0.code == code }) else { return }
        let preferredSlot = availableSlots.first { $0.id == selectedSlot?.id
            && offer.eligibleSlotIDs.contains($0.id) }
            ?? availableSlots.first { offer.eligibleSlotIDs.contains($0.id) }
        guard let preferredSlot else { return }
        onSlotRequested?(preferredSlot.id)
    }
}

/// Composition root for the direct callback graph, before introducing Mediator.
public final class DirectDeliveryCheckoutModules {
    public let address: CheckoutAddressModule
    public let delivery: CheckoutDeliveryModule
    public let promotion: CheckoutPromotionModule
    public let payment: CheckoutPaymentModule

    public init(
        slots: [CheckoutDeliverySlot],
        promotions: [CheckoutPromotionOffer]
    ) {
        let address = CheckoutAddressModule()
        let delivery = CheckoutDeliveryModule(slots: slots)
        let promotion = CheckoutPromotionModule(offers: promotions)
        let payment = CheckoutPaymentModule()
        self.address = address
        self.delivery = delivery
        self.promotion = promotion
        self.payment = payment

        address.onChange = { [weak delivery] address in
            delivery?.updateAddress(address)
        }
        delivery.onChange = { [weak payment, weak promotion] slot, availableSlots in
            // Promotion may synchronously choose a different slot. Updating
            // payment afterward would overwrite the corrected state with `slot`.
            payment?.updateSlot(slot)
            promotion?.updateSlot(slot, availableSlots: availableSlots)
        }
        promotion.onSlotRequested = { [weak delivery] id in
            delivery?.select(id: id)
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
}
