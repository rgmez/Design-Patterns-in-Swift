public enum CommerceRegion: String, CaseIterable, Equatable, Sendable {
    case europeanUnion = "eu"
    case latam
}

public enum RegionalTaxCalculator: String, Equatable, Sendable {
    case euVAT
    case latamIVA

    public var region: CommerceRegion {
        switch self {
        case .euVAT:
            .europeanUnion
        case .latamIVA:
            .latam
        }
    }

    public func taxInMinorUnits(for subtotalInMinorUnits: Int) -> Int {
        switch self {
        case .euVAT:
            subtotalInMinorUnits * 20 / 100
        case .latamIVA:
            subtotalInMinorUnits * 18 / 100
        }
    }
}

public enum RegionalPaymentAuthorizer: String, Equatable, Sendable {
    case euCard
    case latamPix

    public var region: CommerceRegion {
        switch self {
        case .euCard:
            .europeanUnion
        case .latamPix:
            .latam
        }
    }

    public func authorizationReference(for orderID: String) -> String {
        "\(rawValue)-\(orderID)"
    }
}

public enum RegionalReceiptFormatter: String, Equatable, Sendable {
    case euStandard
    case latamFiscal

    public var region: CommerceRegion {
        switch self {
        case .euStandard:
            .europeanUnion
        case .latamFiscal:
            .latam
        }
    }

    public func receipt(
        orderID: String,
        subtotalInMinorUnits: Int,
        taxInMinorUnits: Int,
        totalInMinorUnits: Int
    ) -> String {
        let label = self == .euStandard ? "EU receipt" : "LATAM fiscal receipt"
        return [
            label,
            "order \(orderID)",
            "subtotal \(subtotalInMinorUnits)",
            "tax \(taxInMinorUnits)",
            "total \(totalInMinorUnits)"
        ].joined(separator: " | ")
    }
}

public struct RegionalServices: Equatable, Sendable {
    public let region: CommerceRegion
    public let taxCalculator: RegionalTaxCalculator
    public let paymentAuthorizer: RegionalPaymentAuthorizer
    public let receiptFormatter: RegionalReceiptFormatter

    public init(
        region: CommerceRegion,
        taxCalculator: RegionalTaxCalculator,
        paymentAuthorizer: RegionalPaymentAuthorizer,
        receiptFormatter: RegionalReceiptFormatter
    ) {
        self.region = region
        self.taxCalculator = taxCalculator
        self.paymentAuthorizer = paymentAuthorizer
        self.receiptFormatter = receiptFormatter
    }

    public var isCoherent: Bool {
        taxCalculator.region == region
            && paymentAuthorizer.region == region
            && receiptFormatter.region == region
    }
}

public struct RegionalCheckoutOrder: Equatable, Sendable {
    public let orderID: String
    public let subtotalInMinorUnits: Int
    public let currency: String

    public init(orderID: String, subtotalInMinorUnits: Int, currency: String) {
        self.orderID = orderID
        self.subtotalInMinorUnits = subtotalInMinorUnits
        self.currency = currency
    }
}

public struct RegionalCheckoutResult: Equatable, Sendable {
    public let region: CommerceRegion
    public let currency: String
    public let taxInMinorUnits: Int
    public let totalInMinorUnits: Int
    public let paymentReference: String
    public let receipt: String

    public init(
        region: CommerceRegion,
        currency: String,
        taxInMinorUnits: Int,
        totalInMinorUnits: Int,
        paymentReference: String,
        receipt: String
    ) {
        self.region = region
        self.currency = currency
        self.taxInMinorUnits = taxInMinorUnits
        self.totalInMinorUnits = totalInMinorUnits
        self.paymentReference = paymentReference
        self.receipt = receipt
    }
}

public enum RegionalCheckoutError: Error, Equatable, Sendable {
    case invalidSubtotal
    case mixedServiceFamily(expected: CommerceRegion)
}

/// The composition root keeps the family selection explicit before Abstract Factory.
public func makeRegionalServices(for region: CommerceRegion) -> RegionalServices {
    switch region {
    case .europeanUnion:
        RegionalServices(
            region: .europeanUnion,
            taxCalculator: .euVAT,
            paymentAuthorizer: .euCard,
            receiptFormatter: .euStandard
        )
    case .latam:
        RegionalServices(
            region: .latam,
            taxCalculator: .latamIVA,
            paymentAuthorizer: .latamPix,
            receiptFormatter: .latamFiscal
        )
    }
}

public func placeRegionalOrder(
    _ order: RegionalCheckoutOrder,
    using services: RegionalServices
) throws -> RegionalCheckoutResult {
    guard order.subtotalInMinorUnits > 0 else {
        throw RegionalCheckoutError.invalidSubtotal
    }
    guard services.isCoherent else {
        throw RegionalCheckoutError.mixedServiceFamily(expected: services.region)
    }

    let tax = services.taxCalculator.taxInMinorUnits(
        for: order.subtotalInMinorUnits
    )
    let total = order.subtotalInMinorUnits + tax
    return RegionalCheckoutResult(
        region: services.region,
        currency: order.currency,
        taxInMinorUnits: tax,
        totalInMinorUnits: total,
        paymentReference: services.paymentAuthorizer.authorizationReference(
            for: order.orderID
        ),
        receipt: services.receiptFormatter.receipt(
            orderID: order.orderID,
            subtotalInMinorUnits: order.subtotalInMinorUnits,
            taxInMinorUnits: tax,
            totalInMinorUnits: total
        )
    )
}
