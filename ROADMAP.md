# 100-Day Internal Roadmap: Pragmatic Design Patterns in Swift

This internal roadmap turns the repository into an executable, tested, visual
guide to the 23 Gang of Four design patterns without treating patterns as goals
by themselves or imposing the same cadence on the public series.

The series follows one rule:

> A pattern earns its place only when it solves a concrete problem more clearly
> than Swift's direct language and platform features.

Last updated: 2026-11-11

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
- [x] **Day 016 — Bridge pressure.** Demonstrate the product-type by channel
  combination growth without introducing a class explosion. The [pressure
  review](Documentation/bridge-pressure.md) adds SMS to the direct solution and
  measures why one channel change must touch every notification purpose.
- [x] **Day 017 — Bridge solution.** Implement and document the two-axis bridge
  with executable asynchronous behavior in the [canonical Bridge guide](Structural%20Patterns/Bridge/README.md).
- [x] **Day 018 — Factory Method problem.** Define import workflows in which each
  provider must choose its parser in the [bank statement baseline](Documentation/factory-method-problem.md).
- [x] **Day 019 — Factory Method pressure.** Contrast the extension pressure with
  a centralized Simple Factory switch in the [pressure review](Documentation/factory-method-pressure.md).
- [x] **Day 020 — Factory Method solution.** Implement the minimal factory method
  and document its distinction from Simple and Abstract Factory in the [canonical guide](Creational%20Patterns/Factory%20Method/README.md).
- [x] **Day 021 — Weekly review.** Validate Bridge and Factory Method and remove
  any Strategy-like or factory-like misclassification. The [review evidence](Documentation/week-03-review.md)
  confirms their change boundaries, visual consistency, and warning-free full
  suite before Abstract Factory.

### Week 4 — Abstract Factory and Builder

- [x] **Day 022 — Abstract Factory problem.** Define two coherent service
  families for real app brands, tenants, or environments. The [regional
  commerce baseline](Documentation/abstract-factory-problem.md) keeps the
  composition root direct and makes mixed-family values observable in tests.
- [x] **Day 023 — Abstract Factory pressure.** Demonstrate how independently
  selecting family members creates invalid combinations. The [pressure review](Documentation/abstract-factory-pressure.md)
  measures 16 direct assemblies for two regions and three products: only two
  form coherent service families.
- [x] **Day 024 — Abstract Factory solution.** Implement complete families and
  document why one concrete factory would not justify the pattern in the
  [canonical Abstract Factory guide](Creational%20Patterns/Abstract%20Factory/README.md).
- [x] **Day 025 — Builder problem.** Define a multipart request or checkout
  configuration assembled across conditional steps. The [privacy-aware support
  upload baseline](Documentation/builder-problem.md) keeps construction in one
  throwing value initializer until ordered intermediate steps justify Builder.
- [x] **Day 026 — Builder pressure.** Show validation and construction-order
  requirements that an initializer no longer communicates safely. The
  [pressure review](Documentation/builder-pressure.md) records four invalid
  order families exposed by the direct step sequence.
- [x] **Day 027 — Builder solution.** Implement the smallest useful builder and
  contrast it with a memberwise initializer and default arguments in the
  [canonical Builder guide](Creational%20Patterns/Builder/README.md).
- [x] **Day 028 — Weekly review.** Validate both creational examples and inspect
  their construction APIs for accidental ceremony. The [review evidence](Documentation/week-04-review.md)
  confirms that their construction boundaries remain distinct, warning-free,
  and no larger than their demonstrated pressures require.

### Week 5 — Prototype and Observer

- [x] **Day 029 — Prototype problem.** Start with Swift value-copy semantics and
  define a document graph that genuinely requires controlled deep copying. The
  [editable-document baseline](Documentation/prototype-problem.md) proves that
  ordinary assignment already handles value-only configuration, then fixes the
  identity, subtype, link-remapping, and resource-sharing rules for the graph.
- [x] **Day 030 — Prototype pressure.** Demonstrate reference sharing and subtype
  preservation problems that ordinary assignment does not solve. The
  [pressure review](Documentation/prototype-pressure.md) proves that assignment
  shares mutable blocks and records the four-branch centralized copy needed to
  preserve subtype state, remap links, and share immutable media deliberately.
