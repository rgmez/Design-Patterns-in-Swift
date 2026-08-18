import DesignPatterns
import Testing

@Suite("Package boundary")
struct PackageBoundaryTests {
    @Suite("Canonical module")
    struct CanonicalModule {
        @Test("Can be imported by the test target")
        func canBeImported() {
            // Reaching this test verifies the module boundary without adding a
            // production sentinel whose only purpose would be satisfying a test.
        }
    }
}
