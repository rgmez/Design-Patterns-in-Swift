import DesignPatterns
import Foundation
import Testing

@Suite("Chain of Responsibility problem")
struct ChainProblemTests {
    private static let supportedHost = "shop.example.com"
    private static let productSlug = "precision-coffee-grinder"
    private static let orderID = "order-2048"
    private static let campaignSlug = "autumn-workbench"
    private static let recoveryToken = "recovery-token-42"

    struct PublicRouteScenario: Sendable, CustomTestStringConvertible {
        let name: String
        let path: String
        let expectedDestination: CommerceLinkDestination

        var testDescription: String { name }
    }

    struct UnsupportedLinkScenario: Sendable, CustomTestStringConvertible {
        let name: String
        let value: String

        var testDescription: String { name }
    }

    private static let publicRouteScenarios = [
        PublicRouteScenario(
            name: "product details",
            path: "/products/\(productSlug)",
            expectedDestination: .product(slug: productSlug)
        ),
        PublicRouteScenario(
            name: "campaign landing page",
            path: "/campaigns/\(campaignSlug)",
            expectedDestination: .campaign(slug: campaignSlug)
        )
    ]

    private static let unsupportedLinkScenarios = [
        UnsupportedLinkScenario(
            name: "insecure scheme",
            value: "http://\(supportedHost)/products/\(productSlug)"
        ),
        UnsupportedLinkScenario(
            name: "different host",
            value: "https://help.example.com/products/\(productSlug)"
        ),
        UnsupportedLinkScenario(
            name: "unknown feature path",
            value: "https://\(supportedHost)/stores/madrid"
        ),
        UnsupportedLinkScenario(
            name: "missing product identifier",
            value: "https://\(supportedHost)/products"
        ),
        UnsupportedLinkScenario(
            name: "extra product segment",
            value: "https://\(supportedHost)/products/\(productSlug)/reviews"
        ),
        UnsupportedLinkScenario(
            name: "missing recovery token",
            value: "https://\(supportedHost)/account/recovery"
        )
    ]

    private static func makeRouter() -> DirectCommerceLinkRouter {
        DirectCommerceLinkRouter(supportedHost: supportedHost)
    }

    private static func makeURL(_ value: String) throws -> URL {
        try #require(URL(string: value))
    }

    private static func makeURL(path: String) throws -> URL {
        try makeURL("https://\(supportedHost)\(path)")
    }

    @Suite("Public feature routes")
    struct PublicFeatureRoutes {
        @Test(
            "Routes public links without authentication",
            arguments: ChainProblemTests.publicRouteScenarios
        )
        func routesPublicLink(
            _ scenario: ChainProblemTests.PublicRouteScenario
        ) throws {
            let result = ChainProblemTests.makeRouter().route(
                try ChainProblemTests.makeURL(path: scenario.path),
                isAuthenticated: false
            )

            #expect(result == .handled(scenario.expectedDestination))
        }
    }

    @Suite("Order authentication")
    struct OrderAuthentication {
        @Test("Opens an order for an authenticated customer")
        func opensOrder() throws {
            let result = ChainProblemTests.makeRouter().route(
                try ChainProblemTests.makeURL(
                    path: "/orders/\(ChainProblemTests.orderID)"
                ),
                isAuthenticated: true
            )

            #expect(
                result == .handled(
                    .order(id: ChainProblemTests.orderID)
                )
            )
        }

        @Test("Preserves the order destination while signing in")
        func requestsSignIn() throws {
            let result = ChainProblemTests.makeRouter().route(
                try ChainProblemTests.makeURL(
                    path: "/orders/\(ChainProblemTests.orderID)"
                ),
                isAuthenticated: false
            )

            #expect(
                result == .handled(
                    .signIn(
                        resume: .order(id: ChainProblemTests.orderID)
                    )
                )
            )
        }
    }

    @Suite("Account recovery")
    struct AccountRecovery {
        @Test(
            "Routes recovery independently of the current session",
            arguments: [false, true]
        )
        func routesRecovery(isAuthenticated: Bool) throws {
            let result = ChainProblemTests.makeRouter().route(
                try ChainProblemTests.makeURL(
                    path: "/account/recovery?token=\(ChainProblemTests.recoveryToken)"
                ),
                isAuthenticated: isAuthenticated
            )

            #expect(
                result == .handled(
                    .accountRecovery(
                        token: ChainProblemTests.recoveryToken
                    )
                )
            )
        }
    }

    @Suite("Unhandled links")
    struct UnhandledLinks {
        @Test(
            "Passes unsupported links onward",
            arguments: ChainProblemTests.unsupportedLinkScenarios
        )
        func passesUnsupportedLink(
            _ scenario: ChainProblemTests.UnsupportedLinkScenario
        ) throws {
            let result = ChainProblemTests.makeRouter().route(
                try ChainProblemTests.makeURL(scenario.value),
                isAuthenticated: true
            )

            #expect(result == .unhandled)
        }
    }
}
