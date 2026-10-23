public enum SupportTicketStatus: String, Equatable, Sendable {
    case open
    case waiting
    case closed
}

public struct SupportTicket: Equatable, Sendable {
    public let id: String
    public let status: SupportTicketStatus
    public let assigneeID: String?

    public init(
        id: String,
        status: SupportTicketStatus,
        assigneeID: String?
    ) {
        precondition(!id.isEmpty, "A support ticket needs an identifier")

        self.id = id
        self.status = status
        self.assigneeID = assigneeID
    }
}

public enum SupportTicketFilterError: Error, Equatable, Sendable {
    case malformedTerm(String)
    case missingValue(field: String)
    case unsupportedField(String)
    case unsupportedStatus(String)
    case unsupportedAssignee(String)
}

public struct DirectSupportTicketFilter: Sendable {
    public let currentAgentID: String

    public init(currentAgentID: String) {
        precondition(
            !currentAgentID.isEmpty,
            "A support filter needs the current agent identifier"
        )

        self.currentAgentID = currentAgentID
    }

    public func tickets(
        matching query: String,
        in tickets: [SupportTicket]
    ) throws -> [SupportTicket] {
        var matches = tickets

        for rawTerm in query.split(whereSeparator: \Character.isWhitespace) {
            let term = String(rawTerm)
            let parts = term.split(
                separator: ":",
                maxSplits: 1,
                omittingEmptySubsequences: false
            )

            guard parts.count == 2 else {
                throw SupportTicketFilterError.malformedTerm(term)
            }

            let field = String(parts[0])
            let value = String(parts[1])
            guard !value.isEmpty else {
                throw SupportTicketFilterError.missingValue(field: field)
            }

            switch field {
            case "status":
                guard let status = SupportTicketStatus(rawValue: value) else {
                    throw SupportTicketFilterError.unsupportedStatus(value)
                }
                matches = matches.filter { $0.status == status }
            case "assignee":
                switch value {
                case "me":
                    matches = matches.filter {
                        $0.assigneeID == currentAgentID
                    }
                case "unassigned":
                    matches = matches.filter { $0.assigneeID == nil }
                default:
                    throw SupportTicketFilterError.unsupportedAssignee(value)
                }
            default:
                throw SupportTicketFilterError.unsupportedField(field)
            }
        }

        return matches
    }
}
