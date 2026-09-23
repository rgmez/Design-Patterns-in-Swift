# Decorator Pressure: One Upload Client, Eight Possible Pipelines

Pressure-review date: 2026-09-23

Internal Day 047 makes authentication, connection-loss retry, and terminal
metrics independently selectable. The implementation deliberately keeps those
choices as flags inside one concrete client so the cost is executable before
Decorator is introduced.

## The requirement that changed

The original creator deployment needed one fixed upload path. Product and
operations now need several legitimate profiles behind the same upload
operation:

- production uploads authenticate, retry a lost connection, and record one
  terminal metric;
- pre-signed uploads omit Bearer authentication but retain retry and metrics;
- uploads on a metered network authenticate and measure failure but do not
  repeat a large transfer automatically;
- users who opt out of telemetry still need authentication and retry;
- an in-app preview fixture needs only the underlying transport behavior.

Each feature can be on or off independently. Three binary choices produce
**eight possible behavior combinations**, even though the current product uses
only five. The client contract stays the same; only the behavior surrounding
the transport changes.

## The direct flag design retained

[`MediaUploadPressure.swift`](../Sources/DesignPatterns/Decorator/MediaUploadPressure.swift)
adds `FlagConfiguredMediaUploadClient` and a three-boolean
`MediaUploadBehaviorSelection`. The client still owns request construction,
the retry loop, response classification, and metric emission directly.

The flags introduce conditional state and control flow:

1. `authenticatesRequests` decides whether an access token is required and
   whether the request receives an `Authorization` header.
2. `retriesConnectionLoss` decides whether a transport failure re-enters the
   loop; `retryLimit` remains present even when retry is disabled.
3. `recordsMetrics` guards both success and every terminal failure path.
4. The method fixes authentication outside retry and metrics outside the whole
   logical operation. A caller can select features, but cannot state or change
   their order.

This is still not Decorator. There is no component protocol, wrapper, subclass,
middleware array, or type erasure. The flags are intentionally left visible as
the pressure to remove on Day 048.

## Measured pressure

The direct configurable client now exposes:

- **eight theoretical pipelines** from three independent binary features;
- **five currently required profiles** exercising distinct combinations;
- **three feature selectors** carried through every configured instance;
- **two conditionally meaningful values:** the token matters only when
  authentication is selected, and the retry limit matters only when retry is
  selected;
- **four conditional behavior sites:** header attachment, retry admission,
  success measurement, and failure measurement;
- **one hard-coded order** that callers cannot see in the configuration type.

Adding a fourth independent feature would double the matrix to 16 combinations.
The risk is not the arithmetic alone: each new terminal exit must remember the
metrics flag, each send path must preserve authentication, and retry must remain
inside one logical metric rather than producing one event per attempt.

## Executable evidence

[`DecoratorPressureTests.swift`](../Tests/DesignPatternsTests/DecoratorPressureTests.swift)
proves that the flag-configured client can currently preserve the required
semantics:

- production sends the same authenticated request twice after one lost
  connection and records one metric with two attempts;
- the pre-signed profile retries without adding a Bearer header;
- the metered-network profile stops after one failed attempt and measures it;
- telemetry opt-out retains authentication and retry but emits no metric;
- the minimal preview adds none of the three optional behaviors;
- selecting authentication without a token fails during configuration.

Run the focused evidence with:

```sh
swift test -Xswiftc -warnings-as-errors --filter DecoratorPressureTests
```

## Why order already matters

The flag implementation authenticates once while building the request, then
retries that same request. Metrics wrap the complete logical upload, so a
successful retry produces one event whose attempt count is two. Those choices
are correct for today's Bearer token and product analytics semantics.

They are nevertheless hidden in the method body. If authentication later
refreshes a token per attempt, it must move inside retry. If metrics move inside
retry, they change from one product outcome into transport-attempt telemetry.
Booleans say which behaviors exist; they cannot express which behavior encloses
another. Day 048 must make that ordering legible in composition and tests.

## Why inheritance does not solve the matrix

Subclassing would exchange flag branches for a family such as authenticated,
retrying, measured, authenticated-and-retrying, and so on—up to eight variants
before a fourth feature arrives. Combined subclasses must also choose one fixed
override order, and Swift structs cannot participate in that hierarchy.

The variation is not a taxonomy of upload clients. It is independently
selectable behavior around one operation, so inheritance would encode every
combination instead of composing the dimensions.

## Smaller alternatives considered

A configuration object is the implementation used today. It remains reasonable
when the set is closed, the order never varies, and every call site accepts the
same conditional dependencies. It becomes less clear as feature-specific state
and failure paths accumulate.

Free functions could transform a request for authentication and a response for
metrics. They do not naturally own retry, which must invoke the next operation
again, or preserve state such as an attempt count across that invocation. A
single closure pipeline is possible, but nested closures would still need a
named client contract and explicit ordering to remain teachable and testable.

An interceptor array would make ordering configurable, but it adds iteration,
an implicit continuation protocol, and usually type erasure. That is more
machinery than the three small, identity-bearing wrappers Day 048 should test.

## Boundary carried into Day 048

Decorator may replace the pressure client only if it:

- preserves one small upload-client contract and the existing typed failures;
- lets authentication, retry, and metrics be selected independently;
- makes wrapper order visible where the client is assembled;
- records one terminal metric around a logical upload, not one per attempt;
- keeps the same authenticated request across retries for the current policy;
- uses the minimum concrete wrappers and no generic middleware engine;
- retains the direct client when one fixed pipeline remains the cheaper choice.

## Day 047 decision

Flags can represent all eight combinations, but they mix conditional
dependencies, duplicate metric guards across terminal paths, and hide the only
valid behavior order inside one method. Decorator has now earned a narrow trial:
Day 048 must replace that branching with ordered composition without turning a
three-feature example into a framework.
