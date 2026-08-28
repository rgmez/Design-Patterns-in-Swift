import Foundation

public enum BankStatementProvider: String, CaseIterable, Equatable, Sendable {
    case northstar
    case mercadoSur
    case lumenOpenBanking
}

public enum BankStatementPayload: Equatable, Sendable {
    case csv(String)
    case ofx(String)
    case openBankingJSON(Data)
}

public struct BankStatementImportRequest: Equatable, Sendable {
    public let accountID: String
    public let provider: BankStatementProvider
    public let payload: BankStatementPayload

    public init(
        accountID: String,
        provider: BankStatementProvider,
        payload: BankStatementPayload
    ) {
        self.accountID = accountID
        self.provider = provider
        self.payload = payload
    }
}

public struct ImportedBankTransaction: Equatable, Sendable {
    public let transactionID: String
    public let bookedOn: String
    public let amountInMinorUnits: Int
    public let currency: String
    public let merchant: String

    public init(
        transactionID: String,
        bookedOn: String,
        amountInMinorUnits: Int,
        currency: String,
        merchant: String
    ) {
        self.transactionID = transactionID
        self.bookedOn = bookedOn
        self.amountInMinorUnits = amountInMinorUnits
        self.currency = currency
        self.merchant = merchant
    }
}

public struct BankStatementImport: Equatable, Sendable {
    public let accountID: String
    public let provider: BankStatementProvider
    public let transactions: [ImportedBankTransaction]

    public init(
        accountID: String,
        provider: BankStatementProvider,
        transactions: [ImportedBankTransaction]
    ) {
        self.accountID = accountID
        self.provider = provider
        self.transactions = transactions
    }
}

public enum BankStatementImportError: Error, Equatable, Sendable {
    case unsupportedPayload(provider: BankStatementProvider)
    case malformedStatement(provider: BankStatementProvider)
}

/// Direct baseline: the provider switch owns both workflow selection and parser creation.
public func importBankStatement(
    _ request: BankStatementImportRequest
) throws -> BankStatementImport {
    let transactions: [ImportedBankTransaction]

    switch request.provider {
    case .northstar:
        guard case let .csv(csv) = request.payload else {
            throw BankStatementImportError.unsupportedPayload(provider: request.provider)
        }
        transactions = try parseNorthstarCSV(csv)
    case .mercadoSur:
        guard case let .ofx(ofx) = request.payload else {
            throw BankStatementImportError.unsupportedPayload(provider: request.provider)
        }
        transactions = try parseMercadoSurOFX(ofx)
    case .lumenOpenBanking:
        guard case let .openBankingJSON(json) = request.payload else {
            throw BankStatementImportError.unsupportedPayload(provider: request.provider)
        }
        transactions = try parseLumenJSON(json)
    }

    return BankStatementImport(
        accountID: request.accountID,
        provider: request.provider,
        transactions: transactions
    )
}

private func parseNorthstarCSV(_ csv: String) throws -> [ImportedBankTransaction] {
    let rows = csv.split(whereSeparator: \.isNewline).dropFirst()
    let transactions = rows.compactMap { row -> ImportedBankTransaction? in
        let fields = row.split(separator: ",", omittingEmptySubsequences: false)
        guard fields.count == 5,
              let amount = Int(fields[2]) else { return nil }
        return ImportedBankTransaction(
            transactionID: String(fields[0]),
            bookedOn: String(fields[1]),
            amountInMinorUnits: amount,
            currency: String(fields[3]),
            merchant: String(fields[4])
        )
    }
    guard transactions.count == rows.count, !transactions.isEmpty else {
        throw BankStatementImportError.malformedStatement(provider: .northstar)
    }
    return transactions
}

private func parseMercadoSurOFX(_ ofx: String) throws -> [ImportedBankTransaction] {
    let blocks = ofx.components(separatedBy: "<STMTTRN>").dropFirst()
    let transactions = blocks.compactMap { block -> ImportedBankTransaction? in
        guard let id = value(in: block, tag: "FITID"),
              let date = value(in: block, tag: "DTPOSTED"),
              let amount = value(in: block, tag: "TRNAMT").flatMap(Int.init),
              let merchant = value(in: block, tag: "NAME") else { return nil }
        return ImportedBankTransaction(
            transactionID: id,
            bookedOn: normalizeOFXDate(date),
            amountInMinorUnits: amount,
            currency: value(in: block, tag: "CURDEF") ?? "EUR",
            merchant: merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
    guard transactions.count == blocks.count, !transactions.isEmpty else {
        throw BankStatementImportError.malformedStatement(provider: .mercadoSur)
    }
    return transactions
}

private func parseLumenJSON(_ data: Data) throws -> [ImportedBankTransaction] {
    struct Statement: Decodable {
        let transactions: [Transaction]
    }
    struct Transaction: Decodable {
        let id: String
        let date: String
        let amountMinor: Int
        let currency: String
        let merchant: String
    }

    do {
        let statement = try JSONDecoder().decode(Statement.self, from: data)
        guard !statement.transactions.isEmpty else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Empty statement")
            )
        }
        return statement.transactions.map {
            ImportedBankTransaction(
                transactionID: $0.id,
                bookedOn: $0.date,
                amountInMinorUnits: $0.amountMinor,
                currency: $0.currency,
                merchant: $0.merchant
            )
        }
    } catch {
        throw BankStatementImportError.malformedStatement(provider: .lumenOpenBanking)
    }
}

private func value(in block: String, tag: String) -> String? {
    guard let start = block.range(of: "<\(tag)>") else { return nil }
    let remainder = block[start.upperBound...]
    guard let end = remainder.firstIndex(of: "<") else { return nil }
    return String(remainder[..<end])
}

private func normalizeOFXDate(_ value: String) -> String {
    let digits = value.prefix(8)
    guard digits.count == 8 else { return value }
    let year = digits.prefix(4)
    let month = digits.dropFirst(4).prefix(2)
    let day = digits.dropFirst(6).prefix(2)
    return "\(year)-\(month)-\(day)"
}
