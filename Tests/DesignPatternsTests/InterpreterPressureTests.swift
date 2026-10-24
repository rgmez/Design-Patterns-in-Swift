import DesignPatterns
import Testing

@Suite("Interpreter pressure")
struct InterpreterPressureTests {
    private static let currentAgentID = "agent-robin"
    private static let tickets = [
        SupportTicket(
            id: "ticket-refund-1042",
            status: .open,
            assigneeID: currentAgentID
        ),
        SupportTicket(
            id: "ticket-delivery-1043",
            status: .waiting,
            assigneeID: currentAgentID
        ),
        SupportTicket(
            id: "ticket-address-1044",
            status: .open,
            assigneeID: "agent-sam"
        ),
        SupportTicket(
            id: "ticket-payment-1045",
            status: .closed,
            assigneeID: nil
        )
    ]
    private static let filter = PressureSupportTicketFilter(
        currentAgentID: currentAgentID
    )

    @Suite("Grouped status alternatives")
    struct GroupedStatusAlternatives {
        @Test("Uses OR inside a status group and AND between terms")
        func composesGroupedStatusWithAssignee() throws {
            let matches = try InterpreterPressureTests.filter.tickets(
                matching: "status:(open|waiting) assignee:me",
                in: InterpreterPressureTests.tickets
            )

            #expect(
                matches.map(\.id) == [
                    "ticket-refund-1042",
                    "ticket-delivery-1043"
                ]
            )
        }

        @Test("Preserves inbox order across every accepted alternative")
        func preservesOrder() throws {
            let matches = try InterpreterPressureTests.filter.tickets(
                matching: "status:(waiting|open)",
                in: InterpreterPressureTests.tickets
            )

            #expect(
                matches.map(\.id) == [
                    "ticket-refund-1042",
                    "ticket-delivery-1043",
                    "ticket-address-1044"
                ]
            )
        }

        @Test("Keeps repeated fields conjunctive")
        func keepsRepeatedFieldsConjunctive() throws {
            let matches = try InterpreterPressureTests.filter.tickets(
                matching: "status:(open|waiting) status:closed",
                in: InterpreterPressureTests.tickets
            )

            #expect(matches.isEmpty)
        }
    }

    @Suite("Positioned diagnostics")
    struct PositionedDiagnostics {
        @Test("Reports the opening position of an unclosed group")
        func reportsUnclosedGroup() {
            #expect(
                throws: SupportTicketPressureFilterError.unclosedGroup(
                    position: 7
                )
            ) {
                try InterpreterPressureTests.filter.tickets(
                    matching: "status:(open|waiting",
                    in: InterpreterPressureTests.tickets
                )
            }
        }

        @Test("Reports the exact empty alternative")
        func reportsEmptyAlternative() {
            #expect(
                throws: SupportTicketPressureFilterError.emptyAlternative(
                    position: 13
                )
            ) {
                try InterpreterPressureTests.filter.tickets(
                    matching: "status:(open||waiting)",
                    in: InterpreterPressureTests.tickets
                )
            }
        }

        @Test("Rejects an alternative delimiter outside a group")
        func rejectsUngroupedAlternative() {
            #expect(
                throws: SupportTicketPressureFilterError.unexpectedDelimiter(
                    "|",
                    position: 11
                )
            ) {
                try InterpreterPressureTests.filter.tickets(
                    matching: "status:open|waiting",
                    in: InterpreterPressureTests.tickets
                )
            }
        }

        @Test("Keeps grouped alternatives limited to status")
        func rejectsGroupedAssignees() {
            #expect(
                throws: SupportTicketPressureFilterError.groupingNotSupported(
                    field: "assignee",
                    position: 9
                )
            ) {
                try InterpreterPressureTests.filter.tickets(
                    matching: "assignee:(me|unassigned)",
                    in: InterpreterPressureTests.tickets
                )
            }
        }

        @Test("Positions unsupported values inside their group")
        func positionsUnsupportedStatus() {
            #expect(
                throws: SupportTicketPressureFilterError.unsupportedStatus(
                    "urgent",
                    position: 13
                )
            ) {
                try InterpreterPressureTests.filter.tickets(
                    matching: "status:(open|urgent)",
                    in: InterpreterPressureTests.tickets
                )
            }
        }
    }
}