- [x] **Day 031 — Prototype solution.** Implement explicit cloning only at the
  justified reference boundary and document the common no-pattern case in the
  [canonical Prototype guide](Creational%20Patterns/Prototype/README.md).
- [x] **Day 032 — Observer problem.** Define session or connectivity changes with
  multiple real consumers. The [authenticated-session baseline](Documentation/observer-problem.md)
  keeps delivery synchronous and direct while the four consumers share the
  session owner's lifetime.
- [x] **Day 033 — Observer pressure.** Demonstrate the coupling caused by direct
  callbacks and lifecycle-sensitive subscriptions in the [pressure review](Documentation/observer-pressure.md).
- [x] **Day 034 — Observer solution.** Prefer Observation or `AsyncStream` where
  appropriate and avoid inventing a custom notification framework. The
  actor-isolated `AsyncStream` boundary is documented in the [canonical guide](Behavioral%20Patterns/Observer/README.md)
  and [solution review](Documentation/observer-solution.md), with an editorial
  header that makes independent receiver lifetimes visible.
- [x] **Day 035 — Weekly review.** Validate copy ownership and observer lifecycle,
  cancellation, and delivery semantics. The [review evidence](Documentation/week-05-review.md)
  closes Observer's initial-snapshot race, proves independent cancellation, and
  confirms Prototype's graph-copy ownership remains explicit.

### Week 6 — State and Command

- [x] **Day 036 — State problem.** Define an upload or checkout lifecycle with
  explicit valid and invalid transitions. The [encrypted-backup baseline](Documentation/state-problem.md)
  keeps the lifecycle in one enum and pure reducer until state-specific behavior
  proves that a broader pattern would reduce branching.
- [x] **Day 037 — State pressure.** Demonstrate contradictory booleans and
  branching that allow impossible states. The [pressure review](Documentation/state-pressure.md)
  proves that six independently persisted flags admit 57 invalid lifecycle
  combinations and let UI and worker decisions disagree.
- [x] **Day 038 — State solution.** Model transitions minimally and distinguish
  state machines from runtime-selected Strategy behavior. The [canonical State
  guide](Behavioral%20Patterns/State/README.md) keeps its protocol and seven
  phase implementations private while one value-semantic context owns
  transitions, UI decisions, background work, and typed persistence.
- [x] **Day 039 — Command problem.** Define editor operations that need undo,
  redo, or offline queuing. The [video-timeline baseline](Documentation/command-problem.md)
  keeps trim, move, split, caption, and one-step undo in direct value-based
  methods until reusable edit intent demonstrates a narrower boundary.
- [x] **Day 040 — Command pressure.** Demonstrate why direct button actions cannot
  preserve reversible intent. The [pressure review](Documentation/command-pressure.md)
  measures bounded full-timeline snapshots and 12 duplicated toolbar, keyboard,
  and replay branches before any Command abstraction is introduced.
- [x] **Day 041 — Command solution.** Implement commands with focused state and
  tests for execution and reversal. The [canonical Command guide](Behavioral%20Patterns/Command/README.md)
  keeps one codable edit vocabulary while local history retains only the state
  each accepted edit needs to reverse.
- [x] **Day 042 — Weekly review.** Validate invalid transitions, undo ownership,
  and retained-state costs. The [review evidence](Documentation/week-06-review.md)
  confirms State and Command keep distinct mutation boundaries, explicit
  rejection semantics, and proportionate retained state.

### Week 7 — Facade and Decorator

- [x] **Day 043 — Facade problem.** Define a checkout use case spanning inventory,
  payment, order creation, and analytics. The [direct checkout baseline](Documentation/facade-problem.md)
  keeps reservation, authorization, compensation, order creation, and terminal
  analytics visible in one screen client until repeated orchestration proves a
  narrower Facade boundary.
- [x] **Day 044 — Facade pressure.** Show client orchestration leakage without
  turning the replacement into a god object. The [pressure review](Documentation/facade-pressure.md)
  measures three direct clients, 12 subsystem dependency slots, and three
  duplicated compensation branches before introducing a Facade.
