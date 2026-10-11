public enum CheckoutDeliveryZone: Equatable, Hashable, Sendable {
    case central
    case outer
}

public struct CheckoutDeliveryAddress: Equatable, Sendable {
    public let postalCode: String
    public let zone: CheckoutDeliveryZone

    public init(
        postalCode: String,
        zone: CheckoutDeliveryZone
    ) {
        precondition(!postalCode.isEmpty, "A delivery address needs a postal code")

        self.postalCode = postalCode
        self.zone = zone
    }
}

public enum CheckoutPaymentMethod: Equatable, Hashable, Sendable {
    case card
    case cashOnDelivery
}

public struct CheckoutDeliverySlot: Equatable, Sendable {
    public let id: String
    public let title: String
    public let supportedZones: Set<CheckoutDeliveryZone>
    public let paymentMethods: [CheckoutPaymentMethod]

    public init(
        id: String,
        title: String,
        supportedZones: Set<CheckoutDeliveryZone>,
        paymentMethods: [CheckoutPaymentMethod]
    ) {
        precondition(!id.isEmpty, "A delivery slot needs an identifier")
        precondition(!title.isEmpty, "A delivery slot needs a title")
        precondition(
            !supportedZones.isEmpty,
            "A delivery slot must support at least one zone"
        )
        precondition(
            !paymentMethods.isEmpty,
            "A delivery slot must accept at least one payment method"
        )
        precondition(
            Set(paymentMethods).count == paymentMethods.count,
            "A delivery slot cannot repeat payment methods"
        )

        self.id = id
        self.title = title
        self.supportedZones = supportedZones
        self.paymentMethods = paymentMethods
    }
}

public struct CheckoutPromotionOffer: Equatable, Sendable {
    public let code: String
    public let discountCents: Int
    public let eligibleSlotIDs: Set<String>

    public init(
        code: String,
        discountCents: Int,
        eligibleSlotIDs: Set<String>
    ) {
        precondition(!code.isEmpty, "A promotion needs a code")
        precondition(discountCents > 0, "A promotion discount must be positive")
        precondition(
            !eligibleSlotIDs.isEmpty,
            "A promotion must apply to at least one delivery slot"
        )

        self.code = code
        self.discountCents = discountCents
        self.eligibleSlotIDs = eligibleSlotIDs
    }
}

public enum CheckoutPromotionIssue: Equatable, Sendable {
    case unknownCode
    case deliverySlotRequired
    case deliverySlotNotEligible
}

public enum CheckoutPromotionStatus: Equatable, Sendable {
    case notEntered
    case eligible(code: String, discountCents: Int)
    case unavailable(code: String, issue: CheckoutPromotionIssue)
}

public struct DeliveryCheckoutFormSnapshot: Equatable, Sendable {
    public let address: CheckoutDeliveryAddress?
    public let availableSlots: [CheckoutDeliverySlot]
    public let selectedSlotID: String?
    public let promotionStatus: CheckoutPromotionStatus
    public let availablePaymentMethods: [CheckoutPaymentMethod]
    public let selectedPaymentMethod: CheckoutPaymentMethod?
    public let canPlaceOrder: Bool
}

public struct DirectDeliveryCheckoutForm: Sendable {
    private let slots: [CheckoutDeliverySlot]
    private let promotions: [CheckoutPromotionOffer]
    private var address: CheckoutDeliveryAddress?
    private var selectedSlotID: String?
    private var promotionCode: String?
    private var selectedPaymentMethod: CheckoutPaymentMethod?

    public init(
        slots: [CheckoutDeliverySlot],
        promotions: [CheckoutPromotionOffer]
    ) {
        precondition(
            Set(slots.map(\.id)).count == slots.count,
            "Delivery slot identifiers must be unique"
        )
        precondition(
            Set(promotions.map(\.code)).count == promotions.count,
            "Promotion codes must be unique"
        )

        self.slots = slots
        self.promotions = promotions
    }

    public var snapshot: DeliveryCheckoutFormSnapshot {
        let availableSlots = availableSlotsForCurrentAddress()
        let selectedSlot = selectedSlot(in: availableSlots)
        let availablePaymentMethods = selectedSlot?.paymentMethods ?? []
        let canPlaceOrder = address != nil
            && selectedSlot != nil
            && selectedPaymentMethod != nil

        return DeliveryCheckoutFormSnapshot(
            address: address,
            availableSlots: availableSlots,
            selectedSlotID: selectedSlot?.id,
            promotionStatus: promotionStatus(for: selectedSlot),
            availablePaymentMethods: availablePaymentMethods,
            selectedPaymentMethod: selectedPaymentMethod,
            canPlaceOrder: canPlaceOrder
        )
    }

    public mutating func updateAddress(_ address: CheckoutDeliveryAddress) {
        self.address = address

        let availableSlots = availableSlotsForCurrentAddress()
        if selectedSlot(in: availableSlots) == nil {
            selectedSlotID = nil
        }
        discardUnavailablePaymentMethod()
    }

    @discardableResult
    public mutating func selectDeliverySlot(id: String) -> Bool {
        guard availableSlotsForCurrentAddress().contains(where: { $0.id == id }) else {
            return false
        }

        selectedSlotID = id
        discardUnavailablePaymentMethod()
        return true
    }

    public mutating func applyPromotionCode(_ code: String) {
        precondition(!code.isEmpty, "A promotion code cannot be empty")
        promotionCode = code
    }

    public mutating func clearPromotion() {
        promotionCode = nil
    }

    @discardableResult
    public mutating func selectPaymentMethod(
        _ paymentMethod: CheckoutPaymentMethod
    ) -> Bool {
        guard snapshot.availablePaymentMethods.contains(paymentMethod) else {
            return false
        }

        selectedPaymentMethod = paymentMethod
        return true
    }

    private func availableSlotsForCurrentAddress() -> [CheckoutDeliverySlot] {
        guard let address else {
            return []
        }

        return slots.filter { $0.supportedZones.contains(address.zone) }
    }

    private func selectedSlot(
        in availableSlots: [CheckoutDeliverySlot]
    ) -> CheckoutDeliverySlot? {
        availableSlots.first { $0.id == selectedSlotID }
    }

    private func promotionStatus(
        for selectedSlot: CheckoutDeliverySlot?
    ) -> CheckoutPromotionStatus {
        guard let promotionCode else {
            return .notEntered
        }
        guard let promotion = promotions.first(where: { $0.code == promotionCode }) else {
            return .unavailable(code: promotionCode, issue: .unknownCode)
        }
        guard let selectedSlot else {
            return .unavailable(
                code: promotionCode,
                issue: .deliverySlotRequired
            )
        }
        guard promotion.eligibleSlotIDs.contains(selectedSlot.id) else {
            return .unavailable(
                code: promotionCode,
                issue: .deliverySlotNotEligible
            )
        }

        return .eligible(
            code: promotionCode,
            discountCents: promotion.discountCents
        )
    }

    private mutating func discardUnavailablePaymentMethod() {
        guard let selectedPaymentMethod else {
            return
        }
        guard snapshot.availablePaymentMethods.contains(selectedPaymentMethod) else {
            self.selectedPaymentMethod = nil
            return
        }
    }
}
