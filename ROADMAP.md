# 100-Day Internal Roadmap: Pragmatic Design Patterns in Swift

This internal roadmap turns the repository into an executable, tested, visual
guide to the 23 Gang of Four design patterns without treating patterns as goals
by themselves or imposing the same cadence on the public series.

The series follows one rule:

> A pattern earns its place only when it solves a concrete problem more clearly
> than Swift's direct language and platform features.

Last updated: 2026-08-25

## Outcomes

By Day 100, the repository should provide:

- All 23 GoF patterns represented by realistic app scenarios.
- A runnable Swift Package with automated tests and warning-free builds.
- One canonical, explanatory `README.md` per pattern.
- A consistent RG editorial header and an accessible technical diagram per
  pattern.
- Explicit alternatives and a `When not to use it` section for every pattern.
- A private, Git-ignored English LinkedIn draft for each meaningful publication
  milestone, grounded in verified repository work.
- A reusable `choose-swift-design-pattern` Codex skill.

## Non-goals

- Applying every pattern to one artificial application.
- Adding protocols, layers, coordinators, repositories, or factories only to
  make an example look architectural.
- Recreating production infrastructure that does not help explain the pattern.
- Publishing unverified code or presenting a work in progress as complete.
- Publishing a LinkedIn post for every internal workday regardless of whether
  it contains a complete technical story.
- Tracking private editorial working files under `Editorial/` in Git.
- Automatically pushing, opening pull requests, publishing posts, or releasing
  tags without review.

## Daily operating rules

1. Work on exactly one roadmap day.
2. Start from the first unchecked day.
3. Keep the change small enough to review as one coherent commit.
4. Prefer direct Swift before introducing a pattern.
5. Base documentation and publication drafts only on verified behavior.
6. Stop when unrelated local changes, failed validation, or a scope-expanding
   decision requires human review.
7. Do not begin the next day early.

## Definition of Done for a day

A day can be checked only when every applicable item is true:

- The intended behavior or documentation outcome is explicit.
- The implementation uses the minimum structure needed for that outcome.
- Relevant builds and tests pass without warnings.
- Documentation matches the code and its commands have been checked.
- Visuals follow the approved RG system when the day includes a visual asset.
- When the day closes a publication milestone, its LinkedIn draft refers only
  to evidence produced or verified by completed roadmap work.
- The complete diff has been reviewed for unrelated changes.
- One focused English commit has been created using `New:`, `Fix:`, or
  `Update:`.

Review days additionally require a full build, full test suite, link review,
visual consistency review, and removal of avoidable abstractions.

## Three-day pattern cycle

Each pattern gets three focused days:

- **Day A — Problem:** define the real app pressure, direct solution, acceptance
  criteria, and initial visual thesis.
- **Day B — Pressure:** implement or document the direct solution and demonstrate
  the concrete requirement that makes it insufficient.
- **Day C — Pattern:** introduce the smallest justified pattern implementation,
  complete tests, `README.md`, editorial header, Mermaid diagram, alternatives,
  trade-offs, `When not to use it`, and one complete publication draft.

The direct implementation does not need to remain in the final source when the
documentation and Git history explain the evolution more clearly.

## Pattern inventory

The initial canonical target is the complete GoF catalogue:

- **Creational:** Abstract Factory, Builder, Factory Method, Prototype,
  Singleton.
- **Structural:** Adapter, Bridge, Composite, Decorator, Facade, Flyweight,
  Proxy.
- **Behavioral:** Chain of Responsibility, Command, Interpreter, Iterator,
  Mediator, Memento, Observer, State, Strategy, Template Method, Visitor.

Existing files are historical inputs, not automatically accepted examples.
Factory Method, Abstract Factory, Bridge, Builder, and Prototype require a
conceptual review before being marked as complete.

The 23 GoF patterns are a first milestone, not a permanent boundary. A modern
Swift, concurrency, Apple-platform, or architectural pattern may be added later
only when a real app problem demonstrates its value under the same decision
criteria. Any expansion must be visible in a reviewed roadmap change; catalogue
size is never a goal by itself.

## Publication cadence

