# Factory Method Problem: Bank Statement Import

Problem-definition date: 2026-08-28

This document defines Day 018 of the Factory Method cycle. It fixes a real
import workflow, keeps the first solution direct, and records the pressure
that Day 019 demonstrates before any creator hierarchy is introduced. The
pressure review is recorded in the [Factory Method pressure review](factory-method-pressure.md).

## Product scenario

A personal-finance app imports transactions from three connected institutions:

- Northstar exports a compact CSV file.
- Mercado Sur exports OFX-like statement blocks with bank-specific date fields.
- Lumen exposes open-banking JSON.

Each provider owns more than a file extension. The provider determines how an
account export is prepared and which parser understands that prepared input.
The app still needs one stable `BankStatementImport` value for categorization,
search, and reconciliation.

The example stops before authentication, pagination, currency conversion,
deduplication, and persistence. The payloads are local fixtures so preparation,
parser selection, and normalization remain executable without network services.

## Requirements and invariants

`BankStatementImportRequest` is app-owned and contains the account, provider,
and provider-shaped payload. `importBankStatement(_:)` must:

1. Prepare the provider envelope and select its compatible parser.
2. Normalize each provider's fields into `ImportedBankTransaction`.
3. Preserve account identity and the provider on the resulting import.
4. Reject a payload paired with the wrong provider before parsing.
5. Reject malformed or empty statements rather than returning partial data.
6. Avoid mutating the request value.

## Direct Swift first

The first implementation is one function with a provider `switch`. Each case
checks its payload shape, prepares the provider envelope, calls one private
parser, and returns the same app-owned result:

```swift
switch request.provider {
case .northstar:
    transactions = try parseNorthstarCSV(prepareNorthstarPayload(request.payload))
case .mercadoSur:
    transactions = try parseMercadoSurOFX(prepareMercadoSurPayload(request.payload))
case .lumenOpenBanking:
    transactions = try parseLumenJSON(prepareLumenPayload(request.payload))
}
```

This is deliberately not Factory Method. There is no creator workflow with an
overridable factory operation; a single centralized function prepares every
payload and chooses every parser. With three providers, the direct switch keeps
the control flow visible and compiler-exhaustive.

## Acceptance tests

[`FactoryMethodProblemTests.swift`](../Tests/DesignPatternsTests/FactoryMethodProblemTests.swift)
verifies:

- Northstar CSV, Mercado Sur OFX, and Lumen JSON normalize to the same domain value;
- provider envelopes are prepared before parsing;
- provider and account identity survive import;
- mismatched payloads and malformed data fail explicitly;
- the request remains unchanged.

Run the focused suite with:

```sh
swift test -Xswiftc -warnings-as-errors --filter FactoryMethodProblemTests
```

## Pressure demonstrated on Day 019

Factory Method should earn its place only if adding a provider means extending
an importer workflow, not merely adding another format case. Day 019 makes
that pressure concrete by showing provider-specific preparation and envelope
validation in the direct switch:

- Northstar, Mercado Sur, and Lumen each need different preparation before
  parsing;
- provider-specific workflow rules now sit beside parser selection;
- malformed envelopes add a second failure point before normalization;
- independent provider additions repeatedly modify the same import function and
  its tests.

If format selection remains the only variation, a closed enum and direct parser
switch is the better design. A Simple Factory may also be enough when creation
has no creator workflow to specialize. See the [pressure review](factory-method-pressure.md)
for the measured extension cost and the boundary carried into Day 020.

## Initial visual thesis

**Thesis:** Each bank prepares its own statement; the importer should let the
workflow choose the parser without multiplying incompatible import products.

**Scene:** Three dark bank statement feeds enter a single import workstation.
Each feed has a visibly different material and shape (CSV rows, OFX tags, JSON
brackets), while the output is one clean ledger rail. The central selection
point is the focal point, showing parser choice as controlled construction
rather than a generic factory icon.

The final Factory Method header belongs to Day 020. It must follow the shared
visual contract in [`visual-style.md`](visual-style.md) and use the approved
Adapter header only as the composition reference.

## Day 018 decision

The direct provider switch is executable and covered by nine tests. It remains
the right baseline while provider workflows are small, but Day 019 now records
the concrete preparation pressure before Factory Method is introduced.