- [x] **Day 045 — Facade solution.** Implement a narrow use-case facade and retain
  access to lower-level components where appropriate. The [canonical Facade guide](Structural%20Patterns/Facade/README.md)
  gives checkout placement one orchestration and compensation owner while the
  focused subsystem types remain independently available.
- [x] **Day 046 — Decorator problem.** Define composable HTTP client behavior such
  as authentication, metrics, or retry. The [fixed media-upload baseline](Documentation/decorator-problem.md)
  keeps authentication, bounded retry, and one terminal metric inside a direct
  client until independently optional behavior proves a composition boundary.
- [x] **Day 047 — Decorator pressure.** Demonstrate optional feature combinations
  that inheritance or flags make difficult to compose. The [pressure review](Documentation/decorator-pressure.md)
  measures eight possible pipelines, five required profiles, conditional
  dependencies, and one hidden behavior order in a direct flag-based client.
- [x] **Day 048 — Decorator solution.** Implement ordered wrappers and document
  the behavioral consequences of decorator order in the [canonical Decorator
  guide](Structural%20Patterns/Decorator/README.md).
- [x] **Day 049 — Weekly review.** Validate facade scope and decorator composition
  without hiding errors or ownership. The [joint review](Documentation/week-07-review.md)
  records compensation ownership, independently bounded retries, regression
  coverage, and the complete build, test, lint, and documentation checks.

### Week 8 — Proxy and Chain of Responsibility

- [x] **Day 050 — Proxy problem.** Define lazy loading, access control, or caching
  behind the same remote-resource interface. The [expiring lesson media baseline](Documentation/proxy-problem.md)
  keeps entitlement checks and one bounded URL refresh in a concrete playback
  model until multiple clients prove a shared substitute is worthwhile.
- [x] **Day 051 — Proxy pressure.** Demonstrate why every client should not own
  access and lifecycle policy. The [pressure review](Documentation/proxy-pressure.md)
  measures three client-owned policy copies and verifies consistent entitlement
  gates, bounded URL renewal, and terminal player failures across the two new
  entry points.
- [x] **Day 052 — Proxy solution.** Implement the smallest proxy and contrast it
  with Decorator's behavior composition in the [canonical Proxy
  guide](Structural%20Patterns/Proxy/README.md).
- [x] **Day 053 — Chain problem.** Define deep-link or request handlers that may
  handle or pass work onward. The [universal-link routing baseline](Documentation/chain-of-responsibility-problem.md)
  keeps the closed route set in one exhaustive switch with explicit handled,
  unhandled, and authentication-gated outcomes.
- [x] **Day 054 — Chain pressure.** Show growing centralized branching and the
  importance of deterministic handler order. The [pressure review](Documentation/chain-of-responsibility-pressure.md)
  measures five feature families at one switch and proves two
  specialized-before-generic precedence constraints.
- [x] **Day 055 — Chain solution.** Implement explicit pass/handle semantics and
  distinguish the chain from Decorator and middleware pipelines in the
  [canonical Chain of Responsibility guide](Behavioral%20Patterns/Chain%20of%20Responsibility/README.md).
- [x] **Day 056 — Weekly review.** Validate ordering, error propagation, caching,
  and access decisions. The [review evidence](Documentation/week-08-review.md)
  confirms fresh access checks, uncached playback URLs, terminal handler
  decisions, and the distinct ownership boundaries of Proxy and Chain.

### Week 9 — Memento and Iterator

- [x] **Day 057 — Memento problem.** Define editor draft snapshots without
  exposing mutable internal representation. The [route-planning baseline](Documentation/memento-problem.md)
  keeps small restore points as private, bounded value copies until external
  history ownership or compatibility pressure justifies Memento participants.
- [x] **Day 058 — Memento pressure.** Demonstrate restoration requirements and
  snapshot size or versioning costs. The [pressure review](Documentation/memento-pressure.md)
  measures bounded full-snapshot storage and exposes the schema coupling caused
  by an external JSON history owner.
- [x] **Day 059 — Memento solution.** Implement bounded restoration and document
  persistence and compatibility trade-offs in the [canonical Memento guide](Behavioral%20Patterns/Memento/README.md),
  where an opaque restore point keeps schema ownership inside the editor.
