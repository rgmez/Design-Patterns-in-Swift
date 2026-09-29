import Foundation

public enum AuthenticatedCommerceLink: Equatable, Sendable {
    case order(id: String)
}

public enum CommerceLinkDestination: Equatable, Sendable {
    case product(slug: String)
    case featuredProducts
    case order(id: String)
    case campaign(slug: String)
    case campaignReferral(code: String)
    case store(slug: String)
    case accountRecovery(token: String)
    case signIn(resume: AuthenticatedCommerceLink)
}

public enum CommerceLinkRoutingResult: Equatable, Sendable {
    case handled(CommerceLinkDestination)
    case unhandled
}

public struct DirectCommerceLinkRouter: Sendable {
    public let supportedHost: String

    public init(supportedHost: String) {
        self.supportedHost = supportedHost.lowercased()
    }

    public func route(
        _ url: URL,
        isAuthenticated: Bool
    ) -> CommerceLinkRoutingResult {
        guard url.scheme?.lowercased() == "https",
              url.host?.lowercased() == supportedHost else {
            return .unhandled
        }

        let segments = url.pathComponents.filter { $0 != "/" }
        guard segments.count == 2 else {
            return .unhandled
        }

        let route = segments[0]
        let value = segments[1]

        switch route {
        case "products":
            return .handled(.product(slug: value))

        case "orders" where isAuthenticated:
            return .handled(.order(id: value))

        case "orders":
            return .handled(.signIn(resume: .order(id: value)))

        case "campaigns":
            return .handled(.campaign(slug: value))

        case "account" where value == "recovery":
            guard let token = recoveryToken(in: url) else {
                return .unhandled
            }
            return .handled(.accountRecovery(token: token))

        default:
            return .unhandled
        }
    }

    private func recoveryToken(in url: URL) -> String? {
        let queryItems = URLComponents(
            url: url,
            resolvingAgainstBaseURL: false
        )?.queryItems
        return queryItems?
            .first(where: { $0.name == "token" })?
            .value
            .flatMap { $0.isEmpty ? nil : $0 }
    }
}
