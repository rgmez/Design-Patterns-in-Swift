# Factory Method Pressure: Provider-Owned Import Workflows

Pressure-review date: 2026-08-28

This document records Day 019 of the Factory Method cycle. It extends the
direct bank-statement importer with provider-specific preparation and measures
the pressure before introducing Factory Method.

## The requirement that changed

The three institutions no longer deliver parser-ready payloads:

- Northstar prefixes CSV exports with a UTF-8 BOM and a
  `NORTHSTAR-STATEMENT` envelope line.
- Mercado Sur wraps OFX transaction blocks in an institution envelope. The
  importer must discard the envelope before parsing statement blocks.
- Lumen's open-banking endpoint returns the statement under a `data` envelope
  instead of returning the transaction object directly.

The normalized `BankStatementImport` result stays the same. Preparation is
provider workflow, not business logic: it validates the provider response,
removes its transport wrapper, and hands parser-shaped input to the existing
normalizer.

## Direct Swift extension retained

`importBankStatement(_:)` still uses one exhaustive provider `switch`. Each
branch now performs two provider-specific steps in sequence:

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

The private preparation functions keep the change executable and small. They
reject an incompatible payload before preparation and reject a malformed
provider envelope instead of passing ambiguous data to a parser. No protocol,
creator hierarchy, registry, or runtime discovery mechanism exists yet.

## Measured pressure

The direct function now owns two decisions for every provider: how that
provider's response is prepared and which parser consumes the prepared value.
Adding the envelope rules required:

1. A new preparation function and validation path for each provider.
2. A second failure point in each provider branch, alongside payload-shape
   validation and parser errors.
3. Provider-specific fixtures for both the transport envelope and the
   normalized result.
4. Repeated edits to the same central import function whenever a provider adds
   authentication, pagination, cursor handling, or another preparation step.

The source remains readable for three providers, so line count alone does not
justify a pattern. The structural cost is the change direction: an importer
workflow change must edit the central function even when the shared result and
the other providers do not change. A fourth provider would add another branch
that coordinates preparation, parser selection, and error translation in this
same function.

## Why a Simple Factory is not the full answer

A centralized Simple Factory could move parser construction behind a function
such as `makeParser(for:)`. That would hide the `switch` that creates parser
instances, but it would leave the importer responsible for deciding how each
provider's raw response is prepared before the parser is called. The workflow
would still be centralized and every new provider would still modify the same
selection point.

Simple Factory remains a good choice when creation is the only variation: a
closed format enum can return one parser per format without a provider-owned
workflow. Factory Method becomes relevant only when each concrete importer
workflow can choose the parser it creates while sharing the import operation's
invariant result handling.

## Executable evidence

[`FactoryMethodProblemTests.swift`](../Tests/DesignPatternsTests/FactoryMethodProblemTests.swift)
now verifies:

- each provider's transport envelope is prepared before parsing;
- the same normalized transaction is produced for CSV, OFX, and JSON;
- mismatched payloads fail before provider preparation;
- malformed provider envelopes fail explicitly;
- the request remains an immutable value.

Run the evidence from the repository root:

```sh
swift test -Xswiftc -warnings-as-errors --filter FactoryMethodProblemTests
```

## What still does not justify Factory Method

The provider set is still small and closed, all parsers return the same value,
and the direct branches are easy to inspect. A fourth provider that only adds a
new format case would not justify a creator hierarchy. A local helper or a
Simple Factory remains preferable when preparation is absent or shared.

The pattern earns consideration when provider workflows need to evolve and be
tested independently, while the import operation must continue to enforce one
stable result contract. The completed [canonical Factory Method guide](../Creational%20Patterns/Factory%20Method/README.md)
introduces only that minimum creator boundary and contrasts it with the direct
and Simple Factory alternatives.

## Day 019 decision

Provider-specific preparation makes the workflow variation concrete: the
central switch now coordinates transport validation, preparation, parser
selection, and parser errors. The direct solution remains correct and
warning-free, but its extension pressure is now observable rather than
hypothetical. Factory Method is considered and is now implemented in the
canonical guide without expanding the parser product contract.