- [x] **Day 060 — Iterator problem.** Define a paginated API whose consumers
  should not manage page tokens. The [photo-library baseline](Documentation/iterator-problem.md)
  keeps one opaque cursor in the consuming screen until additional traversal
  clients demonstrate shared pagination, termination, and cancellation policy.
- [x] **Day 061 — Iterator pressure.** Demonstrate duplicated pagination state,
  cancellation, and termination logic. The [pressure review](Documentation/iterator-pressure.md)
  measures three consumer-owned cursors and termination decisions while
  preserving distinct indexing, retry, early-exit, and cancellation policies.
- [x] **Day 062 — Iterator solution.** Expose iteration through `AsyncSequence`
  and document why an array is sufficient for already-loaded data in the
  [canonical Iterator guide](Behavioral%20Patterns/Iterator/README.md).
- [x] **Day 063 — Weekly review.** Validate snapshot ownership and asynchronous
  iteration termination, error, and cancellation behavior. The
  [review evidence](Documentation/week-09-review.md) confirms independent
  captured state, atomic restoration, terminal iteration, same-cursor retry,
  and cancellation before buffered delivery or new remote work.

### Week 10 — Composite and Mediator

- [x] **Day 064 — Composite problem.** Define a real file-and-folder or document
  hierarchy requiring uniform operations. The [offline workspace baseline](Documentation/composite-problem.md)
  keeps the closed file-or-folder hierarchy in an `indirect enum` and one
  recursive selection preview until additional clients prove a uniform component
  boundary would reduce branching.
- [x] **Day 065 — Composite pressure.** Demonstrate recursive client branching
  across leaves and containers. The [pressure review](Documentation/composite-pressure.md)
  measures three client-owned file-or-folder switches and recursive walks while
  keeping offline, search, and cleanup policies independent.
- [x] **Day 066 — Composite solution.** Implement uniform traversal while keeping
  leaf-only operations explicit. The [canonical Composite guide](Structural%20Patterns/Composite/README.md)
  centralizes file discovery behind `WorkspaceComponent.fileLocations` while
  keeping offline, search, cleanup, and concrete-file opening responsibilities
  separate.
- [x] **Day 067 — Mediator problem.** Define checkout form modules that otherwise
  reference and update one another directly. The [delivery checkout baseline](Documentation/mediator-problem.md)
  keeps address, slot, promotion, and payment interaction inside one direct form
  model until independently owned modules demonstrate real coordination risk.
- [x] **Day 068 — Mediator pressure.** Show coordination coupling and feedback-loop
  risks without centralizing all business logic. The [pressure review](Documentation/mediator-pressure.md)
  demonstrates four direct module dependencies, a delivery/promotion callback
  cycle, and verified reentry guards while keeping validation in each participant.
- [x] **Day 069 — Mediator solution.** Implement a focused interaction mediator
  and document its boundary against a god coordinator. The [canonical Mediator
  guide](Behavioral%20Patterns/Mediator/README.md) routes participant events through
  one interaction owner and resolves promotion-driven delivery corrections before
  validating payment, preserving a method accepted by the final window.
- [x] **Day 070 — Weekly review.** Validate recursive behavior, ownership, and
  mediator responsibility. The [review evidence](Documentation/week-10-review.md)
  confirms contextual value traversal, explicit promotion opt-in, bounded
  coordination, and a warning-free full suite before Template Method.

### Week 11 — Template Method and Flyweight

- [x] **Day 071 — Template Method problem.** Define a stable import pipeline with
  a small number of provider-specific steps. The [reading-list import baseline](Documentation/template-method-problem.md)
  keeps Safari and Pocket decoding explicit while normalization, deduplication,
  atomic persistence, and reporting follow one verified order.
- [x] **Day 072 — Template Method pressure.** Demonstrate duplicated algorithm
  order and compare inheritance with protocol composition. The [pressure
  evidence](Documentation/template-method-pressure.md) adds a third provider,
  counts six repeated safety-rail decisions, and keeps an ordinary composed
  function as the benchmark for a module-controlled skeleton.
