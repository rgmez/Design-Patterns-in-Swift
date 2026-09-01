import DesignPatterns
import Testing

@Suite("Abstract Factory")
struct AbstractFactoryTests {
    struct FamilyScenario: Sendable, CustomTestStringConvertible {
        let name: String
        let factory: any RegionalCommerceFactory
        let taxCalculator: RegionalTaxCalculator
        let paymentAuthorizer: RegionalPaymentAuthorizer
        let receiptFormatter: RegionalReceiptFormatter
        let taxInMinorUnits: Int
        let paymentReference: String
        let receipt: String

        var testDescription: String { name }
    }

    private struct MixedCommerceFactory: RegionalCommerceFactory {
        let region = CommerceRegion.europeanUnion

        func makeTaxCalculator() -> RegionalTaxCalculator { .euVAT }

        func makePaymentAuthorizer() -> RegionalPaymentAuthorizer { .latamPix }

        func makeReceiptFormatter() -> RegionalReceiptFormatter { .euStandard }
    }

    private static let order = RegionalCheckoutOrder(
        orderID: "order-42",
        subtotalInMinorUnits: 1_000,
        currency: "EUR"
    )
    private static let familyScenarios = [
        FamilyScenario(
            name: "EU family",
            factory: EuropeanUnionCommerceFactory(),
            taxCalculator: .euVAT,
            paymentAuthorizer: .euCard,
            receiptFormatter: .euStandard,
            taxInMinorUnits: 200,
            paymentReference: "euCard-order-42",
            receipt: "EU receipt | order order-42 | subtotal 1000 | tax 200 | total 1200"
        ),
        FamilyScenario(
            name: "LATAM family",
            factory: LatamCommerceFactory(),
            taxCalculator: .latamIVA,
            paymentAuthorizer: .latamPix,
            receiptFormatter: .latamFiscal,
            taxInMinorUnits: 180,
            paymentReference: "latamPix-order-42",
            receipt: "LATAM fiscal receipt | order order-42 | subtotal 1000 | tax 180 | total 1180"
        )
    ]

    @Suite("Complete families")
    struct CompleteFamilies {
        @Test(
            "Creates compatible products through one family boundary",
            arguments: AbstractFactoryTests.familyScenarios
        )
        func createsCompatibleProducts(_ scenario: FamilyScenario) {
            let services = makeRegionalServices(using: scenario.factory)

            #expect(services.region == scenario.factory.region)
            #expect(services.taxCalculator == scenario.taxCalculator)
            #expect(services.paymentAuthorizer == scenario.paymentAuthorizer)
            #expect(services.receiptFormatter == scenario.receiptFormatter)
            #expect(services.isCoherent)
        }

        @Test(
            "Selects the matching concrete family at the composition root",
            arguments: AbstractFactoryTests.familyScenarios
        )
        func selectsConcreteFamily(_ scenario: FamilyScenario) {
            #expect(
                makeRegionalServices(for: scenario.factory.region)
                    == makeRegionalServices(using: scenario.factory)
            )
        }
    }

    @Suite("Checkout")
    struct Checkout {
        @Test(
            "Uses each complete family without changing the checkout flow",
            arguments: AbstractFactoryTests.familyScenarios
        )
        func usesCompleteFamily(_ scenario: FamilyScenario) throws {
            let result = try placeRegionalOrder(
                AbstractFactoryTests.order,
                using: makeRegionalServices(using: scenario.factory)
            )

            #expect(result.region == scenario.factory.region)
            #expect(result.currency == AbstractFactoryTests.order.currency)
            #expect(result.taxInMinorUnits == scenario.taxInMinorUnits)
            #expect(result.totalInMinorUnits == 1_000 + scenario.taxInMinorUnits)
            #expect(result.paymentReference == scenario.paymentReference)
            #expect(result.receipt == scenario.receipt)
        }

        @Test("Rejects a custom factory that breaks family compatibility")
        func rejectsBrokenFactoryContract() {
            let services = makeRegionalServices(using: MixedCommerceFactory())

            #expect(throws: RegionalCheckoutError.mixedServiceFamily(expected: .europeanUnion)) {
                try placeRegionalOrder(AbstractFactoryTests.order, using: services)
            }
        }

        @Test("Rejects an order with no payable subtotal")
        func rejectsInvalidSubtotal() {
            let invalidOrder = RegionalCheckoutOrder(
                orderID: AbstractFactoryTests.order.orderID,
                subtotalInMinorUnits: 0,
                currency: AbstractFactoryTests.order.currency
            )

            #expect(throws: RegionalCheckoutError.invalidSubtotal) {
                try placeRegionalOrder(
                    invalidOrder,
                    using: makeRegionalServices(for: .europeanUnion)
                )
            }
        }
    }

    @Suite("Value semantics")
    struct ValueSemantics {
        @Test("Leaves the order unchanged while calculating checkout")
        func preservesOrderValue() throws {
            let sourceOrder = AbstractFactoryTests.order

            _ = try placeRegionalOrder(
                sourceOrder,
                using: makeRegionalServices(for: .europeanUnion)
            )

            #expect(sourceOrder == AbstractFactoryTests.order)
        }
    }
}
