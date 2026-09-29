import Foundation

public struct DirectExpandedCommerceLinkRouter: Sendable {
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

        return routeSupported(
            segments: segments,
            url: url,
            isAuthenticated: isAuthenticated
        )
    }

    private func routeSupported(
        segments: [String],
        url: URL,
        isAuthenticated: Bool
    ) -> CommerceLinkRoutingResult {
        switch (segments[0], segments[1]) {
        case ("products", "featured"):
            return .handled(.featuredProducts)

        case ("products", let slug):
            return .handled(.product(slug: slug))

        case ("orders", let id) where isAuthenticated:
            return .handled(.order(id: id))

        case ("orders", let id):
            return .handled(.signIn(resume: .order(id: id)))

        case ("campaigns", "referral"):
            return queryValue(named: "code", in: url)
                .map { .handled(.campaignReferral(code: $0)) }
                ?? .unhandled

        case ("campaigns", let slug):
            return .handled(.campaign(slug: slug))

        case ("account", "recovery"):
            return queryValue(named: "token", in: url)
                .map { .handled(.accountRecovery(token: $0)) }
                ?? .unhandled

        case ("stores", let slug):
            return .handled(.store(slug: slug))

        default:
            return .unhandled
        }
    }

    private func queryValue(named name: String, in url: URL) -> String? {
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
