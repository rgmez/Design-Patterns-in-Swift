public enum SupportTicketQueryError: Error, Equatable, Sendable {
    case malformedTerm(position: Int)
    case missingValue(field: String, position: Int)
    case unsupportedField(String, position: Int)
    case unsupportedStatus(String, position: Int)
    case unsupportedAssignee(String, position: Int)
    case unclosedGroup(position: Int)
    case emptyAlternative(position: Int)
    case unexpectedDelimiter(Character, position: Int)
    case groupingNotSupported(field: String, position: Int)
}

public enum SupportTicketAssigneeExpression: Equatable, Sendable {
    case currentAgent
    case unassigned
}

public enum SupportTicketFilterExpression: Equatable, Sendable {
    case status(Set<SupportTicketStatus>)
    case assignee(SupportTicketAssigneeExpression)

    public func interpret(
        _ ticket: SupportTicket,
        currentAgentID: String
    ) -> Bool {
        switch self {
        case let .status(statuses):
            statuses.contains(ticket.status)
        case .assignee(.currentAgent):
            ticket.assigneeID == currentAgentID
        case .assignee(.unassigned):
            ticket.assigneeID == nil
        }
    }
}

public struct SupportTicketQuery: Equatable, Sendable {
    public let expressions: [SupportTicketFilterExpression]

    fileprivate init(expressions: [SupportTicketFilterExpression]) {
        self.expressions = expressions
    }

    public func interpret(
        _ ticket: SupportTicket,
        currentAgentID: String
    ) -> Bool {
        expressions.allSatisfy {
            $0.interpret(ticket, currentAgentID: currentAgentID)
        }
    }
}

public struct SupportTicketQueryParser: Sendable {
    public init() {}

    public func parse(_ query: String) throws -> SupportTicketQuery {
        let characters = Array(query)
        var cursor = 0
        var expressions: [SupportTicketFilterExpression] = []

        while cursor < characters.count {
            while cursor < characters.count,
                  characters[cursor].isWhitespace {
                cursor += 1
            }

            guard cursor < characters.count else {
                break
            }

            let termStart = cursor
            while cursor < characters.count,
                  !characters[cursor].isWhitespace {
                cursor += 1
            }

            expressions.append(
                try parseTerm(
                    Array(characters[termStart..<cursor]),
                    at: termStart
                )
            )
        }

        return SupportTicketQuery(expressions: expressions)
    }

    private func parseTerm(
        _ term: [Character],
        at termStart: Int
    ) throws -> SupportTicketFilterExpression {
        guard let separator = term.firstIndex(of: ":") else {
            throw SupportTicketQueryError.malformedTerm(position: termStart)
        }

        let field = String(term[..<separator])
        let valueStart = separator + 1
        guard valueStart < term.count else {
            throw SupportTicketQueryError.missingValue(
                field: field,
                position: termStart + valueStart
            )
        }

        let value = Array(term[valueStart...])
        switch field {
        case "status":
            return .status(
                try parseStatuses(value, at: termStart + valueStart)
            )
        case "assignee":
            return .assignee(
                try parseAssignee(value, at: termStart + valueStart)
            )
        default:
            throw SupportTicketQueryError.unsupportedField(
                field,
                position: termStart
            )
        }
    }

    private func parseStatuses(
        _ value: [Character],
        at valueStart: Int
    ) throws -> Set<SupportTicketStatus> {
        guard value.first == "(" else {
            if let delimiter = value.firstIndex(where: {
                $0 == "(" || $0 == ")" || $0 == "|"
            }) {
                throw SupportTicketQueryError.unexpectedDelimiter(
                    value[delimiter],
                    position: valueStart + delimiter
                )
            }

            return [try parseStatus(String(value), at: valueStart)]
        }

        guard let closingGroup = value.firstIndex(of: ")") else {
            throw SupportTicketQueryError.unclosedGroup(position: valueStart)
        }
        guard closingGroup == value.count - 1 else {
            let unexpected = closingGroup + 1
            throw SupportTicketQueryError.unexpectedDelimiter(
                value[unexpected],
                position: valueStart + unexpected
            )
        }

        var statuses: Set<SupportTicketStatus> = []
        var optionStart = 1

        for index in 1..<closingGroup where value[index] == "|" {
            guard optionStart < index else {
                throw SupportTicketQueryError.emptyAlternative(
                    position: valueStart + index
                )
            }

            statuses.insert(
                try parseStatus(
                    String(value[optionStart..<index]),
                    at: valueStart + optionStart
                )
            )
            optionStart = index + 1
        }

        guard optionStart < closingGroup else {
            throw SupportTicketQueryError.emptyAlternative(
                position: valueStart + closingGroup
            )
        }

        statuses.insert(
            try parseStatus(
                String(value[optionStart..<closingGroup]),
                at: valueStart + optionStart
            )
        )
        return statuses
    }

    private func parseStatus(
        _ rawStatus: String,
        at position: Int
    ) throws -> SupportTicketStatus {
        guard let status = SupportTicketStatus(rawValue: rawStatus) else {
            throw SupportTicketQueryError.unsupportedStatus(
                rawStatus,
                position: position
            )
        }
        return status
    }

    private func parseAssignee(
        _ value: [Character],
        at position: Int
    ) throws -> SupportTicketAssigneeExpression {
        if value.contains("(") || value.contains(")") || value.contains("|") {
            throw SupportTicketQueryError.groupingNotSupported(
                field: "assignee",
                position: position
            )
        }

        switch String(value) {
        case "me":
            return .currentAgent
        case "unassigned":
            return .unassigned
        default:
            throw SupportTicketQueryError.unsupportedAssignee(
                String(value),
                position: position
            )
        }
    }
}

public struct InterpretedSupportTicketFilter: Sendable {
    public let currentAgentID: String
    private let parser = SupportTicketQueryParser()

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
        let expression = try parser.parse(query)
        return tickets.filter {
            expression.interpret($0, currentAgentID: currentAgentID)
        }
    }
}
