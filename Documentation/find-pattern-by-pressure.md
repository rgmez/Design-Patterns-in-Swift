# Find a Pattern by Pressure

[← Repository overview](../README.md) · [Pattern catalogue](../README.md#pattern-catalogue) · [No-pattern decision](no-pattern-decision.md) · [Decision skill](../.codex/skills/choose-swift-design-pattern/SKILL.md)

Start from what is currently difficult in the app, not from the pattern name you want to use.

Before following any link, confirm four facts:

1. A current requirement creates observable pressure.
2. The direct Swift or platform solution has a named failure mode.
3. The proposed boundary moves responsibility to a clearer owner.
4. A test, type constraint, ownership rule, or measurement can verify the improvement.

If one fact is missing, choose **no pattern yet** or **insufficient evidence**.

## External systems and access

- **Two SDKs disagree on requests, results, errors, or async contracts** → [Adapter](../Structural%20Patterns/Adapter/README.md). Keep a direct mapping while one integration is simple and stable.
- **Several clients repeat the same multi-service choreography** → [Facade](../Structural%20Patterns/Facade/README.md). Keep orchestration at the call site while one caller owns it.
- **One subject needs access checks, lazy setup, or bounded lifecycle control behind the same operation** → [Proxy](../Structural%20Patterns/Proxy/README.md). Keep a guard or wrapper function while direct access remains clear.

## Creation and identity

- **Independently selected services can form invalid families** → [Abstract Factory](../Creational%20Patterns/Abstract%20Factory/README.md). Keep one typed composition function while the family is closed.
- **Inputs arrive in ordered stages and partial construction has validation rules** → [Builder](../Creational%20Patterns/Builder/README.md). Keep a throwing initializer when inputs arrive together.
- **Each workflow must own preparation and the product it creates** → [Factory Method](../Creational%20Patterns/Factory%20Method/README.md). Keep a switch or creation closure when only selection varies.
- **A reference graph needs controlled independent copying and identity remapping** → [Prototype](../Creational%20Patterns/Prototype/README.md). Prefer value assignment or reconstruction for value-only models.
- **One process identity must cross a construction root that cannot inject it** → [Singleton](../Creational%20Patterns/Singleton/README.md). Inject one actor everywhere else and remove the shared path when registration becomes possible.

## Behavior and lifecycle

- **The caller selects one policy with independently changing rules or inputs** → [Strategy](../Behavioral%20Patterns/Strategy/README.md). Keep an enum or function for closed local policies.
- **Event history selects legal actions, transitions, and worker behavior** → [State](../Behavioral%20Patterns/State/README.md). Keep an enum reducer while transitions are the only varying behavior.
- **Two dimensions vary and combine independently** → [Bridge](../Structural%20Patterns/Bridge/README.md). Use Strategy when only one behavior family varies.
- **Several workflows must preserve one safety-critical order while one narrow step varies** → [Template Method](../Behavioral%20Patterns/Template%20Method/README.md). Prefer a private higher-order function when closures make the variation clearer.

## Events, coordination, and history

- **Consumers need current state and later changes with independent lifetimes** → [Observer](../Behavioral%20Patterns/Observer/README.md). Prefer Observation or one callback when the receiver set is fixed.
- **Peer modules react to one another and one owner must resolve their ordering invariant** → [Mediator](../Behavioral%20Patterns/Mediator/README.md). Keep direct callbacks while interaction is one-way.
- **Ordered independent handlers need pass-through and one terminal owner** → [Chain of Responsibility](../Behavioral%20Patterns/Chain%20of%20Responsibility/README.md). Keep one loop while one function still owns routing.
- **Operations need portable intent, queueing, or operation-specific undo data** → [Command](../Behavioral%20Patterns/Command/README.md). Use direct calls when invocation is immediate; use Memento when complete-state restoration is the requirement.
- **An external caretaker must retain opaque snapshots without learning private state** → [Memento](../Behavioral%20Patterns/Memento/README.md). Keep value snapshots or a private bounded array while history stays with one owner.

## Traversal, language, and structure

- **Lazy ordered production must hide cursor progress, cancellation, or remote page boundaries** → [Iterator](../Behavioral%20Patterns/Iterator/README.md). Keep a collection or one async loop when data is already materialized.
- **Users author a bounded language with grouping and positioned diagnostics** → [Interpreter](../Behavioral%20Patterns/Interpreter/README.md). Keep typed filters for independent atoms and adopt maintained parser infrastructure when grammar mechanics grow.
- **Clients need one operation over leaves and arbitrarily nested containers** → [Composite](../Structural%20Patterns/Composite/README.md). Keep explicit recursion while the structure is small or traversal is the real concern.
- **Selectable behaviors compose around one operation and every chosen layer must run** → [Decorator](../Structural%20Patterns/Decorator/README.md). Keep a fixed pipeline while selection and ordering do not vary.
- **Operations grow across a stable family of element kinds** → [Visitor](../Behavioral%20Patterns/Visitor/README.md). Keep exhaustive enum switches while operations remain few or element kinds change frequently.

## Measured resource pressure

- **Many live contexts repeat a small immutable payload with a verified cost** → [Flyweight](../Structural%20Patterns/Flyweight/README.md). Prefer platform caching or direct values until identity and payload repetition are measured in the real boundary.

## When no pattern wins

Keep the direct design when a value type, enum, function, initializer, actor, `AsyncSequence`, Observation model, or platform API already owns the behavior without duplicated state or indirection.

The [product-share URL case](no-pattern-decision.md) demonstrates that result, and the [`choose-swift-design-pattern` skill](../.codex/skills/choose-swift-design-pattern/SKILL.md) applies the same evidence gate to new app problems.
