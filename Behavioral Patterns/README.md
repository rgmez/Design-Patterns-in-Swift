# 🧠 Behavioral Patterns

Coordinate behavior and change when the app problem is about routing, history, interpretation, iteration, state, or collaboration.

[← Pattern catalogue](../README.md#pattern-catalogue) · [Quickstart](../README.md#quickstart) · [No-pattern decision](../Documentation/no-pattern-decision.md) · [Creational](../Creational%20Patterns/README.md) · [Structural](../Structural%20Patterns/README.md)

## How to use this category

Start with the direct baseline, then follow the guide's turning point to see which behavior changes and which invariant needs one owner.

Recommended route: [Strategy](Strategy/README.md) → [Observer](Observer/README.md) → [State](State/README.md).

Use [Command](Command/README.md) when operations need durable intent or reversal data, [Iterator](Iterator/README.md) when lazy production must hide pagination, and [Visitor](Visitor/README.md) when operations grow faster than a stable element family.

## Pattern catalogue

| Pattern | Use it when | Keep it simple when |
| --- | --- | --- |
| [Chain of Responsibility](Chain%20of%20Responsibility/README.md) | Ordered handlers own separate features and processing stops after one handles or rejects the request. | One function owns the request or every processing step must run. |
| [Command](Command/README.md) | Operations need durable intent, queueing, or operation-specific reversal data. | Direct invocation works or restoring complete state is the real requirement. |
| [Interpreter](Interpreter/README.md) | Users author a bounded language whose structure must be parsed, inspected, and evaluated. | Filters remain atomic; use maintained parser infrastructure if nesting, precedence, escaping, or recovery becomes real. |
| [Iterator](Iterator/README.md) | Lazy production must hide pagination progress while preserving order and cancellation. | Data is already materialized or one loop owns the complete traversal. |
| [Mediator](Mediator/README.md) | Independently owned peers react bidirectionally and one boundary must own their ordering invariant. | Coordination is one-way, one external operation is enough, or participants are not independently owned. |
| [Memento](Memento/README.md) | An external caretaker must retain opaque, versioned, atomically restorable state. | The model is already public, one previous value is enough, or durable storage needs an explicit document format. |
| [Observer](Observer/README.md) | Consumers appear and disappear independently and must cancel without source-specific removal code. | One local closure or one observable UI model already owns delivery. |
| [State](State/README.md) | Several behavior families change together with internal history and need one phase owner. | Transitions are the only varying behavior or a few enum computed properties remain cohesive. |
| [Strategy](Strategy/README.md) | The caller selects one interchangeable policy that owns its inputs and tie-breaking rules. | Policies are fixed or lifecycle history selects behavior. |
| [Template Method](Template%20Method/README.md) | A closed nominal family must share one non-overridable algorithm with one narrow varying step. | Call-site closures, value semantics, or external provider injection are more useful than a class hierarchy. |
| [Visitor](Visitor/README.md) | Operations grow faster than a stable element family and each operation needs cohesive state or results. | Element kinds change frequently, behavior is intrinsic, or a small fold removes the repetition. |

## Category boundary

Behavioral patterns coordinate responsibilities and changing behavior over time. They do not replace a direct enum, function, callback, or value model while the behavior remains small, closed, and locally owned.

## Evidence and references

[Source examples](../Sources/DesignPatterns/) · [Tests](../Tests/DesignPatternsTests/) · [README experience](../Documentation/readme-experience.md)
