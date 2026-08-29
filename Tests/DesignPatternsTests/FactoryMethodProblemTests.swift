import Foundation
import DesignPatterns
import Testing

@Suite("Factory Method problem")
struct FactoryMethodProblemTests {
    private static let accountID = "account-77"
    private static let transaction = ImportedBankTransaction(
        transactionID: "txn-1",
        bookedOn: "2026-08-28",
        amountInMinorUnits: -1_299,
        currency: "EUR",
        merchant: "Metro Market"
    )
    private static let northstarCSV = """
    \u{FEFF}NORTHSTAR-STATEMENT
    id,date,amount_minor,currency,merchant
    txn-1,2026-08-28,-1299,EUR,Metro Market
    """
    private static let mercadoSurOFX = """
    <OFX><BANKID>MSUR</BANKID><STMTTRN>
    <FITID>txn-1<DTPOSTED>20260828<TRNAMT>-1299<NAME>Metro Market</STMTTRN></OFX>
    """
    private static let lumenJSON = Data("""
    {
      "data": {
        "transactions": [
          {
            "id": "txn-1",
            "date": "2026-08-28",
            "amountMinor": -1299,
            "currency": "EUR",
            "merchant": "Metro Market"
          }
        ]
      }
    }
    """.utf8)

    @Suite("Factory Method creators")
    struct Creators {
        @Test("Northstar workflow creates the CSV parser")
        func northstarCreatesParser() throws {
            let workflow = NorthstarBankStatementWorkflow()
            let prepared = try workflow.preparePayload(.csv(FactoryMethodProblemTests.northstarCSV))
            let transactions = try workflow.makeParser().parse(prepared)

            #expect(transactions == [FactoryMethodProblemTests.transaction])
        }

        @Test("Mercado Sur workflow creates the OFX parser")
        func mercadoSurCreatesParser() throws {
            let workflow = MercadoSurBankStatementWorkflow()
            let prepared = try workflow.preparePayload(.ofx(FactoryMethodProblemTests.mercadoSurOFX))
            let transactions = try workflow.makeParser().parse(prepared)

            #expect(transactions == [FactoryMethodProblemTests.transaction])
        }

        @Test("Lumen workflow creates the open-banking parser")
        func lumenCreatesParser() throws {
            let workflow = LumenBankStatementWorkflow()
            let prepared = try workflow.preparePayload(.openBankingJSON(FactoryMethodProblemTests.lumenJSON))
            let transactions = try workflow.makeParser().parse(prepared)

            #expect(transactions == [FactoryMethodProblemTests.transaction])
        }
    }

    @Suite("Provider workflows")
    struct ProviderWorkflows {
        @Test("Imports Northstar CSV into app-owned transactions")
        func importsNorthstar() throws {
            let request = BankStatementImportRequest(
                accountID: FactoryMethodProblemTests.accountID,
                provider: .northstar,
                payload: .csv(FactoryMethodProblemTests.northstarCSV)
            )

            let statement = try importBankStatement(request)

            #expect(statement.accountID == FactoryMethodProblemTests.accountID)
            #expect(statement.provider == .northstar)
            #expect(statement.transactions == [FactoryMethodProblemTests.transaction])
        }

        @Test("Imports Mercado Sur OFX with provider-specific dates")
        func importsMercadoSur() throws {
            let request = BankStatementImportRequest(
                accountID: FactoryMethodProblemTests.accountID,
                provider: .mercadoSur,
                payload: .ofx(FactoryMethodProblemTests.mercadoSurOFX)
            )

            let statement = try importBankStatement(request)

            #expect(statement.provider == .mercadoSur)
            #expect(statement.transactions == [FactoryMethodProblemTests.transaction])
        }

        @Test("Imports Lumen open-banking JSON")
        func importsLumen() throws {
            let request = BankStatementImportRequest(
                accountID: FactoryMethodProblemTests.accountID,
                provider: .lumenOpenBanking,
                payload: .openBankingJSON(FactoryMethodProblemTests.lumenJSON)
            )

            let statement = try importBankStatement(request)

            #expect(statement.provider == .lumenOpenBanking)
            #expect(statement.transactions == [FactoryMethodProblemTests.transaction])
        }
    }

    @Suite("Input boundary")
    struct InputBoundary {
        @Test("Rejects a payload that does not belong to the provider")
        func rejectsMismatchedPayload() {
            let request = BankStatementImportRequest(
                accountID: FactoryMethodProblemTests.accountID,
                provider: .northstar,
                payload: .ofx(FactoryMethodProblemTests.mercadoSurOFX)
            )

            #expect(throws: BankStatementImportError.unsupportedPayload(provider: .northstar)) {
                try importBankStatement(request)
            }
        }

        @Test("Rejects malformed provider data")
        func rejectsMalformedData() {
            let request = BankStatementImportRequest(
                accountID: FactoryMethodProblemTests.accountID,
                provider: .northstar,
                payload: .csv("id,date,amount_minor,currency,merchant\nbroken")
            )

            #expect(throws: BankStatementImportError.malformedStatement(provider: .northstar)) {
                try importBankStatement(request)
            }
        }

        @Test("Rejects a provider envelope that cannot be prepared")
        func rejectsMalformedProviderEnvelope() {
            let request = BankStatementImportRequest(
                accountID: FactoryMethodProblemTests.accountID,
                provider: .northstar,
                payload: .csv("id,date,amount_minor,currency,merchant\ntxn-1,2026-08-28,-1299,EUR,Metro Market")
            )

            #expect(throws: BankStatementImportError.malformedStatement(provider: .northstar)) {
                try importBankStatement(request)
            }
        }

        @Test("Rejects an incomplete Mercado Sur envelope")
        func rejectsIncompleteMercadoSurEnvelope() {
            let request = BankStatementImportRequest(
                accountID: FactoryMethodProblemTests.accountID,
                provider: .mercadoSur,
                payload: .ofx("<OFX><STMTTRN><FITID>txn-1")
            )

            #expect(throws: BankStatementImportError.malformedStatement(provider: .mercadoSur)) {
                try importBankStatement(request)
            }
        }

        @Test("Rejects an incomplete Lumen envelope")
        func rejectsIncompleteLumenEnvelope() {
            let request = BankStatementImportRequest(
                accountID: FactoryMethodProblemTests.accountID,
                provider: .lumenOpenBanking,
                payload: .openBankingJSON(Data("{\"transactions\":[]}".utf8))
            )

            #expect(throws: BankStatementImportError.malformedStatement(provider: .lumenOpenBanking)) {
                try importBankStatement(request)
            }
        }
    }

    @Suite("Value semantics")
    struct ValueSemantics {
        @Test("Does not mutate the import request")
        func preservesInputValue() throws {
            let request = BankStatementImportRequest(
                accountID: FactoryMethodProblemTests.accountID,
                provider: .northstar,
                payload: .csv(FactoryMethodProblemTests.northstarCSV)
            )

            _ = try importBankStatement(request)

            #expect(request.accountID == FactoryMethodProblemTests.accountID)
            #expect(request.provider == .northstar)
            #expect(request.payload == .csv(FactoryMethodProblemTests.northstarCSV))
        }
    }
}
