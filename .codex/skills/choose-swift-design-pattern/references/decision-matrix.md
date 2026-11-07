# GoF Decision Matrix

Use this compact matrix to locate a plausible boundary after the direct Swift
baseline has been considered. Open a canonical README when implementation
details or pattern-specific trade-offs matter; the matrix is a discriminator,
not a substitute for the evidence gate.

## Creational

| Pattern | Observable pressure that earns it | Direct Swift baseline | Reject when | Canonical guide |
| --- | --- | --- | --- | --- |
| Factory Method | Each provider owns preparation and creation inside one extensible workflow. | Switch or injected creation closure. | Only selection varies, or creation is unrelated to a workflow. | [Factory Method](../../../../Creational%20Patterns/Factory%20Method/README.md) |
| Abstract Factory | Related products must be selected as one coherent family. | One composition function returning typed values. | The family is closed or only one product varies. | [Abstract Factory](../../../../Creational%20Patterns/Abstract%20Factory/README.md) |
| Builder | Ordered inputs need validation before a final immutable value exists. | Throwing or memberwise initializer. | Inputs arrive together; only optional fields or fluent syntax motivate it. | [Builder](../../../../Creational%20Patterns/Builder/README.md) |
| Prototype | A reference graph needs controlled independent copying and identity remapping. | Value assignment or explicit construction. | Value semantics or a normal initializer already reconstructs it. | [Prototype](../../../../Creational%20Patterns/Prototype/README.md) |
| Singleton | One accountable process-wide owner cannot enter a runtime-created callback normally. | Composition-root injection or registration. | Shared lookup is merely convenient or injection is available. | [Singleton](../../../../Creational%20Patterns/Singleton/README.md) |

## Structural

| Pattern | Observable pressure that earns it | Direct Swift baseline | Reject when | Canonical guide |
| --- | --- | --- | --- | --- |
| Adapter | External interfaces disagree on requests, results, errors, or async contracts. | Direct call plus local mapping. | One integration is simple and stable. | [Adapter](../../../../Structural%20Patterns/Adapter/README.md) |
| Bridge | Two dimensions vary independently and otherwise multiply product types. | Enum, switch, function, or one-axis Strategy. | Only one behavior family varies. | [Bridge](../../../../Structural%20Patterns/Bridge/README.md) |
| Composite | Clients need one operation over leaves and arbitrarily nested part-whole structures. | Collections, recursion, or explicit enum cases. | The structure is flat or traversal is the real problem. | [Composite](../../../../Structural%20Patterns/Composite/README.md) |
| Decorator | Selectable behaviors compose around one operation and order changes policy. | One function or explicit pipeline. | Behavior is fixed, access is the concern, or processing must stop at one owner. | [Decorator](../../../../Structural%20Patterns/Decorator/README.md) |
| Facade | Repeated multi-service orchestration needs one app-level entry point. | Focused orchestration at the call site. | There is one caller or the issue is translation or peer coordination. | [Facade](../../../../Structural%20Patterns/Facade/README.md) |
| Flyweight | Measurement shows many objects repeat immutable resources with meaningful memory or identity cost. | Ordinary values and platform caching. | Object count alone motivates speculative sharing. | [Flyweight](../../../../Structural%20Patterns/Flyweight/README.md) |
| Proxy | A same-operation substitute must control access or lifecycle for one subject. | Guard or focused wrapper function. | Behavior should compose independently or direct access is sufficient. | [Proxy](../../../../Structural%20Patterns/Proxy/README.md) |

## Behavioral

| Pattern | Observable pressure that earns it | Direct Swift baseline | Reject when | Canonical guide |
| --- | --- | --- | --- | --- |
| Chain of Responsibility | Ordered independent handlers need pass-through and one terminal decision. | Ordered loop or conditional routing. | Every step must run or one function owns the request. | [Chain of Responsibility](../../../../Behavioral%20Patterns/Chain%20of%20Responsibility/README.md) |
| Command | Operations need portable intent, queueing, or operation-specific undo data. | Function or closure. | Direct invocation suffices or complete-state restoration is required. | [Command](../../../../Behavioral%20Patterns/Command/README.md) |
| Interpreter | A bounded user language needs grammar, grouping, and positioned diagnostics. | Typed filters, predicates, or parser library. | Independent filter atoms suffice. | [Interpreter](../../../../Behavioral%20Patterns/Interpreter/README.md) |
| Iterator | Lazy ordered production must hide pagination, cursor progress, cancellation, or retries. | Collection, Sequence, or direct async loop. | Data is materialized or one loop is enough. | [Iterator](../../../../Behavioral%20Patterns/Iterator/README.md) |
| Mediator | Peers react over time and cross-component ordering needs one consistency owner. | Direct callbacks or focused orchestration. | A single external operation is enough. | [Mediator](../../../../Behavioral%20Patterns/Mediator/README.md) |
| Memento | An owner needs opaque, versioned snapshots while hiding its private schema. | Value snapshot or Codable persistence. | Public persistence or operation intent is required. | [Memento](../../../../Behavioral%20Patterns/Memento/README.md) |
| Observer | Independent-lifetime consumers need current state and later confirmed changes. | Direct callbacks, Observation, or native notifications. | Receivers are fixed or native Observation already fits. | [Observer](../../../../Behavioral%20Patterns/Observer/README.md) |
| State | Valid transitions, actions, and worker behavior change with event history. | Enum state machine or pure reducer. | A closed enum keeps transitions local or caller selects behavior. | [State](../../../../Behavioral%20Patterns/State/README.md) |
| Strategy | The caller selects an independently varying policy with its own rules. | Enum switch or injected function. | Policies are closed/local or lifecycle history selects behavior. | [Strategy](../../../../Behavioral%20Patterns/Strategy/README.md) |
| Template Method | Workflows share a safety-critical order while narrow steps vary. | Shared functions and explicit provider calls. | The order is easy to review or the whole algorithm varies. | [Template Method](../../../../Behavioral%20Patterns/Template%20Method/README.md) |
| Visitor | Operations grow over a stable set of element kinds. | Enum switch, protocol requirements, or transforms. | Element kinds change often or traversal is the problem. | [Visitor](../../../../Behavioral%20Patterns/Visitor/README.md) |