The 100 roadmap days are small internal work units. They are deliberately
independent from the public series: daily progress does not create an obligation
to publish daily.

- Public entries use `Day N` as a series sequence, not as elapsed calendar days.
- Drafts live only under the Git-ignored `Editorial/series/` directory.
- Publication remains manual after review, with a target cadence of two or three
  posts per week rather than a fixed daily promise.
- An internal day without a complete, useful story produces no LinkedIn draft.

The initial publication map contains approximately 29 posts:

| Public entry | Internal trigger | Story |
| --- | --- | --- |
| Day 0 | Before the programme | Introduce the repository, the initial 23-pattern milestone, and the no-overengineering rule. |
| Day 1 | Day 007 | Explain the verified baseline and the foundation built before the first rewrite. |
| Days 2–24 | Each pattern's Day C | Publish one complete problem-to-trade-offs story for each GoF pattern. |
| Day 25 | Day 090 | Show a real case where the direct Swift solution wins and no named pattern is added. |
| Day 26 | Day 091 | Review the complete initial catalogue and the distinctions that prevented misclassification. |
| Day 27 | Day 098 | Explain how repository evidence became the `choose-swift-design-pattern` skill. |
| Day 28 | Day 100 | Share the retrospective, rejected abstractions, and possible next patterns. |

This map may shrink, merge, or grow when the technical story requires it. It is
an editorial guide, not a content quota.

## Daily schedule

### Week 1 — Foundation

- [x] **Day 001 — Establish the programme.** Create the 100-day internal
  roadmap, operating rules, and Definition of Done. Day 0 remains a separate
  private launch draft.
- [x] **Day 002 — Audit the current catalogue.** Record implemented, missing,
  misclassified, duplicated, and undocumented patterns with file-level evidence
  in the [baseline audit](Documentation/catalogue-audit.md).
- [x] **Day 003 — Create the package boundary.** Introduce the smallest Swift
  Package structure that can compile examples together without target explosion,
  documented in the [package boundary](Documentation/package-boundary.md).
- [x] **Day 004 — Make behavior verifiable.** Add the initial test target and CI
  checks for build, tests, and compiler warnings, documented in the
  [quality gates](Documentation/quality-gates.md).
- [x] **Day 005 — Standardize teaching units.** Define the
  [pattern README template](Documentation/pattern-readme-template.md),
  [visual style contract](Documentation/visual-style.md), approved Adapter
  reference, and RG logo asset.
- [x] **Day 006 — Map realistic app domains.** Assign each pattern a credible
  commerce, editor, integration, content, media, or system scenario in the
  [real-app domain map](Documentation/app-domain-map.md).
- [x] **Day 007 — Foundation review.** Run all available checks, repair links,
  remove avoidable structure, confirm readiness for the first pattern, and
  prepare the first evidence-based public-series draft. Evidence is recorded
  in the [foundation review](Documentation/foundation-review.md).

### Week 2 — Adapter and Strategy

- [x] **Day 008 — Adapter problem.** Define an incompatible external payment or
  analytics SDK boundary, direct integration, and acceptance tests.
  The [payment SDK problem](Documentation/adapter-problem.md) fixes the first
  vendor contract and the evidence required before introducing an adapter.
- [x] **Day 009 — Adapter pressure.** Demonstrate how vendor types and errors leak
  into the app when the second integration requirement arrives. The
  [pressure review](Documentation/adapter-pressure.md) records the direct,
  executable two-provider branch and the coupling it exposes.
- [x] **Day 010 — Adapter solution.** Implement the minimal adapter, tests,
  canonical README, RG header, Mermaid diagram, and trade-offs. The [canonical
  Adapter guide](Structural%20Patterns/Adapter/README.md) keeps provider
  translation outside checkout.
- [x] **Day 011 — Strategy problem.** Define runtime-selectable pricing or
  shipping policies and a direct implementation. The [delivery promise
  problem](Documentation/strategy-problem.md) proves the enum-and-function
  baseline before any Strategy boundary exists.
- [x] **Day 012 — Strategy pressure.** Show the requirement that makes growing
  conditionals harder to test and vary independently. The [pressure review](Documentation/strategy-pressure.md)
  adds a partner-sponsored ranking policy with independently supplied campaign
  data while deliberately retaining the direct switch.
