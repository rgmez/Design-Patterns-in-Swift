import DesignPatterns
import Testing

@Suite("Interpreter problem")
struct InterpreterProblemTests {
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
    private static let unassignedOpenTicket = SupportTicket(
        id: "ticket-payment-1045",
        status: .open,
        assigneeID: nil
    )
    private static let closedTicket = SupportTicket(
        id: "ticket-cancelled-1046",
        status: .closed,
        assigneeID: nil
    )
    private static let tickets = [
        currentAgentOpenTicket,
        currentAgentWaitingTicket,
        colleagueOpenTicket,
        unassignedOpenTicket,
        closedTicket
    ]
    private static let filter = DirectSupportTicketFilter(
        currentAgentID: currentAgentID
    )

    @Suite("Conjunctive filters")
    struct ConjunctiveFilters {
        @Test("Combines status and current-assignee terms with AND semantics")
        func filtersOpenTicketsAssignedToCurrentAgent() throws {
            let matches = try InterpreterProblemTests.filter.tickets(
                matching: "status:open assignee:me",
                in: InterpreterProblemTests.tickets
            )

            #expect(
                matches == [InterpreterProblemTests.currentAgentOpenTicket]
            )
        }

        @Test("Finds unassigned tickets without interpreting an agent ID")
        func filtersUnassignedTickets() throws {
            let matches = try InterpreterProblemTests.filter.tickets(
                matching: "assignee:unassigned",
                in: InterpreterProblemTests.tickets
            )

            #expect(
                matches == [
                    InterpreterProblemTests.unassignedOpenTicket,
                    InterpreterProblemTests.closedTicket
                ]
            )
        }

        @Test("Keeps source order when one term matches several tickets")
        func preservesInboxOrder() throws {
            let matches = try InterpreterProblemTests.filter.tickets(
                matching: "status:open",
                in: InterpreterProblemTests.tickets
            )

            #expect(
                matches == [
                    InterpreterProblemTests.currentAgentOpenTicket,
                    InterpreterProblemTests.colleagueOpenTicket,
                    InterpreterProblemTests.unassignedOpenTicket
                ]
            )
        }

        @Test("Treats a blank query as the unfiltered inbox")
        func keepsAllTicketsForBlankQuery() throws {
            let matches = try InterpreterProblemTests.filter.tickets(
                matching: "   \n ",
                in: InterpreterProblemTests.tickets
            )

            #expect(matches == InterpreterProblemTests.tickets)
        }
    }

    @Suite("Rejected terms")
    struct RejectedTerms {
        @Test("Rejects a term without the field separator")
        func rejectsMalformedTerm() {
            #expect(
                throws: SupportTicketFilterError.malformedTerm("open")
            ) {
                try InterpreterProblemTests.filter.tickets(
                    matching: "open",
                    in: InterpreterProblemTests.tickets
                )
            }
        }

        @Test("Rejects a known field with no value")
        func rejectsMissingValue() {
            #expect(
                throws: SupportTicketFilterError.missingValue(field: "status")
            ) {
                try InterpreterProblemTests.filter.tickets(
                    matching: "status:",
                    in: InterpreterProblemTests.tickets
                )
            }
        }

        @Test("Rejects fields outside the bounded grammar")
        func rejectsUnsupportedField() {
            #expect(
                throws: SupportTicketFilterError.unsupportedField("priority")
            ) {
                try InterpreterProblemTests.filter.tickets(
                    matching: "priority:urgent",
                    in: InterpreterProblemTests.tickets
                )
            }
        }

        @Test("Rejects values outside each field vocabulary")
        func rejectsUnsupportedValues() {
            #expect(
                throws: SupportTicketFilterError.unsupportedStatus("urgent")
            ) {
                try InterpreterProblemTests.filter.tickets(
                    matching: "status:urgent",
                    in: InterpreterProblemTests.tickets
                )
            }
            #expect(
                throws: SupportTicketFilterError.unsupportedAssignee("anyone")
            ) {
                try InterpreterProblemTests.filter.tickets(
                    matching: "assignee:anyone",
                    in: InterpreterProblemTests.tickets
                )
            }
        }
    }
}
