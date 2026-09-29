import DesignPatterns
import Foundation
import Testing

@Suite("Chain of Responsibility pressure")
struct ChainPressureTests {
    private static let supportedHost = "shop.example.com"
    private static let productSlug = "precision-coffee-grinder"
    private static let campaignSlug = "autumn-workbench"
    private static let referralCode = "friend-2048"
    private static let storeSlug = "madrid-centro"
    private static let orderID = "order-4096"

    struct RouteScenario: Sendable, CustomTestStringConvertible {
        let name: String
        let path: String
        let expectedDestination: CommerceLinkDestination

        var testDescription: String { name }
    }

    private static let specializedRouteScenarios = [
        RouteScenario(
            name: "featured products before generic product slugs",
            path: "/products/featured",
            expectedDestination: .featuredProducts
        ),
        RouteScenario(
            name: "referral campaign before generic campaign slugs",
            path: "/campaigns/referral?code=\(referralCode)",
            expectedDestination: .campaignReferral(code: referralCode)
        )
    ]

    private static let genericRouteScenarios = [
        RouteScenario(
            name: "ordinary product slug",
            path: "/products/\(productSlug)",
            expectedDestination: .product(slug: productSlug)
        ),
        RouteScenario(
            name: "ordinary campaign slug",
            path: "/campaigns/\(campaignSlug)",
            expectedDestination: .campaign(slug: campaignSlug)
        )
    ]

    private static func makeRouter() -> DirectExpandedCommerceLinkRouter {
        DirectExpandedCommerceLinkRouter(supportedHost: supportedHost)
    }

    private static func makeURL(path: String) throws -> URL {
        try #require(URL(string: "https://\(supportedHost)\(path)"))
    }

    @Suite("Specific route precedence")
    struct SpecificRoutePrecedence {
        @Test(
            "Routes specialized links before their generic siblings",
            arguments: ChainPressureTests.specializedRouteScenarios
        )
        func routesSpecializedLink(
            _ scenario: ChainPressureTests.RouteScenario
        ) throws {
            let result = ChainPressureTests.makeRouter().route(
                try ChainPressureTests.makeURL(path: scenario.path),
                isAuthenticated: false
            )

            #expect(result == .handled(scenario.expectedDestination))
        }

        @Test("Does not reinterpret an invalid referral as a campaign")
        func rejectsReferralWithoutCode() throws {
            let result = ChainPressureTests.makeRouter().route(
                try ChainPressureTests.makeURL(path: "/campaigns/referral"),
                isAuthenticated: false
            )

            #expect(result == .unhandled)
        }
    }

    @Suite("Generic sibling routes")
    struct GenericSiblingRoutes {
        @Test(
            "Keeps ordinary product and campaign routes available",
            arguments: ChainPressureTests.genericRouteScenarios
        )
        func routesGenericLink(
            _ scenario: ChainPressureTests.RouteScenario
        ) throws {
            let result = ChainPressureTests.makeRouter().route(
                try ChainPressureTests.makeURL(path: scenario.path),
                isAuthenticated: false
            )

            #expect(result == .handled(scenario.expectedDestination))
        }
    }

    @Suite("Independent feature growth")
    struct IndependentFeatureGrowth {
        @Test("Adds store routing at the same central decision point")
        func routesStore() throws {
            let result = ChainPressureTests.makeRouter().route(
                try ChainPressureTests.makeURL(
                    path: "/stores/\(ChainPressureTests.storeSlug)"
                ),
                isAuthenticated: false
            )

            #expect(
                result == .handled(
                    .store(slug: ChainPressureTests.storeSlug)
                )
            )
        }

        @Test("Preserves the order authentication guard")
        func retainsOrderWhileSigningIn() throws {
            let result = ChainPressureTests.makeRouter().route(
                try ChainPressureTests.makeURL(
                    path: "/orders/\(ChainPressureTests.orderID)"
                ),
                isAuthenticated: false
            )

            #expect(
                result == .handled(
                    .signIn(
                        resume: .order(id: ChainPressureTests.orderID)
                    )
                )
            )
        }
    }
}
