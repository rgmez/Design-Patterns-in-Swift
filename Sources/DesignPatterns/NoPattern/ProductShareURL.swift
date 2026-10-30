import Foundation

public enum ProductShareSurface: String, CaseIterable, Sendable {
    case favorites
    case orderHistory = "order_history"
    case productDetails = "product_details"
}

public struct ProductShareRequest: Equatable, Sendable {
    public let productID: UUID
    public let source: ProductShareSurface?
    public let campaignID: UUID?

    public init(
        productID: UUID,
        source: ProductShareSurface? = nil,
        campaignID: UUID? = nil
    ) {
        self.productID = productID
        self.source = source
        self.campaignID = campaignID
    }
}

public enum ProductShareLinkError: Error, Equatable, Sendable {
    case invalidURL
}

public func productShareURL(
    for request: ProductShareRequest
) throws -> URL {
    var components = URLComponents()
    components.scheme = "https"
    components.host = "shop.example.com"
    components.path = "/products/\(request.productID.uuidString.lowercased())"

    var queryItems: [URLQueryItem] = []

    if let source = request.source {
        queryItems.append(
            URLQueryItem(name: "source", value: source.rawValue)
        )
    }

    if let campaignID = request.campaignID {
        queryItems.append(
            URLQueryItem(
                name: "campaign_id",
                value: campaignID.uuidString.lowercased()
            )
        )
    }

    components.queryItems = queryItems.isEmpty ? nil : queryItems

    guard let url = components.url else {
        throw ProductShareLinkError.invalidURL
    }

    return url
}