- [x] **Day 073 — Template Method solution.** Implement the stable skeleton only
  if subclass variation remains the clearest trade-off. The [canonical Template
  Method guide](Behavioral%20Patterns/Template%20Method/README.md) closes
  construction within the module, makes the import sequence final, and varies
  only provider decoding and candidate selection without abstract-method traps.
- [x] **Day 074 — Flyweight problem.** Define thousands of map annotations sharing
  immutable styles or icons. The [festival map baseline](Documentation/flyweight-problem.md)
  deliberately rebuilds complete category artwork per annotation so the next
  day can measure repeated intrinsic memory before introducing shared storage.
- [x] **Day 075 — Flyweight pressure.** Measure or calculate the repeated-memory
  cost before adding shared representation. The [pressure review](Documentation/flyweight-pressure.md)
  exercises 20,000 locations and finds 81,903,616 avoidable repeated pixel
  bytes while deliberately keeping the direct ownership model.
- [x] **Day 076 — Flyweight solution.** Implement shared intrinsic data and record
  the measured benefit and lookup cost. The [canonical Flyweight guide](Structural%20Patterns/Flyweight/README.md)
  uses one request-scoped category catalogue to reduce 20,000 artwork objects
  to four while keeping every location's map and accessibility state unique.
- [x] **Day 077 — Weekly review.** Reassess whether composition beats inheritance
  and whether Flyweight has quantitative justification. The [review evidence](Documentation/week-11-review.md)
  keeps composition as the default, confines inheritance to one closed import
  sequence, and confirms the measured 81,903,616-byte Flyweight reduction.

### Week 12 — Visitor and Interpreter

- [x] **Day 078 — Visitor problem.** Define a stable document node hierarchy with
  a growing set of export or validation operations. The [publishing document
  baseline](Documentation/visitor-problem.md) keeps one accessibility audit in
  an exhaustive enum switch until additional operations justify double dispatch.
- [x] **Day 079 — Visitor pressure.** Demonstrate operation scattering and the
  trade-off between stable nodes and new node types. The [pressure review](Documentation/visitor-pressure.md)
  adds plain-text extraction and localization inventory, exposing three
  traversals and twelve concrete branches across four unchanged node kinds.
- [x] **Day 080 — Visitor solution.** Implement double dispatch only if the
  hierarchy and operation growth justify it. The [canonical Visitor guide](Behavioral%20Patterns/Visitor/README.md)
  keeps four document elements stable while accessibility, plain-text, and
  localization visitors own their distinct state and results.
- [x] **Day 081 — Interpreter problem.** Define a deliberately small filter DSL,
  such as `status:open assignee:me`. The [support inbox baseline](Documentation/interpreter-problem.md)
  keeps the two-field grammar in one direct loop until composition or diagnostic
  pressure justifies explicit language structure.
- [x] **Day 082 — Interpreter pressure.** Define grammar limits, parsing errors,
  and the point where a parser library becomes preferable. The [pressure
  review](Documentation/interpreter-pressure.md) adds one positioned,
  non-nested status alternative while keeping the parser direct and records
  the exact recursion, precedence, escaping, and recovery threshold for a
  maintained parsing library.
- [x] **Day 083 — Interpreter solution.** Implement the bounded grammar with
  readable diagnostics and no speculative language features. The [canonical
  Interpreter guide](Behavioral%20Patterns/Interpreter/README.md) separates one
  positioned parser from a value-semantic expression vocabulary while keeping
  local status OR, outer AND, stable ordering, and the parser-library threshold
  explicit.
- [x] **Day 084 — Weekly review.** Validate extensibility direction and reject
  unnecessary AST or grammar complexity. The [review evidence](Documentation/week-12-review.md)
  keeps Visitor aligned with operation growth over stable elements and confines
  Interpreter to one non-recursive, positioned support-query grammar.

### Week 13 — Singleton and the no-pattern decision

- [x] **Day 085 — Singleton problem.** Define a genuinely process-unique platform
  resource with explicit ownership. The [audio session baseline](Documentation/singleton-problem.md)
  keeps one controller injected from the composition root and proves exclusive,
  recoverable ownership before any shared instance exists.
- [x] **Day 086 — Singleton pressure.** Demonstrate uniqueness requirements while
  preserving dependency injection and test isolation. The [pressure evidence](Documentation/singleton-pressure.md)
  proves that one injected controller rejects competing owners while two
  independent construction roots can each activate the same process resource.
