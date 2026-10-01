import DesignPatterns
import Foundation
import Testing

@Suite("Chain of Responsibility")
struct ChainTests {
    private static let supportedHost = "shop.example.com"
    private static let productSlug = "precision-coffee-grinder"
    private static let campaignSlug = "autumn-workbench"
    private static let referralCode = "friend-8192"
    private static let orderID = "order-8192"
    private static let recoveryToken = "recovery-token-84"
    private static let storeSlug = "madrid-centro"

    private struct UnexpectedHandler: CommerceLinkHandler {
        func handle(
            _ request: CommerceLinkRequest
        ) -> CommerceLinkHandlerDecision {
            Issue.record(
                "A handler after a terminal decision must not run"
            )
            return .pass
        }
    }

    struct RouteScenario: Sendable, CustomTestStringConvertible {
        let name: String
        let path: String
        let isAuthenticated: Bool
        let expectedDestination: CommerceLinkDestination

        var testDescription: String { name }
    }

    private static let supportedRouteScenarios = [
        RouteScenario(
            name: "featured products before a generic product slug",
            path: "/products/featured",
            isAuthenticated: false,
            expectedDestination: .featuredProducts
        ),
        RouteScenario(
            name: "ordinary product after the specialized handler passes",
            path: "/products/\(productSlug)",
            isAuthenticated: false,
            expectedDestination: .product(slug: productSlug)
        ),
        RouteScenario(
            name: "referral before a generic campaign slug",
            path: "/campaigns/referral?code=\(referralCode)",
            isAuthenticated: false,
            expectedDestination: .campaignReferral(code: referralCode)
        ),
        RouteScenario(
            name: "ordinary campaign after the referral handler passes",
            path: "/campaigns/\(campaignSlug)",
            isAuthenticated: false,
            expectedDestination: .campaign(slug: campaignSlug)
        ),
        RouteScenario(
            name: "account recovery independent of session state",
            path: "/account/recovery?token=\(recoveryToken)",
            isAuthenticated: false,
            expectedDestination: .accountRecovery(token: recoveryToken)
        ),
        RouteScenario(
            name: "retail store page",
            path: "/stores/\(storeSlug)",
            isAuthenticated: false,
            expectedDestination: .store(slug: storeSlug)
        )
    ]

    private static func makeRouter() -> CommerceLinkRouter {
        .commerce(supportedHost: supportedHost)
    }

    private static func makeURL(path: String) throws -> URL {
        try #require(URL(string: "https://\(supportedHost)\(path)"))
    }

    @Suite("Ordered ownership")
    struct OrderedOwnership {
        @Test(
            "Stops at the first handler that accepts the link",
            arguments: ChainTests.supportedRouteScenarios
        )
        func routesToFirstOwner(
            _ scenario: ChainTests.RouteScenario
        ) throws {
            let result = ChainTests.makeRouter().route(
                try ChainTests.makeURL(path: scenario.path),
                isAuthenticated: scenario.isAuthenticated
            )

            #expect(result == .handled(scenario.expectedDestination))
        }

        @Test("Makes precedence an explicit composition decision")
        func exposesHandlerOrder() throws {
            let router = CommerceLinkRouter(
                supportedHost: ChainTests.supportedHost,
                handlers: [
                    ProductLinkHandler(),
                    FeaturedProductsLinkHandler()
                ]
            )

            let result = router.route(
                try ChainTests.makeURL(path: "/products/featured"),
                isAuthenticated: false
            )

            #expect(result == .handled(.product(slug: "featured")))
        }

        @Test("Does not consult handlers after a handled decision")
        func handledDecisionStopsLaterHandlers() throws {
            let router = CommerceLinkRouter(
                supportedHost: ChainTests.supportedHost,
                handlers: [
                    FeaturedProductsLinkHandler(),
                    UnexpectedHandler()
                ]
            )

            let result = router.route(
                try ChainTests.makeURL(path: "/products/featured"),
                isAuthenticated: false
            )

            #expect(result == .handled(.featuredProducts))
        }
    }

    @Suite("Terminal decisions")
    struct TerminalDecisions {
        @Test("Rejects a malformed owned route before generic fallback")
        func rejectionStopsTheChain() throws {
            let router = CommerceLinkRouter(
                supportedHost: ChainTests.supportedHost,
                handlers: [
                    ReferralCampaignLinkHandler(),
                    CampaignLinkHandler()
                ]
            )

            let result = router.route(
                try ChainTests.makeURL(path: "/campaigns/referral"),
                isAuthenticated: false
            )

            #expect(result == .unhandled)
        }

        @Test("Returns unhandled after every feature passes")
        func allHandlersPass() throws {
            let result = ChainTests.makeRouter().route(
                try ChainTests.makeURL(path: "/wishlist/saved"),
                isAuthenticated: true
            )

            #expect(result == .unhandled)
        }

        @Test("Rejects a foreign host before consulting the chain")
        func rejectsForeignHost() throws {
            let foreignURL = try #require(
                URL(string: "https://help.example.com/products/featured")
            )

            let result = ChainTests.makeRouter().route(
                foreignURL,
                isAuthenticated: true
            )

            #expect(result == .unhandled)
        }

        @Test("Rejects an insecure scheme before consulting the chain")
        func rejectsInsecureScheme() throws {
            let insecureURL = try #require(
                URL(string: "http://shop.example.com/products/featured")
            )
            let router = CommerceLinkRouter(
                supportedHost: ChainTests.supportedHost,
                handlers: [UnexpectedHandler()]
            )

            let result = router.route(
                insecureURL,
                isAuthenticated: true
            )

            #expect(result == .unhandled)
        }
    }

    @Suite("Order authentication")
    struct OrderAuthentication {
        @Test("Opens an order only for an authenticated customer")
        func opensAuthenticatedOrder() throws {
            let result = ChainTests.makeRouter().route(
                try ChainTests.makeURL(
                    path: "/orders/\(ChainTests.orderID)"
                ),
                isAuthenticated: true
            )

            #expect(
                result == .handled(.order(id: ChainTests.orderID))
            )
        }

        @Test("Retains the order while an unauthenticated customer signs in")
        func retainsOrderThroughSignIn() throws {
            let result = ChainTests.makeRouter().route(
                try ChainTests.makeURL(
                    path: "/orders/\(ChainTests.orderID)"
                ),
                isAuthenticated: false
            )

            #expect(
                result == .handled(
                    .signIn(resume: .order(id: ChainTests.orderID))
                )
            )
        }
    }
}
