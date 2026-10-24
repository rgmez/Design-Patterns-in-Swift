public enum SupportTicketPressureFilterError: Error, Equatable, Sendable {
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

public struct PressureSupportTicketFilter: Sendable {
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
        let characters = Array(query)
        var cursor = 0
        var matches = tickets

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

            matches = try apply(
                Array(characters[termStart..<cursor]),
                at: termStart,
                to: matches
            )
        }

        return matches
    }

    private func apply(
        _ term: [Character],
        at termStart: Int,
        to tickets: [SupportTicket]
    ) throws -> [SupportTicket] {
        guard let separator = term.firstIndex(of: ":") else {
            throw SupportTicketPressureFilterError.malformedTerm(
                position: termStart
            )
        }

        let field = String(term[..<separator])
        let valueStart = separator + 1
        guard valueStart < term.count else {
            throw SupportTicketPressureFilterError.missingValue(
                field: field,
                position: termStart + valueStart
            )
        }

        let value = Array(term[valueStart...])
        switch field {
        case "status":
            let statuses = try parseStatuses(
                value,
                at: termStart + valueStart
            )
            return tickets.filter { statuses.contains($0.status) }
        case "assignee":
            return try filterAssignee(
                String(value),
                at: termStart + valueStart,
                in: tickets
            )
        default:
            throw SupportTicketPressureFilterError.unsupportedField(
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
                throw SupportTicketPressureFilterError.unexpectedDelimiter(
                    value[delimiter],
                    position: valueStart + delimiter
                )
            }

            return [try parseStatus(String(value), at: valueStart)]
        }

        guard let closingGroup = value.firstIndex(of: ")") else {
            throw SupportTicketPressureFilterError.unclosedGroup(
                position: valueStart
            )
        }
        guard closingGroup == value.count - 1 else {
            let unexpected = closingGroup + 1
            throw SupportTicketPressureFilterError.unexpectedDelimiter(
                value[unexpected],
                position: valueStart + unexpected
            )
        }

        var statuses: Set<SupportTicketStatus> = []
        var optionStart = 1

        for index in 1..<closingGroup where value[index] == "|" {
            guard optionStart < index else {
                throw SupportTicketPressureFilterError.emptyAlternative(
                    position: valueStart + index
                )
            }

            let rawStatus = String(value[optionStart..<index])
            statuses.insert(
                try parseStatus(rawStatus, at: valueStart + optionStart)
            )
            optionStart = index + 1
        }

        guard optionStart < closingGroup else {
            throw SupportTicketPressureFilterError.emptyAlternative(
                position: valueStart + closingGroup
            )
        }

        let rawStatus = String(value[optionStart..<closingGroup])
        statuses.insert(
            try parseStatus(rawStatus, at: valueStart + optionStart)
        )
        return statuses
    }

    private func parseStatus(
        _ rawStatus: String,
        at position: Int
    ) throws -> SupportTicketStatus {
        guard let status = SupportTicketStatus(rawValue: rawStatus) else {
            throw SupportTicketPressureFilterError.unsupportedStatus(
                rawStatus,
                position: position
            )
        }
        return status
    }

    private func filterAssignee(
        _ value: String,
        at position: Int,
        in tickets: [SupportTicket]
    ) throws -> [SupportTicket] {
        if value.contains("(") || value.contains(")") || value.contains("|") {
            throw SupportTicketPressureFilterError.groupingNotSupported(
                field: "assignee",
                position: position
            )
        }

        switch value {
        case "me":
            return tickets.filter { $0.assigneeID == currentAgentID }
        case "unassigned":
            return tickets.filter { $0.assigneeID == nil }
        default:
            throw SupportTicketPressureFilterError.unsupportedAssignee(
                value,
                position: position
            )
        }
    }
}
