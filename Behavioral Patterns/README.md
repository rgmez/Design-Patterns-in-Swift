# 🧠 Behavioral Patterns

Coordinate behavior and change when the app problem is about routing, history, interpretation, iteration, state, or collaboration.

[← Pattern catalogue](../README.md#pattern-catalogue) · [Quickstart](../README.md#quickstart) · [No-pattern decision](../Documentation/no-pattern-decision.md) · [Creational](../Creational%20Patterns/README.md) · [Structural](../Structural%20Patterns/README.md)

<a id="how-to-use-this-category"></a>

## 🧭 How to use this category

Start with the direct baseline, then follow the guide's turning point to see which behavior changes and which invariant needs one owner.

Recommended route: [Strategy](Strategy/README.md) → [Observer](Observer/README.md) → [State](State/README.md).

Use [Command](Command/README.md) when operations need durable intent or reversal data, [Iterator](Iterator/README.md) when lazy production must hide pagination, and [Visitor](Visitor/README.md) when operations grow faster than a stable element family.

<a id="pattern-catalogue"></a>

## 📚 Pattern catalogue

### 🔗 [Chain of Responsibility](Chain%20of%20Responsibility/README.md)

- **Use it when:** Ordered handlers own separate features and processing stops after one handles or rejects the request.
- **Keep it simple when:** One function owns the request or every processing step must run.

### 🎮 [Command](Command/README.md)

- **Use it when:** Operations need durable intent, queueing, or operation-specific reversal data.
- **Keep it simple when:** Direct invocation works or restoring complete state is the real requirement.

### 🧩 [Interpreter](Interpreter/README.md)

- **Use it when:** Users author a bounded language whose structure must be parsed, inspected, and evaluated.
- **Keep it simple when:** Filters remain atomic; use maintained parser infrastructure if nesting, precedence, escaping, or recovery becomes real.

### 🔁 [Iterator](Iterator/README.md)

- **Use it when:** Lazy production must hide pagination progress while preserving order and cancellation.
- **Keep it simple when:** Data is already materialized or one loop owns the complete traversal.

### 🔀 [Mediator](Mediator/README.md)

- **Use it when:** Independently owned peers react bidirectionally and one boundary must own their ordering invariant.
- **Keep it simple when:** Coordination is one-way, one external operation is enough, or participants are not independently owned.

### 📸 [Memento](Memento/README.md)

- **Use it when:** An external caretaker must retain opaque, versioned, atomically restorable state.
- **Keep it simple when:** The model is already public, one previous value is enough, or durable storage needs an explicit document format.

### 👀 [Observer](Observer/README.md)

- **Use it when:** Consumers appear and disappear independently and must cancel without source-specific removal code.
- **Keep it simple when:** One local closure or one observable UI model already owns delivery.

### 🚦 [State](State/README.md)

- **Use it when:** Several behavior families change together with internal history and need one phase owner.
- **Keep it simple when:** Transitions are the only varying behavior or a few enum computed properties remain cohesive.

### ♟️ [Strategy](Strategy/README.md)

- **Use it when:** The caller selects one interchangeable policy that owns its inputs and tie-breaking rules.
- **Keep it simple when:** Policies are fixed or lifecycle history selects behavior.

### 🛤️ [Template Method](Template%20Method/README.md)

- **Use it when:** A closed nominal family must share one non-overridable algorithm with one narrow varying step.
- **Keep it simple when:** Call-site closures, value semantics, or external provider injection are more useful than a class hierarchy.

### 🔎 [Visitor](Visitor/README.md)

- **Use it when:** Operations grow faster than a stable element family and each operation needs cohesive state or results.
- **Keep it simple when:** Element kinds change frequently, behavior is intrinsic, or a small fold removes the repetition.

<a id="category-boundary"></a>

## 🎯 Category boundary

Behavioral patterns coordinate responsibilities and changing behavior over time. They do not replace a direct enum, function, callback, or value model while the behavior remains small, closed, and locally owned.

<a id="evidence-and-references"></a>

## 🔗 Evidence and references

[Source examples](../Sources/DesignPatterns/) · [Tests](../Tests/DesignPatternsTests/) · [README experience](../Documentation/readme-experience.md)