- [x] **Day 087 — Singleton solution.** Implement the smallest controlled shared
  instance and document why ordinary services should not copy it in the
  [canonical Singleton guide](Creational%20Patterns/Singleton/README.md).
- [x] **Day 088 — No-pattern problem.** Define a plausible refactor request where
  a named pattern appears attractive. The [product-share baseline](Documentation/no-pattern-problem.md)
  tests an immutable request and `URLComponents` before a custom Builder earns
  any construction state.
- [x] **Day 089 — No-pattern evidence.** Compare the pattern's types and
  indirection with a function, enum, initializer, or platform API. The
  [evidence review](Documentation/no-pattern-evidence.md) adds one typed
  storefront locale without introducing construction order, reusable state,
  or mechanics beyond the immutable request and `URLComponents`.
- [x] **Day 090 — No-pattern decision.** Keep the direct solution and document the
  concrete signal that would justify revisiting it. The [final no-pattern
  guide](Documentation/no-pattern-decision.md) retains the immutable product-share
  request and identifies ordered, validated construction stages as the threshold
  for reconsidering Builder.
- [x] **Day 091 — Catalogue review.** Validate all 23 patterns, status links,
  visuals, tests, and conceptual distinctions. The [complete catalogue
  review](Documentation/catalogue-review.md) confirms 23 canonical guides,
  warning-free behavior, one visual system, and the change boundaries that
  prevent nearby patterns from being misclassified.

### Week 14 — Codex skill and release readiness

- [x] **Day 092 — Extract decision signals.** Derive evidence-based triggers and
  rejection signals from the completed catalogue. The [decision-signal
  extraction](Documentation/skill-decision-signals.md) makes a verified direct
  Swift baseline, positive pressure, rejection evidence, and neighbour checks
  prerequisites for any future recommendation.
- [x] **Day 093 — Design skill scenarios.** Define prompts that require Adapter,
  State, no pattern, and a Bridge-versus-Strategy decision. The
  [independent evaluation scenarios](Documentation/skill-evaluation-scenarios.md)
  separate unfamiliar app prompts from observable rubrics so later forward
  tests can expose overfitting without leaking expected answers.
- [x] **Day 094 — Initialize the skill.** Create
  `.codex/skills/choose-swift-design-pattern` with the official skill tooling.
  The [skill entry point](.codex/skills/choose-swift-design-pattern/SKILL.md)
  now defines its discovery boundary, while generated agent metadata keeps the
  scaffold ready for the Day 095 workflow without premature resources.
- [x] **Day 095 — Write the decision workflow.** Make the direct Swift solution
  and explicit no-pattern verdict first-class outcomes. The [skill entry
  point](.codex/skills/choose-swift-design-pattern/SKILL.md) now moves from
  observed pressure through a direct baseline and evidence gate to exactly one
  reviewable verdict, including the evidence that would reverse it.
- [x] **Day 096 — Add progressive references.** Provide a concise decision matrix,
  catalogue guidance, and example-quality checklist without duplication. The
  [skill entry point](.codex/skills/choose-swift-design-pattern/SKILL.md) now
  routes only the relevant [catalogue matrix](.codex/skills/choose-swift-design-pattern/references/decision-matrix.md),
  [neighbour guidance](.codex/skills/choose-swift-design-pattern/references/catalogue-guidance.md),
  or [example-quality checklist](.codex/skills/choose-swift-design-pattern/references/example-quality-checklist.md)
  for the current request.
- [x] **Day 097 — Validate the skill.** Run structural validation and realistic
  forward tests without leaking expected answers. The [validation report](Documentation/skill-validation.md)
  records a valid skill package, four independent passing verdicts, ignored raw
  outputs, and two bounded output-shape observations for Day 098.
- [x] **Day 098 — Refine from evidence.** Correct weak triggers, over-prescription,
  and confusing output based on validation results. The
  [refinement report](Documentation/skill-refinement.md) records narrower
  neighbour selection, representation-neutral decision answers, and two fresh
  passing boundary tests without copying their prompts into the skill.