- [x] **Day 013 — Strategy solution.** Implement the minimal strategy boundary
  and explain when an enum or function remains better. The [canonical Strategy
  guide](Behavioral%20Patterns/Strategy/README.md) uses one value type to make
  delivery ranking policies interchangeable without a protocol hierarchy.
- [x] **Day 014 — Weekly review.** Validate Adapter and Strategy together and
  compare Strategy with State and Bridge. The [review evidence](Documentation/week-02-review.md)
  confirms both examples remain minimal, warning-free, visually consistent, and
  correctly classified.

### Week 3 — Bridge and Factory Method

- [x] **Day 015 — Bridge problem.** Define two independently changing axes in a
  real notification scenario. The [notification problem baseline](Documentation/bridge-problem.md)
  keeps the nine-case direct switch executable before Bridge is considered.
- [ ] **Day 016 — Bridge pressure.** Demonstrate the product-type by channel
  combination growth without introducing a class explosion.
- [ ] **Day 017 — Bridge solution.** Implement and document the two-axis bridge
  with executable asynchronous behavior.
- [ ] **Day 018 — Factory Method problem.** Define import workflows in which each
  provider must choose its parser.
- [ ] **Day 019 — Factory Method pressure.** Contrast the extension pressure with
  a centralized Simple Factory switch.
- [ ] **Day 020 — Factory Method solution.** Implement the minimal factory method
  and document its distinction from Simple and Abstract Factory.
- [ ] **Day 021 — Weekly review.** Validate Bridge and Factory Method and remove
  any Strategy-like or factory-like misclassification.

### Week 4 — Abstract Factory and Builder

- [ ] **Day 022 — Abstract Factory problem.** Define two coherent service
  families for real app brands, tenants, or environments.
- [ ] **Day 023 — Abstract Factory pressure.** Demonstrate how independently
  selecting family members creates invalid combinations.
- [ ] **Day 024 — Abstract Factory solution.** Implement complete families and
  document why one concrete factory would not justify the pattern.
- [ ] **Day 025 — Builder problem.** Define a multipart request or checkout
  configuration assembled across conditional steps.
- [ ] **Day 026 — Builder pressure.** Show validation and construction-order
  requirements that an initializer no longer communicates safely.
- [ ] **Day 027 — Builder solution.** Implement the smallest useful builder and
  contrast it with a memberwise initializer and default arguments.
- [ ] **Day 028 — Weekly review.** Validate both creational examples and inspect
  their construction APIs for accidental ceremony.

### Week 5 — Prototype and Observer

- [ ] **Day 029 — Prototype problem.** Start with Swift value-copy semantics and
  define a document graph that genuinely requires controlled deep copying.
- [ ] **Day 030 — Prototype pressure.** Demonstrate reference sharing and subtype
  preservation problems that ordinary assignment does not solve.
- [ ] **Day 031 — Prototype solution.** Implement explicit cloning only at the
  justified reference boundary and document the common no-pattern case.
- [ ] **Day 032 — Observer problem.** Define session or connectivity changes with
  multiple real consumers.
- [ ] **Day 033 — Observer pressure.** Demonstrate the coupling caused by direct
  callbacks and lifecycle-sensitive subscriptions.
- [ ] **Day 034 — Observer solution.** Prefer Observation or `AsyncStream` where
  appropriate and avoid inventing a custom notification framework.
- [ ] **Day 035 — Weekly review.** Validate copy ownership and observer lifecycle,
  cancellation, and delivery semantics.

### Week 6 — State and Command

- [ ] **Day 036 — State problem.** Define an upload or checkout lifecycle with
  explicit valid and invalid transitions.
- [ ] **Day 037 — State pressure.** Demonstrate contradictory booleans and
  branching that allow impossible states.
- [ ] **Day 038 — State solution.** Model transitions minimally and distinguish
  state machines from runtime-selected Strategy behavior.
- [ ] **Day 039 — Command problem.** Define editor operations that need undo,
  redo, or offline queuing.
- [ ] **Day 040 — Command pressure.** Demonstrate why direct button actions cannot
  preserve reversible intent.
