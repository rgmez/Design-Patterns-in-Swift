import DesignPatterns
import Testing

@Suite("Abstract Factory problem")
struct AbstractFactoryProblemTests {
    struct FamilyScenario: Sendable, CustomTestStringConvertible {
        let name: String
        let region: CommerceRegion
        let taxCalculator: RegionalTaxCalculator
        let paymentAuthorizer: RegionalPaymentAuthorizer
        let receiptFormatter: RegionalReceiptFormatter
        let taxInMinorUnits: Int
        let paymentReference: String
        let receipt: String

        var testDescription: String { name }
    }

    private static let order = RegionalCheckoutOrder(
        orderID: "order-42",
        subtotalInMinorUnits: 1_000,
        currency: "EUR"
    )
    private static let familyScenarios = [
        FamilyScenario(
            name: "EU family",
            region: .europeanUnion,
            taxCalculator: .euVAT,
            paymentAuthorizer: .euCard,
            receiptFormatter: .euStandard,
            taxInMinorUnits: 200,
            paymentReference: "euCard-order-42",
            receipt: "EU receipt | order order-42 | subtotal 1000 | tax 200 | total 1200"
        ),
        FamilyScenario(
            name: "LATAM family",
            region: .latam,
            taxCalculator: .latamIVA,
            paymentAuthorizer: .latamPix,
            receiptFormatter: .latamFiscal,
            taxInMinorUnits: 180,
            paymentReference: "latamPix-order-42",
            receipt: "LATAM fiscal receipt | order order-42 | subtotal 1000 | tax 180 | total 1180"
        )
    ]

    @Suite("Regional families")
    struct RegionalFamilies {
        @Test(
            "Builds one coherent service family per region",
            arguments: AbstractFactoryProblemTests.familyScenarios
        )
        func buildsCoherentFamily(_ scenario: FamilyScenario) throws {
            let services = makeRegionalServices(for: scenario.region)

            #expect(services.region == scenario.region)
            #expect(services.taxCalculator == scenario.taxCalculator)
            #expect(services.paymentAuthorizer == scenario.paymentAuthorizer)
            #expect(services.receiptFormatter == scenario.receiptFormatter)
            #expect(services.isCoherent)

            let result = try placeRegionalOrder(
                AbstractFactoryProblemTests.order,
                using: services
            )

            #expect(result.region == scenario.region)
            #expect(result.currency == AbstractFactoryProblemTests.order.currency)
            #expect(result.taxInMinorUnits == scenario.taxInMinorUnits)
            #expect(result.totalInMinorUnits == 1_000 + scenario.taxInMinorUnits)
            #expect(result.paymentReference == scenario.paymentReference)
            #expect(result.receipt == scenario.receipt)
        }
    }

    @Suite("Composition boundary")
    struct CompositionBoundary {
        @Test("Rejects a cross-region service combination")
        func rejectsMixedFamily() {
            let mixedServices = RegionalServices(
                region: .europeanUnion,
                taxCalculator: .euVAT,
                paymentAuthorizer: .latamPix,
                receiptFormatter: .euStandard
            )

            #expect(!mixedServices.isCoherent)
            #expect(throws: RegionalCheckoutError.mixedServiceFamily(expected: .europeanUnion)) {
                try placeRegionalOrder(
                    AbstractFactoryProblemTests.order,
                    using: mixedServices
                )
            }
        }

        @Test("Rejects an order with no payable subtotal")
        func rejectsInvalidSubtotal() {
            let invalidOrder = RegionalCheckoutOrder(
                orderID: "order-42",
                subtotalInMinorUnits: 0,
                currency: "EUR"
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
            let sourceOrder = AbstractFactoryProblemTests.order

            _ = try placeRegionalOrder(
                sourceOrder,
                using: makeRegionalServices(for: .europeanUnion)
            )

            #expect(sourceOrder == AbstractFactoryProblemTests.order)
        }
    }
}
