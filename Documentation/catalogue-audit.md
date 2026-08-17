# Design Pattern Catalogue Audit

Baseline date: 2026-08-17

This audit records what the repository can prove today. A directory name does
not count as a completed pattern: the example must demonstrate the pattern's
intent, compile as part of the repository, be tested, and explain why the added
structure is worthwhile in Swift.

## Executive summary

- The target catalogue contains all 23 Gang of Four patterns.
- Six patterns currently have a named example area: Factory Method, Abstract
  Factory, Builder, Prototype, Adapter, and Bridge.
- Seventeen patterns have no canonical example area yet. Strategy has a
  candidate implementation, but it is currently misclassified under Bridge.
- None of the six existing areas meets the programme's Definition of Done.
- Adapter has the clearest pattern structure and can be rebuilt around a real
  integration.
- Builder and Prototype are structurally recognizable, but their examples do
  not demonstrate enough pressure to justify the patterns in Swift.
- Factory Method, Abstract Factory, and Bridge need conceptual replacements.
- All eight Swift files type-check in isolation. One emits a deprecation
  warning, and the files cannot compile together because of top-level code and
  repeated declarations.
- There is no Swift Package, automated test target, or CI configuration.

This is a teaching audit, not a deletion list. Existing examples remain as
historical inputs until a tested and documented replacement is ready.

## Status definitions

| Status | Meaning | Required response |
| --- | --- | --- |
| Rebuild | The pattern's core relationship is visible, but the domain and evidence are too weak. | Preserve the useful shape and replace the scenario, behavior, tests, and documentation. |
| Reframe | The code resembles the named pattern, but Swift offers a materially simpler default that is not discussed. | Start from direct Swift, demonstrate the pressure, then retain only justified structure. |
| Replace | The implementation teaches a different pattern or omits the defining relationship. | Keep history, but create a new canonical example and clearly name the old construction. |
| Missing | No canonical implementation and README exist for the pattern. | Add it only during its scheduled three-day cycle. |

## Existing examples

### Factory Method — Replace

The documentation describes Factory Method as allowing subclasses to choose
the created product, but the implementation has no creator hierarchy and no
overridable creation operation. `TaskFactory.createTask` is a static method with
a centralized `switch` over `TaskType`.

Evidence:

- [`TaskFactory.createTask`](../Creational%20Patterns/Factory/TaskFactory.swift#L76-L92)
  is a Simple Factory.
- Adding a product requires editing the `switch`, despite the documentation's
  extensibility claim in
  [`TaskFactory.md`](../Creational%20Patterns/Factory/TaskFactory.md#L14-L18).
- Optional `deadline` data is accepted for every case and silently replaced
  with an empty string for deadline tasks.

Decision: name the current construction Simple Factory in historical context.
Build the canonical Factory Method example around import workflows where each
provider owns the creation of its parser.

### Abstract Factory — Replace

The example exposes several creation methods, but it has only one concrete
factory. `SimpleTask`, `RecurringTask`, and `DeadlineTask` are alternative
products of one kind, not members of multiple coherent product families.

Evidence:

- [`TaskFactoryProtocol`](../Creational%20Patterns/Abstract%20Factory/TaskAbstractFactory.swift#L74-L79)
  declares three task constructors.
- [`TaskFactory`](../Creational%20Patterns/Abstract%20Factory/TaskAbstractFactory.swift#L81-L104)
  is the only factory implementation.
- [`TaskManager.createTask`](../Creational%20Patterns/Abstract%20Factory/TaskAbstractFactory.swift#L116-L141)
  repeats centralized product selection with another `switch`.
- The documentation claims that the system supports multiple families, but no
  second family can be selected or validated.

Decision: replace it with at least two complete service families whose members
must not be mixed, such as coherent tenant or brand configurations.

### Builder — Reframe

The fluent construction syntax is recognizable, but the example builds one
flat value with no validation, ordering constraint, conditional assembly, or
alternative representation. A Swift initializer with defaults would currently
be smaller and clearer.

Evidence:

- [`Task`](../Creational%20Patterns/Builder/TaskBuilder.swift#L1-L10) is a flat
  six-property value.
- [`TaskBuilder`](../Creational%20Patterns/Builder/TaskBuilder.swift#L34-L86)
  stores mutable defaults and always returns the same representation.
- `TaskBuilderProtocol` returns the concrete `TaskBuilder` type and does not
  include `setType`, so the protocol adds indirection without forming a useful
  abstraction boundary.
- Required domain data can become placeholder strings such as `"No Deadline"`
  and `"Unassigned"` instead of producing explicit validation errors.

Decision: begin with an initializer. Introduce Builder later only if multipart
request or checkout assembly demonstrates conditional steps and validation that
the initializer cannot communicate clearly.

### Prototype — Reframe

The implementation performs explicit cloning and preserves a subclass, but it
does not explain why ordinary Swift value copying is insufficient. Its payload
contains strings, enums, and an array of strings, so it never demonstrates the
reference-sharing problem that would justify controlled deep copying.

Evidence:

- The comment says “Base struct”, while
  [`Task`](../Creational%20Patterns/Prototype/TaskPrototype.swift#L16-L44) is a
  class.
- [`Prototype.md`](../Creational%20Patterns/Prototype/Prototype.md#L25-L28) says
  the example uses a `Task` struct, contradicting the implementation.
- `clone()` returns the protocol type, forcing downcasts in the usage example.
- The example does not contain an expensive creation step or a nested mutable
  reference whose ownership must be separated.

Decision: teach assignment and copy-on-write value semantics first. Retain an
explicit Prototype only around a document reference graph that needs controlled
deep copies and subtype preservation.

### Adapter — Rebuild

This is the strongest current skeleton: a target protocol, an incompatible
adaptee, and an adapter are all visible. The scenario remains too synthetic to
show the boundary pressure of a real SDK.

Evidence:

- [`Task`](../Structural%20Patterns/Adapter/ExternalTaskAdapter.swift#L1-L6) is
  the target interface.
- [`ExternalTaskService`](../Structural%20Patterns/Adapter/ExternalTaskAdapter.swift#L8-L25)
  is the adaptee.
- [`ExternalTaskAdapter`](../Structural%20Patterns/Adapter/ExternalTaskAdapter.swift#L27-L47)
  maps the names and operation into the target.
- The “third-party” type lives in the same file, has no vendor-specific errors
  or asynchronous contract, and maps `performTask()` to `markAsComplete()`
  without explaining the semantic decision.

Decision: preserve the relationship, but rebuild it around a payment or
analytics integration with incompatible request, result, and error types.

### Bridge — Replace

The directory contains three different dependency-composition examples rather
than one clear demonstration of two dimensions that evolve independently.

Evidence:

- [`TaskExecutionModes.swift`](../Structural%20Patterns/Bridge/TaskExecutionModes.swift#L11-L62)
  swaps execution behavior around one `GenericTask`; this is closer to Strategy
  than a demonstrated abstraction hierarchy crossed with an implementation
  hierarchy.
- Both execution implementations are `async`, despite being named synchronous
  and asynchronous.
- [`TaskNotificationMechanisms.swift`](../Structural%20Patterns/Bridge/TaskNotificationMechanisms.swift#L25-L58)
  is the most promising composition, but it has one task type and never shows
  two independently growing axes.
- [`TaskPriorityManagement.swift`](../Structural%20Patterns/Bridge/TaskPriorityManagement.swift#L31-L75)
  selects priority algorithms. Its own usage comment calls them strategies, so
  it is a Strategy candidate, not a Bridge example.
- The Bridge README presents all three examples as equivalent and repeats the
  Open/Closed Principle as two separate characteristics.

Decision: replace the three competing narratives with one notification example
that has two explicit axes, such as notification purpose and delivery channel.
Use the priority resolver only as input when the canonical Strategy cycle
starts; do not silently relabel it as complete.

## Complete GoF catalogue

| Category | Pattern | Baseline status | Planned days |
| --- | --- | --- | --- |
| Creational | Factory Method | Replace — current code is Simple Factory | 018–020 |
| Creational | Abstract Factory | Replace — no alternative product families | 022–024 |
| Creational | Builder | Reframe — direct initializer not evaluated | 025–027 |
| Creational | Prototype | Reframe — Swift value semantics not evaluated | 029–031 |
| Creational | Singleton | Missing | 085–087 |
| Structural | Adapter | Rebuild — valid skeleton, synthetic integration | 008–010 |
| Structural | Bridge | Replace — Strategy-like examples, no proven two-axis growth | 015–017 |
| Structural | Composite | Missing | 064–066 |
| Structural | Decorator | Missing | 046–048 |
| Structural | Facade | Missing | 043–045 |
| Structural | Flyweight | Missing | 074–076 |
| Structural | Proxy | Missing | 050–052 |
| Behavioral | Chain of Responsibility | Missing | 053–055 |
| Behavioral | Command | Missing | 039–041 |
| Behavioral | Interpreter | Missing | 081–083 |
| Behavioral | Iterator | Missing | 060–062 |
| Behavioral | Mediator | Missing | 067–069 |
| Behavioral | Memento | Missing | 057–059 |
| Behavioral | Observer | Missing | 032–034 |
| Behavioral | State | Missing | 036–038 |
| Behavioral | Strategy | Missing — candidate misclassified under Bridge | 011–013 |
| Behavioral | Template Method | Missing | 071–073 |
| Behavioral | Visitor | Missing | 078–080 |

## Duplication and integration blockers

The files behave like isolated playgrounds rather than one repository that can
be built as a unit.

- `Task` is independently declared in five files and `TaskType` in four.
- Factory Method and Abstract Factory duplicate `SimpleTask`, `RecurringTask`,
  `DeadlineTask`, and most usage data.
- All three Bridge files redeclare `MyTask`; two also duplicate
  `ReportGenerationMyTask`.
- Two Bridge files declare a top-level `main()` and launch unstructured tasks.
- Several files execute sample code at the top level, which prevents them from
  sharing a normal library target.

A combined type-check fails with invalid redeclarations, ambiguous type lookup,
and top-level-expression errors. Day 003 must introduce a package boundary and
namespacing strategy without creating one target per tiny type.

## Build and behavior baseline

Each of the eight Swift files was checked independently with:

```sh
swiftc -module-cache-path /private/tmp/design-patterns-swift-module-cache \
  -typecheck <example.swift>
```

Results:

- 8 of 8 files passed type-check in isolation.
- `TaskExecutionModes.swift` emitted a deprecation warning for
  `Task.sleep(_:)`; warnings are failures under the programme's Definition of
  Done.
- A single invocation containing all eight files failed because the examples
  do not share a compilable boundary.
- Running `TaskExecutionModes.swift` exited after the asynchronous operation
  started, before the task finished.
- Running `TaskNotificationMechanisms.swift` exited after report generation
  started, before either notification was sent.
- Running `TaskPriorityManagement.swift` produced no behavior because
  `priorityExample()` is never invoked.

There is currently no `Package.swift`, `Tests/`, or `.github/` directory.
Behavior is demonstrated through `print` statements rather than assertions.

## Documentation baseline

- The root README lists 18 of the 23 GoF patterns. Singleton, Chain of
  Responsibility, Interpreter, Iterator, and Template Method are absent.
- Twelve listed patterns point to `#` placeholders.
- The Factory Method, Abstract Factory, and Adapter link labels name Swift files
  that do not match their linked documentation or actual filenames.
- The license link points to `LICENSE.md`, but the repository contains
  `LICENSE`.
- Existing pattern documents are named inconsistently and none is the canonical
  per-directory `README.md` required by the roadmap.
- No pattern document includes verified run commands, tests, an explicit
  “When not to use it” section, an explanatory diagram, or an approved RG
  editorial header.
- Most explanations begin with generic definitions rather than the concrete app
  problem and the simpler Swift alternative.

These issues will be corrected incrementally. A mass rename now would create a
large link migration before package and documentation conventions exist.

## Decisions carried forward

1. Do not count directories or type-check success as pattern completion.
2. Start every rewrite from a real requirement and a direct Swift solution.
3. Preserve old examples until their tested replacement is ready.
4. Use one canonical example and README per pattern; avoid several weak variants.
5. Treat “no pattern” as a valid documented result.
6. Delay broad renames until the package and README templates define stable
   boundaries.
7. Keep LinkedIn drafts local and outside Git; posts may report only evidence
   captured by completed repository work.

The next step is Day 003: create the smallest Swift Package boundary that lets
examples compile together without turning every pattern into its own framework.