- [ ] **Day 041 — Command solution.** Implement commands with focused state and
  tests for execution and reversal.
- [ ] **Day 042 — Weekly review.** Validate invalid transitions, undo ownership,
  and retained-state costs.

### Week 7 — Facade and Decorator

- [ ] **Day 043 — Facade problem.** Define a checkout use case spanning inventory,
  payment, order creation, and analytics.
- [ ] **Day 044 — Facade pressure.** Show client orchestration leakage without
  turning the replacement into a god object.
- [ ] **Day 045 — Facade solution.** Implement a narrow use-case facade and retain
  access to lower-level components where appropriate.
- [ ] **Day 046 — Decorator problem.** Define composable HTTP client behavior such
  as authentication, metrics, or retry.
- [ ] **Day 047 — Decorator pressure.** Demonstrate optional feature combinations
  that inheritance or flags make difficult to compose.
- [ ] **Day 048 — Decorator solution.** Implement ordered wrappers and document
  the behavioral consequences of decorator order.
- [ ] **Day 049 — Weekly review.** Validate facade scope and decorator composition
  without hiding errors or ownership.

### Week 8 — Proxy and Chain of Responsibility

- [ ] **Day 050 — Proxy problem.** Define lazy loading, access control, or caching
  behind the same remote-resource interface.
- [ ] **Day 051 — Proxy pressure.** Demonstrate why every client should not own
  access and lifecycle policy.
- [ ] **Day 052 — Proxy solution.** Implement the smallest proxy and contrast it
  with Decorator's behavior composition.
- [ ] **Day 053 — Chain problem.** Define deep-link or request handlers that may
  handle or pass work onward.
- [ ] **Day 054 — Chain pressure.** Show growing centralized branching and the
  importance of deterministic handler order.
- [ ] **Day 055 — Chain solution.** Implement explicit pass/handle semantics and
  distinguish the chain from Decorator and middleware pipelines.
- [ ] **Day 056 — Weekly review.** Validate ordering, error propagation, caching,
  and access decisions.

### Week 9 — Memento and Iterator

- [ ] **Day 057 — Memento problem.** Define editor draft snapshots without
  exposing mutable internal representation.
- [ ] **Day 058 — Memento pressure.** Demonstrate restoration requirements and
  snapshot size or versioning costs.
- [ ] **Day 059 — Memento solution.** Implement bounded restoration and document
  persistence and compatibility trade-offs.
- [ ] **Day 060 — Iterator problem.** Define a paginated API whose consumers
  should not manage page tokens.
- [ ] **Day 061 — Iterator pressure.** Demonstrate duplicated pagination state,
  cancellation, and termination logic.
- [ ] **Day 062 — Iterator solution.** Expose iteration through `AsyncSequence`
  and document why an array is sufficient for already-loaded data.
- [ ] **Day 063 — Weekly review.** Validate snapshot ownership and asynchronous
  iteration termination, error, and cancellation behavior.

### Week 10 — Composite and Mediator

- [ ] **Day 064 — Composite problem.** Define a real file-and-folder or document
  hierarchy requiring uniform operations.
- [ ] **Day 065 — Composite pressure.** Demonstrate recursive client branching
  across leaves and containers.
- [ ] **Day 066 — Composite solution.** Implement uniform traversal while keeping
  leaf-only operations explicit.
- [ ] **Day 067 — Mediator problem.** Define checkout form modules that otherwise
  reference and update one another directly.
- [ ] **Day 068 — Mediator pressure.** Show coordination coupling and feedback-loop
  risks without centralizing all business logic.
- [ ] **Day 069 — Mediator solution.** Implement a focused interaction mediator
  and document its boundary against a god coordinator.
- [ ] **Day 070 — Weekly review.** Validate recursive behavior, ownership, and
  mediator responsibility.

### Week 11 — Template Method and Flyweight

- [ ] **Day 071 — Template Method problem.** Define a stable import pipeline with
  a small number of provider-specific steps.
- [ ] **Day 072 — Template Method pressure.** Demonstrate duplicated algorithm
  order and compare inheritance with protocol composition.