- [x] **Day 099 — Release-candidate QA.** Run all checks, verify documentation and
  assets, prepare release notes, and request approval before any tag or release.
  The [v1.0 release candidate](Documentation/v1.0-release-candidate.md) records a
  warning-free build, 350 passing tests, complete guide and asset inventories,
  repository-wide link and Mermaid checks, the explicit renderer-validation
  limit, and the approval gate that prevents an automatic tag or release.
- [x] **Day 100 — Retrospective.** Record what was simplified, rejected, learned,
  and recommended for the next iteration of the repository. The
  [100-day retrospective](Documentation/retrospective.md) closes the programme
  with its deliberately omitted abstractions, evidence-led lessons, remaining
  validation limits, and candidate problem areas for a later roadmap.

### Bonus track — Harden the examples

The [bonus-track plan](Documentation/bonus-track.md) improves decision quality
without reopening the completed catalogue or inventing requirements to defend a
pattern.

- [x] **Bonus 001 — Isolate historical examples.** Mark superseded documents
  and Swift files as non-canonical, map each one to its tested replacement, and
  keep the original evidence available without presenting it as current advice.
- [x] **Bonus 002 — Re-evaluate Factory Method against creation closures.** The
  [executable comparison](Documentation/factory-method-closure-comparison.md)
  proves that closures reproduce a correctly paired workflow through one
  configurator but expose preparation/parser pairing to its caller. Factory
  Method remains only because the provider owns both decisions.
- [x] **Bonus 003 — Constrain Singleton's shared lookup.** The
  [visibility review](Documentation/singleton-visibility-review.md) replaces
  public `shared` access with one file-private production identity, a package
  composition root for injection, and the single non-injectable callback path.
- [x] **Bonus 004 — Tighten Flyweight measurement claims.** The
  [measurement review](Documentation/flyweight-measurement-review.md) renames
  the executable profile around model-owned payload, preserves exact identity
  and byte evidence, and explicitly excludes allocation, RSS, cache, renderer,
  and GPU-memory claims.
- [x] **Bonus 005 — Define Interpreter's parser handoff.** The
  [handoff review](Documentation/interpreter-parser-handoff.md) turns nesting,
  precedence, quoting, escaping, and multi-error recovery into executable
  rejection boundaries without expanding the current grammar.
- [x] **Bonus 006 — Bound Mediator coordination responsibility.** The
  [responsibility review](Documentation/mediator-responsibility-review.md)
  proves local participant rules independently and defines evidence-based split
  signals before coordination becomes a god object.
- [x] **Bonus 007 — Quantify Memento snapshot growth.** The
  [storage review](Documentation/memento-storage-review.md) demonstrates
  monotonic content growth, linear bounded-history growth for small edits, and
  the evidence required before adopting deltas or durable persistence.
- [x] **Bonus 008 — Compare Template Method with higher-order composition.**
  The [composition review](Documentation/template-method-composition-review.md)
  proves an ordinary closure-based rail can preserve order and atomicity, then
  narrows Template Method to a closed nominal importer family.
- [x] **Bonus 009 — Demonstrate Visitor's extension direction.** The
  [extension review](Documentation/visitor-extension-review.md) makes operation
  growth executable and records the compiler-enforced cost of adding an element
  without inventing a fifth node kind.
- [x] **Bonus 010 — Review the hardened catalogue.** The
  [final bonus review](Documentation/bonus-track-review.md) records a
  warning-free build, 359 tests in 194 suites, complete guide/link/diagram/asset
  checks, the unchanged skill-validation boundary, and v1.0 requalification.

## Review checkpoints

- **Day 007:** foundation ready.
- **Day 028:** corrected creational foundation.
- **Day 049:** common app patterns validated.
- **Day 070:** flow and structural patterns validated.
- **Day 091:** all 23 patterns complete.
- **Day 099:** release candidate ready for explicit approval.
- **Day 100:** retrospective complete; the original candidate reached the
  explicit release-approval gate before the bonus track began.
- **Bonus 010:** hardened examples retain only evidence-backed improvements and
  the v1.0 candidate is requalified for explicit release approval.

The roadmap may be clarified as evidence emerges, but changing scope, order, or
the Definition of Done must be visible in its own reviewed commit.
