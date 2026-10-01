# Proxy and Chain of Responsibility Review

Review date: 2026-10-01

This review closes Internal Day 056 by checking access decisions, URL lifetime,
error propagation, deterministic handler order, and the simpler alternatives.

## Responsibility matrix

| Question | Proxy | Chain of Responsibility |
| --- | --- | --- |
| What changes? | Three playback entry points stop duplicating one mandatory resource policy | Five route families stop adding branches to one central switch |
| Public boundary | The same lesson playback operation as the real subject | One router that asks feature-owned handlers in explicit order |
| Access owner | The proxy checks entitlement before every subject delegation | The order handler owns its session-dependent destination |
| Terminal outcome | Success or the original typed playback error | The first `handled` or `reject` decision stops traversal |
| Simpler default | One direct playback model for one caller | One exhaustive switch for a small, closed route set |

## Proxy findings

`EntitledLessonPlaybackProxy` checks access before the real subject requests a
short-lived URL. Denied access performs no media-service or player work. An
authorized request delegates once; only explicit URL expiration earns one more
complete subject delegation. A second expiration, player unavailability, media
unavailability, and media failure during replacement remain terminal.

The proxy deliberately caches neither authorization nor playback URLs. A new
regression test reuses one proxy for two successful requests and proves two
entitlement checks, two media requests, and two distinct player URLs. Caching
would need separate evidence for freshness, invalidation, memory limits, and
concurrent requests; adding it here would combine an unearned concern with the
demonstrated protection and lifecycle policy.

The generic proxy and value-semantic subject remain proportionate. Runtime
subject selection is not required, so an existential box, cache actor,
repository, and generic retry policy would add flexibility without a consumer.

## Chain findings

`CommerceLinkRouter` validates HTTPS, the configured host, and the two-segment
shape before constructing a request. It then consults handlers in array order.
Only `.pass` advances; `.handled` returns its destination, while `.reject`
terminates as `.unhandled` so an owned malformed specialized route cannot be
reinterpreted by a generic sibling.

Regression coverage now records an issue if a handler after a successful owner
is invoked. A separate insecure-scheme case uses the same guard to prove the
chain is not consulted before the app-level URL boundary accepts the link. The
existing malformed-referral case already proves that terminal rejection stops
before the generic campaign handler can claim the same path.

The explicit existential array is the only heterogeneous storage required.
Mutable `next` links, runtime registration, a dependency container, and a
middleware engine would hide the two precedence pairs that composition and
tests currently make visible.

## Classification and error semantics

Both examples forward work, but they answer different product questions. Proxy
always stands in front of one known subject and applies mandatory access and
lifecycle policy. Chain asks multiple candidates which feature owns a request
and stops at the first terminal decision. Reordering or omitting the Proxy gate
is not supported configuration; reordering Chain handlers can intentionally
change which overlapping route wins.

Proxy preserves typed operational errors because callers may need to distinguish
access denial, remote failure, player failure, and expired media. Chain has no
throwing feature boundary in this example: `.reject` is a routing decision for
an owned malformed URL, not a generic error channel. Introducing error erasure
or making every handler throwable would reduce clarity without reducing risk.

## Documentation and visual review

The canonical guides retain the app problem, direct baseline, measured pressure,
participants, Swift walkthrough, execution commands, tests, trade-offs,
alternatives, and explicit `When not to use it` guidance. Their local source
and test links resolve, and their Mermaid blocks use real domain names with an
explanatory paragraph and accessible equivalent.

The existing 1672 × 941 headers were compared with the approved Adapter
reference. Both retain the upper-left type hierarchy, upper-right original RG
mark, charcoal/red/orange palette, technical grid, and detailed lower-band
scene. Proxy uses one guarded conduit and a bounded key-return loop; Chain uses
one left-to-right route with a single terminal diversion. They remain visually
coherent with the collection, so no image regeneration is justified.

## Validation

```sh
swift build -Xswiftc -warnings-as-errors
swift test -Xswiftc -warnings-as-errors
swiftlint lint --strict --no-cache Sources Tests
git diff --check
git check-ignore -v Editorial/
```

- The focused Proxy and Chain run passes 18 tests in 9 suites, including the
  new regression cases.
- The full build succeeds and the warning-as-error suite passes 192 tests in
  104 suites.
- SwiftLint strict mode reports zero violations across 71 Swift files.
- Concrete local Markdown links resolve; external URLs and heading anchors are
  outside this check.
- Mermaid delimiters, diagram type, and domain identifiers were checked against
  the implementations. Mermaid CLI is unavailable, so no parser validation is
  claimed.
- Both editorial headers have the required 1672 × 941 dimensions and pass the
  five-part visual comparison.
- CodeGraph is not initialized. The review used the already scoped source,
  tests, and canonical guides; no index was created during this review.
- `Editorial/` remains ignored and outside the commit.

## Readiness decision

Day 056 is complete with focused regression coverage and no production
abstraction changes. Proxy owns fresh access and bounded resource renewal;
Chain owns ordered request selection and terminal routing decisions. Neither a
cache nor a middleware framework has earned a place.

Day 057 will define the direct Memento problem. It has not started. Day 056 is
not a publication milestone, so no LinkedIn draft is created or changed.
