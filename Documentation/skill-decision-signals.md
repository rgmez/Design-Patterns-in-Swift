# 🧭 Evidence-Based Pattern Decision Signals

<a id="evidence-based-pattern-decision-signals"></a>

Extraction date: 2026-11-03

This document closes Internal Day 092 by turning the completed catalogue into decision evidence for the future `choose-swift-design-pattern` skill. It is not a second pattern catalogue. The [complete catalogue review](catalogue-review.md) and each canonical guide remain the source for implementation details, tests, and trade-offs.

The purpose here is narrower: identify the observable pressure that can earn a pattern, the rejection signal that keeps ordinary Swift, and the nearest design that must be ruled out before recommending added structure.

[← Repository overview](../README.md) · [Pattern catalogue](../README.md#pattern-catalogue) · [Reading guide](../README.md#reading-guide)

**On this page**

- [Evidence gate before naming a pattern](#evidence-gate-before-naming-a-pattern)
- [Cross-cutting rejection signals](#cross-cutting-rejection-signals)
- [Creational signals](#creational-signals)
- [Structural signals](#structural-signals)
- [Behavioral signals](#behavioral-signals)
- [Required neighbour checks](#required-neighbour-checks)
- [Decision record contract for the future skill](#decision-record-contract-for-the-future-skill)
- [Scope boundary and next evidence](#scope-boundary-and-next-evidence)

## Evidence gate before naming a pattern

A pattern is a justified outcome only when all four statements are true:

1. **A current requirement creates observable pressure.** The evidence is a real integration mismatch, invalid state, repeated coordination rule, independent change axis, ownership problem, or measured resource cost—not a speculative future feature.
2. **The direct Swift solution has a specific failure mode.** A value, enum, function, initializer, collection operation, actor, `AsyncSequence`, or platform API was considered first, and its remaining coupling or risk can be named.
3. **The pattern moves responsibility to a better owner.** It removes or localizes the demonstrated pressure instead of merely renaming the same branches behind protocols and extra types.
4. **The improvement is verifiable.** Tests, type constraints, ownership rules, or quantitative evidence can show the behavior the boundary protects.

If any statement is false, the decision is **no pattern yet**. Record the missing pressure and the concrete signal that would justify reconsideration. The [product-share decision](no-pattern-decision.md) is the catalogue's executable example: localization adds domain vocabulary, but all values still arrive together and one immutable request plus one pure function owns the work.

## Cross-cutting rejection signals

Keep the direct design when the proposed pattern is justified only by one of these arguments:

- “We may need more implementations later,” when only one stable implementation exists and no external boundary needs a test seam.
- “The initializer or switch is getting long,” when its inputs still arrive together and its rules remain local, closed, and easy to test.
- “This is the textbook shape,” when Swift value semantics, functions, enums, protocol extensions, actors, or native sequences already express the change.
- “It makes the API fluent or consistent,” when the added mutable lifetime or indirection protects no product invariant.
- “There are many objects,” without measured memory, identity, lifecycle, or coordination cost.
- “It decouples things,” without naming which dependency changes independently, which owner should absorb it, and which test proves the improvement.

These signals reject premature structure, not future evolution. A recommendation must state what new evidence would reverse the no-pattern verdict.

## Creational signals

| Pattern | Positive trigger | Reject the pattern when | Direct Swift baseline |
| --- | --- | --- | --- |
| [Factory Method](../Creational%20Patterns/Factory%20Method/README.md) | Each provider owns preparation and creation of one product inside the same extensible workflow. | Selection is the only variation, or creation is unrelated to a stable workflow. | A switch or injected creation closure. |
| [Abstract Factory](../Creational%20Patterns/Abstract%20Factory/README.md) | Several related products must be selected as one coherent family, and independent selection makes invalid combinations representable. | The family is closed and one aggregate switch keeps combinations valid, or only one product varies. | One composition function returning typed values. |
| [Builder](../Creational%20Patterns/Builder/README.md) | Inputs arrive across ordered stages, intermediate transitions need validation, and a final immutable value must not exist early. | All inputs arrive together; optional fields, fluent syntax, or a long initializer are the only pressure. | A memberwise or throwing initializer with focused value types. |
| [Prototype](../Creational%20Patterns/Prototype/README.md) | A reference-backed graph needs controlled independent duplication, runtime subtype preservation, identity remapping, and explicit resource sharing. | The model has value semantics or a normal initializer can reconstruct it without graph-copy rules. | Assignment for values or explicit construction for simple references. |
| [Singleton](../Creational%20Patterns/Singleton/README.md) | A process-wide resource has one accountable owner and a runtime-created callback cannot receive it through the normal composition root. | The shared lookup is merely convenient, or every consumer can receive the dependency explicitly. | Composition-root injection, registration, or isolated instances. |

The creation question is not “How many arguments are there?” It is “What rule does creation itself own?” Product selection, coherent families, staged construction, controlled copying, and constrained process ownership are five different change boundaries.

## Structural signals

| Pattern | Positive trigger | Reject the pattern when | Direct Swift baseline |
| --- | --- | --- | --- |
| [Adapter](../Structural%20Patterns/Adapter/README.md) | External providers expose incompatible requests, results, errors, or async contracts while the app needs one stable vocabulary. | One integration is simple and stable, or the app already understands the subsystem's interface. | Direct provider call plus local mapping. |
| [Bridge](../Structural%20Patterns/Bridge/README.md) | Two dimensions vary independently, combine at runtime, and otherwise multiply product types or branches. | Only one behavior family varies, or the second dimension is closed data with no independent change pressure. | An enum, switch, function, or Strategy for one axis. |
| [Composite](../Structural%20Patterns/Composite/README.md) | Clients need the same operation over a leaf and an arbitrarily nested part-whole hierarchy. | The structure is flat, traversal alone is the problem, or leaf and container behavior should remain visibly different. | Collections, recursion, or explicit enum cases. |
| [Decorator](../Structural%20Patterns/Decorator/README.md) | Independently selectable behaviors must compose around the same operation, every selected layer participates, and order changes policy. | Behavior is fixed, one substitute controls access, or processing should stop after one owner handles the request. | One function, explicit pipeline, or direct composition. |
| [Facade](../Structural%20Patterns/Facade/README.md) | Multiple entry points repeat the same multi-service operation and need one app-level boundary while lower-level capabilities remain available. | There is only one caller, no repeated orchestration, or the real issue is interface translation or ongoing peer coordination. | A focused orchestration function at the call site. |
| [Flyweight](../Structural%20Patterns/Flyweight/README.md) | Many unique objects repeat a small set of immutable resources, and measurement proves meaningful identity or memory reduction. | Object count is the only evidence, shared data is mutable, or caching is speculative. | Ordinary values and platform caching. |
| [Proxy](../Structural%20Patterns/Proxy/README.md) | A substitute with the same operation must control access or lifecycle for one real subject without leaking that policy to clients. | The behavior should be independently composable, or the client can call the subject directly without duplicated policy. | A guard, focused wrapper function, or direct subject. |

Structural similarity is insufficient evidence. Wrapper-like shapes must still answer whether all layers run (Decorator), one substitute controls one subject (Proxy), or one ordered handler owns the request (Chain of Responsibility).

## Behavioral signals

| Pattern | Positive trigger | Reject the pattern when | Direct Swift baseline |
| --- | --- | --- | --- |
| [Chain of Responsibility](../Behavioral%20Patterns/Chain%20of%20Responsibility/README.md) | Independent handlers need explicit order, pass-through, and a first terminal handled or rejected decision. | Every step must run, order is irrelevant, or one known function owns the request. | An ordered loop or direct conditional routing. |
| [Command](../Behavioral%20Patterns/Command/README.md) | Operations from multiple entry points need portable intent, queueing, or operation-specific undo/redo state. | A direct call is sufficient or only complete-state restoration is required. | Functions or closures; Memento for opaque snapshots. |
| [Interpreter](../Behavioral%20Patterns/Interpreter/README.md) | Users need a bounded language whose grammar, grouping, and positioned diagnostics are product behavior. | Independent filters or typed query values suffice; complex precedence, recovery, or open-ended syntax needs maintained parser infrastructure. | Predicates, enums, typed filters, or a parser library. |
| [Iterator](../Behavioral%20Patterns/Iterator/README.md) | Consumers need lazy ordered values while pagination, cursor progress, cancellation, or retries remain hidden. | Data is already materialized, one loop is enough, or uniform part-whole behavior is the actual need. | A collection, sequence, or direct async loop. |
| [Mediator](../Behavioral%20Patterns/Mediator/README.md) | Peers react to one another over time and cross-section consequences require one owner for ordering and consistency. | A single external operation is enough, or components do not have growing peer-to-peer dependencies. | Direct callbacks or a focused orchestration function. |
| [Memento](../Behavioral%20Patterns/Memento/README.md) | An owner must create and restore opaque, versioned snapshots while keeping its private schema hidden. | Public persistence or migration is required, or operation-specific intent is the real history. | Value snapshots, `Codable` persistence, or Command. |
| [Observer](../Behavioral%20Patterns/Observer/README.md) | Multiple consumers have independent lifetimes and need current state plus subsequent confirmed changes. | Receivers are fixed, delivery is local and synchronous, or native Observation already supplies the needed semantics. | Direct callbacks, Observation, or a native notification mechanism. |
| [State](../Behavioral%20Patterns/State/README.md) | Valid transitions, available actions, and worker behavior change together according to event history. | A closed enum and reducer keep transitions local, or the caller deliberately selects the behavior. | An enum state machine or pure reducer. |
| [Strategy](../Behavioral%20Patterns/Strategy/README.md) | A caller-selected policy varies independently with its own data, direction, fallback, or tie-breaking rules. | Policies are closed and local, or behavior is selected by lifecycle history rather than by the caller. | An enum switch or injected function. |
| [Template Method](../Behavioral%20Patterns/Template%20Method/README.md) | Several workflows repeat the same safety-critical order while only narrow steps vary. | The order is easy to review in ordinary functions, or the whole algorithm rather than one step must vary. | Shared functions plus explicit provider-specific calls. |
| [Visitor](../Behavioral%20Patterns/Visitor/README.md) | Operations grow frequently across a stable set of element kinds, and each operation needs exhaustive type-specific behavior. | Element kinds change frequently, one operation is local, or traversal—not double dispatch—is the problem. | Enum switches, protocol requirements, or collection transforms. |

## Required neighbour checks

Before choosing among commonly confused patterns, ask the discriminating question rather than comparing their class diagrams:

| Candidate group | Discriminating question |
| --- | --- |
| Simple Factory / Factory Method / Abstract Factory | Is the change central selection, creator-owned construction inside a workflow, or selection of a coherent product family? |
| Builder / State | Are transitions constructing a value that does not exist yet, or changing the behavior of an existing context? |
| Strategy / State / Bridge | Does the caller choose one policy, does event history choose behavior, or do two independent dimensions combine? |
| Decorator / Proxy / Chain of Responsibility | Must all selected wrappers run, must one substitute govern a subject, or must one handler make the terminal decision? |
| Command / Memento | Must history preserve intent and reversal data, or an opaque snapshot of complete owner state? |
| Adapter / Facade / Mediator | Is the boundary translating incompatible vocabulary, simplifying a subsystem entry point, or coordinating peer reactions over time? |
| Composite / Iterator / Visitor | Is the need uniform part-whole behavior, controlled production order, or new operations over stable element kinds? |
| Template Method / Strategy / Factory Method | Is one step inside a fixed algorithm varying, the whole behavior replaceable, or one product created inside a workflow? |

## Decision record contract for the future skill

A useful recommendation should be reviewable without trusting the pattern name. It must report:

- the observed app pressure and its evidence;
- the direct Swift design that should be tried or retained;
- the verdict: one pattern, no pattern yet, or insufficient evidence;
- the responsibility the pattern would move and the complexity it adds;
- the closest alternative and the discriminating reason it loses; and
- the concrete requirement that would reverse the verdict.

The skill must not recommend several patterns as a menu when the evidence can distinguish them. When evidence cannot distinguish them, it should request the missing fact instead of inventing one.

## Scope boundary and next evidence

This extraction changes no production code and does not initialize the skill. It gives Day 093 a tested catalogue vocabulary from which to design independent prompts for Adapter, State, no-pattern, and Bridge-versus-Strategy decisions. Those scenarios and their expected evaluation criteria have not been written yet.