- [ ] **Day 073 — Template Method solution.** Implement the stable skeleton only
  if subclass variation remains the clearest trade-off.
- [ ] **Day 074 — Flyweight problem.** Define thousands of map annotations sharing
  immutable styles or icons.
- [ ] **Day 075 — Flyweight pressure.** Measure or calculate the repeated-memory
  cost before adding shared representation.
- [ ] **Day 076 — Flyweight solution.** Implement shared intrinsic data and record
  the measured benefit and lookup cost.
- [ ] **Day 077 — Weekly review.** Reassess whether composition beats inheritance
  and whether Flyweight has quantitative justification.

### Week 12 — Visitor and Interpreter

- [ ] **Day 078 — Visitor problem.** Define a stable document node hierarchy with
  a growing set of export or validation operations.
- [ ] **Day 079 — Visitor pressure.** Demonstrate operation scattering and the
  trade-off between stable nodes and new node types.
- [ ] **Day 080 — Visitor solution.** Implement double dispatch only if the
  hierarchy and operation growth justify it.
- [ ] **Day 081 — Interpreter problem.** Define a deliberately small filter DSL,
  such as `status:open assignee:me`.
- [ ] **Day 082 — Interpreter pressure.** Define grammar limits, parsing errors,
  and the point where a parser library becomes preferable.
- [ ] **Day 083 — Interpreter solution.** Implement the bounded grammar with
  readable diagnostics and no speculative language features.
- [ ] **Day 084 — Weekly review.** Validate extensibility direction and reject
  unnecessary AST or grammar complexity.

### Week 13 — Singleton and the no-pattern decision

- [ ] **Day 085 — Singleton problem.** Define a genuinely process-unique platform
  resource with explicit ownership.
- [ ] **Day 086 — Singleton pressure.** Demonstrate uniqueness requirements while
  preserving dependency injection and test isolation.
- [ ] **Day 087 — Singleton solution.** Implement the smallest controlled shared
  instance and document why ordinary services should not copy it.
- [ ] **Day 088 — No-pattern problem.** Define a plausible refactor request where
  a named pattern appears attractive.
- [ ] **Day 089 — No-pattern evidence.** Compare the pattern's types and
  indirection with a function, enum, initializer, or platform API.
- [ ] **Day 090 — No-pattern decision.** Keep the direct solution and document the
  concrete signal that would justify revisiting it.
- [ ] **Day 091 — Catalogue review.** Validate all 23 patterns, status links,
  visuals, tests, and conceptual distinctions.

### Week 14 — Codex skill and release readiness

- [ ] **Day 092 — Extract decision signals.** Derive evidence-based triggers and
  rejection signals from the completed catalogue.
- [ ] **Day 093 — Design skill scenarios.** Define prompts that require Adapter,
  State, no pattern, and a Bridge-versus-Strategy decision.
- [ ] **Day 094 — Initialize the skill.** Create
  `.codex/skills/choose-swift-design-pattern` with the official skill tooling.
- [ ] **Day 095 — Write the decision workflow.** Make the direct Swift solution
  and explicit no-pattern verdict first-class outcomes.
- [ ] **Day 096 — Add progressive references.** Provide a concise decision matrix,
  catalogue guidance, and example-quality checklist without duplication.
- [ ] **Day 097 — Validate the skill.** Run structural validation and realistic
  forward tests without leaking expected answers.
- [ ] **Day 098 — Refine from evidence.** Correct weak triggers, over-prescription,
  and confusing output based on validation results.
- [ ] **Day 099 — Release-candidate QA.** Run all checks, verify documentation and
  assets, prepare release notes, and request approval before any tag or release.
- [ ] **Day 100 — Retrospective.** Record what was simplified, rejected, learned,
  and recommended for the next iteration of the repository.

## Review checkpoints

- **Day 007:** foundation ready.
- **Day 028:** corrected creational foundation.
- **Day 049:** common app patterns validated.
- **Day 070:** flow and structural patterns validated.
- **Day 091:** all 23 patterns complete.
- **Day 099:** release candidate ready for explicit approval.

The roadmap may be clarified as evidence emerges, but changing scope, order, or
the Definition of Done must be visible in its own reviewed commit.
