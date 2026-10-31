import DesignPatterns
import Foundation
import Testing

@Suite("No-pattern problem")
struct NoPatternProblemTests {
    private static let productID = UUID()
    private static let campaignID = UUID()
    private static let canonicalPrefix = "https://shop.example.com/products/"
    private static let canonicalProductPath =
        "/products/\(productID.uuidString.lowercased())"
    private static let stableAttributionQuery =
        "source=product_details&campaign_id="
        + campaignID.uuidString.lowercased()

    @Suite("Canonical product link")
    struct CanonicalProductLink {
        @Test("Builds the organic product URL from one immutable request")
        func buildsOrganicLink() throws {
            let request = ProductShareRequest(
                productID: NoPatternProblemTests.productID
            )

            let url = try productShareURL(for: request)

            #expect(
                url.absoluteString
                    == NoPatternProblemTests.canonicalPrefix
                    + NoPatternProblemTests.productID.uuidString.lowercased()
            )
            #expect(url.scheme == "https")
            #expect(url.host == "shop.example.com")
            #expect(url.query == nil)
        }

        @Test(
            "Maps every supported share surface",
            arguments: ProductShareSurface.allCases
        )
        func mapsSource(_ source: ProductShareSurface) throws {
            let request = ProductShareRequest(
                productID: NoPatternProblemTests.productID,
                source: source
            )

            let url = try productShareURL(for: request)

            #expect(url.query == "source=\(source.rawValue)")
        }
    }

    @Suite("Optional attribution")
    struct OptionalAttribution {
        @Test("Adds source before campaign when both are present")
        func addsStableAttribution() throws {
            let request = ProductShareRequest(
                productID: NoPatternProblemTests.productID,
                source: .productDetails,
                campaignID: NoPatternProblemTests.campaignID
            )

            let url = try productShareURL(for: request)

            #expect(url.query == NoPatternProblemTests.stableAttributionQuery)
        }

        @Test("Does not retain options from a previous call")
        func keepsCallsIndependent() throws {
            let attributedRequest = ProductShareRequest(
                productID: NoPatternProblemTests.productID,
                destinationLocale: .portugueseBrazil,
                source: .favorites,
                campaignID: NoPatternProblemTests.campaignID
            )
            let organicRequest = ProductShareRequest(
                productID: NoPatternProblemTests.productID
            )

            _ = try productShareURL(for: attributedRequest)
            let organicURL = try productShareURL(for: organicRequest)

            #expect(organicURL.query == nil)
            #expect(organicURL.path == NoPatternProblemTests.canonicalProductPath)
        }
    }

    @Suite("Destination routing")
    struct DestinationRouting {
        @Test(
            "Places every supported locale before the product path",
            arguments: ProductShareLocale.allCases
        )
        func addsLocalizedPath(_ locale: ProductShareLocale) throws {
            let request = ProductShareRequest(
                productID: NoPatternProblemTests.productID,
                destinationLocale: locale
            )

            let url = try productShareURL(for: request)

            #expect(
                url.path
                    == "/\(locale.rawValue)/products/"
                    + NoPatternProblemTests.productID.uuidString.lowercased()
            )
            #expect(url.query == nil)
        }

        @Test("Keeps localized routing independent from attribution")
        func combinesLocaleAndAttribution() throws {
            let request = ProductShareRequest(
                productID: NoPatternProblemTests.productID,
                destinationLocale: .spanishMexico,
                source: .productDetails,
                campaignID: NoPatternProblemTests.campaignID
            )

            let url = try productShareURL(for: request)

            #expect(
                url.path
                    == "/es-mx"
                    + NoPatternProblemTests.canonicalProductPath
            )
            #expect(url.query == NoPatternProblemTests.stableAttributionQuery)
        }
    }
}
