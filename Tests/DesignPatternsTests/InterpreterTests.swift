import DesignPatterns
import Testing

@Suite("Interpreter")
struct InterpreterTests {
    private static let currentAgentID = "agent-robin"
    private static let currentAgentOpenTicket = SupportTicket(
        id: "ticket-refund-1042",
        status: .open,
        assigneeID: currentAgentID
    )
    private static let currentAgentWaitingTicket = SupportTicket(
        id: "ticket-delivery-1043",
        status: .waiting,
        assigneeID: currentAgentID
    )
    private static let colleagueOpenTicket = SupportTicket(
        id: "ticket-address-1044",
        status: .open,
        assigneeID: "agent-sam"
    )
    private static let unassignedClosedTicket = SupportTicket(
        id: "ticket-payment-1045",
        status: .closed,
        assigneeID: nil
    )
    private static let tickets = [
        currentAgentOpenTicket,
        currentAgentWaitingTicket,
        colleagueOpenTicket,
        unassignedClosedTicket
    ]
    private static let parser = SupportTicketQueryParser()
    private static let filter = InterpretedSupportTicketFilter(
        currentAgentID: currentAgentID
    )

    @Suite("Parsing")
    struct Parsing {
        @Test("Builds explicit terms for local OR and query-wide AND")
        func buildsBoundedExpression() throws {
            let query = try InterpreterTests.parser.parse(
                "status:(open|waiting) assignee:me"
            )

            #expect(
                query.expressions == [
                    .status([.open, .waiting]),
                    .assignee(.currentAgent)
                ]
            )
        }

        @Test("Keeps a blank query as a valid conjunction with no terms")
        func buildsEmptyConjunction() throws {
            let query = try InterpreterTests.parser.parse("  \n ")

            #expect(query.expressions.isEmpty)
        }
    }

    @Suite("Interpretation")
    struct Interpretation {
        @Test("Combines grouped status alternatives with an assignee term")
        func interpretsLocalOrAndOuterAnd() throws {
            let matches = try InterpreterTests.filter.tickets(
                matching: "status:(open|waiting) assignee:me",
                in: InterpreterTests.tickets
            )

            #expect(
                matches == [
                    InterpreterTests.currentAgentOpenTicket,
                    InterpreterTests.currentAgentWaitingTicket
                ]
            )
        }

        @Test("Preserves source order instead of alternative order")
        func preservesInboxOrder() throws {
            let matches = try InterpreterTests.filter.tickets(
                matching: "status:(waiting|open)",
                in: InterpreterTests.tickets
            )

            #expect(
                matches == [
                    InterpreterTests.currentAgentOpenTicket,
                    InterpreterTests.currentAgentWaitingTicket,
                    InterpreterTests.colleagueOpenTicket
                ]
            )
        }

        @Test("Keeps repeated fields conjunctive")
        func interpretsRepeatedFieldsWithAnd() throws {
            let matches = try InterpreterTests.filter.tickets(
                matching: "status:(open|waiting) status:closed",
                in: InterpreterTests.tickets
            )

            #expect(matches.isEmpty)
        }

        @Test("Interprets current and missing assignees without global state")
        func interpretsAssigneeAliases() throws {
            let currentAgentMatches = try InterpreterTests.filter.tickets(
                matching: "assignee:me",
                in: InterpreterTests.tickets
            )
            let unassignedMatches = try InterpreterTests.filter.tickets(
                matching: "assignee:unassigned",
                in: InterpreterTests.tickets
            )

            #expect(
                currentAgentMatches == [
                    InterpreterTests.currentAgentOpenTicket,
                    InterpreterTests.currentAgentWaitingTicket
                ]
            )
            #expect(
                unassignedMatches == [
                    InterpreterTests.unassignedClosedTicket
                ]
            )
        }
    }

    @Suite("Positioned diagnostics")
    struct PositionedDiagnostics {
        @Test(
            "Rejects invalid syntax or vocabulary at its exact position",
            arguments: invalidQueries
        )
        func rejectsInvalidQuery(_ scenario: InvalidQuery) {
            #expect(throws: scenario.expectedError) {
                try InterpreterTests.parser.parse(scenario.query)
            }
        }

        private static let invalidQueries = [
            InvalidQuery(
                query: "open",
                expectedError: .malformedTerm(position: 0)
            ),
            InvalidQuery(
                query: "status:",
                expectedError: .missingValue(field: "status", position: 7)
            ),
            InvalidQuery(
                query: "priority:urgent",
                expectedError: .unsupportedField("priority", position: 0)
            ),
            InvalidQuery(
                query: "status:(open|waiting",
                expectedError: .unclosedGroup(position: 7)
            ),
            InvalidQuery(
                query: "status:(open||waiting)",
                expectedError: .emptyAlternative(position: 13)
            ),
            InvalidQuery(
                query: "status:open|waiting",
                expectedError: .unexpectedDelimiter("|", position: 11)
            ),
            InvalidQuery(
                query: "status:(open|urgent)",
                expectedError: .unsupportedStatus("urgent", position: 13)
            ),
            InvalidQuery(
                query: "assignee:(me|unassigned)",
                expectedError: .groupingNotSupported(
                    field: "assignee",
                    position: 9
                )
            ),
            InvalidQuery(
                query: "assignee:anyone",
                expectedError: .unsupportedAssignee("anyone", position: 9)
            )
        ]
    }
}

struct InvalidQuery: CustomTestStringConvertible, Sendable {
    let query: String
    let expectedError: SupportTicketQueryError

    var testDescription: String {
        query
    }
}
