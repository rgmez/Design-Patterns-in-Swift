import Foundation

public struct CommerceLinkRequest: Sendable {
    public let url: URL
    public let pathSegments: [String]
    public let isAuthenticated: Bool

    public func queryValue(named name: String) -> String? {
        let queryItems = URLComponents(
            url: url,
            resolvingAgainstBaseURL: false
        )?.queryItems
        return queryItems?
            .first(where: { $0.name == name })?
            .value
            .flatMap { $0.isEmpty ? nil : $0 }
    }
}

public enum CommerceLinkHandlerDecision: Equatable, Sendable {
    case pass
    case handled(CommerceLinkDestination)
    case reject
}

public protocol CommerceLinkHandler: Sendable {
    func handle(
        _ request: CommerceLinkRequest
    ) -> CommerceLinkHandlerDecision
}

public struct CommerceLinkRouter: Sendable {
    public let supportedHost: String
    public let handlers: [any CommerceLinkHandler]

    public init(
        supportedHost: String,
        handlers: [any CommerceLinkHandler]
    ) {
        self.supportedHost = supportedHost.lowercased()
        self.handlers = handlers
    }

    public static func commerce(
        supportedHost: String
    ) -> CommerceLinkRouter {
        CommerceLinkRouter(
            supportedHost: supportedHost,
            handlers: [
                FeaturedProductsLinkHandler(),
                ProductLinkHandler(),
                OrderLinkHandler(),
                ReferralCampaignLinkHandler(),
                CampaignLinkHandler(),
                AccountRecoveryLinkHandler(),
                StoreLinkHandler()
            ]
        )
    }

    public func route(
        _ url: URL,
        isAuthenticated: Bool
    ) -> CommerceLinkRoutingResult {
        guard url.scheme?.lowercased() == "https",
              url.host?.lowercased() == supportedHost else {
            return .unhandled
        }

        let pathSegments = url.pathComponents.filter { $0 != "/" }
        guard pathSegments.count == 2 else {
            return .unhandled
        }

        let request = CommerceLinkRequest(
            url: url,
            pathSegments: pathSegments,
            isAuthenticated: isAuthenticated
        )

        for handler in handlers {
            switch handler.handle(request) {
            case .pass:
                continue
            case let .handled(destination):
                return .handled(destination)
            case .reject:
                return .unhandled
            }
        }

        return .unhandled
    }
}

public struct FeaturedProductsLinkHandler: CommerceLinkHandler {
    public init() {}

    public func handle(
        _ request: CommerceLinkRequest
    ) -> CommerceLinkHandlerDecision {
        guard request.pathSegments == ["products", "featured"] else {
            return .pass
        }
        return .handled(.featuredProducts)
    }
}

public struct ProductLinkHandler: CommerceLinkHandler {
    public init() {}

    public func handle(
        _ request: CommerceLinkRequest
    ) -> CommerceLinkHandlerDecision {
        guard request.pathSegments[0] == "products" else {
            return .pass
        }
        return .handled(.product(slug: request.pathSegments[1]))
    }
}

public struct OrderLinkHandler: CommerceLinkHandler {
    public init() {}

    public func handle(
        _ request: CommerceLinkRequest
    ) -> CommerceLinkHandlerDecision {
        guard request.pathSegments[0] == "orders" else {
            return .pass
        }

        let id = request.pathSegments[1]
        guard request.isAuthenticated else {
            return .handled(.signIn(resume: .order(id: id)))
        }
        return .handled(.order(id: id))
    }
}

public struct ReferralCampaignLinkHandler: CommerceLinkHandler {
    public init() {}

    public func handle(
        _ request: CommerceLinkRequest
    ) -> CommerceLinkHandlerDecision {
        guard request.pathSegments == ["campaigns", "referral"] else {
            return .pass
        }
        guard let code = request.queryValue(named: "code") else {
            return .reject
        }
        return .handled(.campaignReferral(code: code))
    }
}

public struct CampaignLinkHandler: CommerceLinkHandler {
    public init() {}

    public func handle(
        _ request: CommerceLinkRequest
    ) -> CommerceLinkHandlerDecision {
        guard request.pathSegments[0] == "campaigns" else {
            return .pass
        }
        return .handled(.campaign(slug: request.pathSegments[1]))
    }
}

public struct AccountRecoveryLinkHandler: CommerceLinkHandler {
    public init() {}

    public func handle(
        _ request: CommerceLinkRequest
    ) -> CommerceLinkHandlerDecision {
        guard request.pathSegments == ["account", "recovery"] else {
            return .pass
        }
        guard let token = request.queryValue(named: "token") else {
            return .reject
        }
        return .handled(.accountRecovery(token: token))
    }
}

public struct StoreLinkHandler: CommerceLinkHandler {
    public init() {}

    public func handle(
        _ request: CommerceLinkRequest
    ) -> CommerceLinkHandlerDecision {
        guard request.pathSegments[0] == "stores" else {
            return .pass
        }
        return .handled(.store(slug: request.pathSegments[1]))
    }
}
