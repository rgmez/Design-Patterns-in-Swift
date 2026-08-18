# Real-App Domain Map

This map assigns one credible app problem to every Gang of Four pattern before
implementation begins. It is a constraint, not a promise that the pattern will
be used: each cycle must still prove that direct Swift has reached a concrete
limit.

The [roadmap](../ROADMAP.md) remains the source of truth for sequence and scope.
The [catalogue audit](catalogue-audit.md) records the historical code that each
cycle must preserve until its replacement is verified.

## Selection rules

Every scenario below has four gates:

1. Start with the smallest direct Swift solution.
2. Introduce only requirements an app could actually receive.
3. Measure the pressure in coupling, branching, invalid states, duplication,
   memory, lifecycle risk, or test friction.
4. Reject the named pattern when its extra types do not reduce that pressure.

[Refactoring.Guru's Swift catalogue](https://refactoring.guru/design-patterns/swift)
may be used to cross-check pattern intent and vocabulary. It is not a source for
our examples. Do not reuse or closely mirror its domains, names, type graph,
code, diagrams, or narrative progression.

## Creational patterns

### Factory Method — bank statement import

**App problem:** A personal-finance app imports transactions from bank-specific
CSV, OFX, and open-banking JSON exports. Each importer owns authentication or
file preparation and must select the parser compatible with that prepared data.

**Direct Swift first:** A single import function switches on a detected format
and constructs the corresponding parser.

**Pattern earns its place when:** Adding a bank provider requires both
provider-specific workflow behavior and a parser choice, so the central switch
changes for every extension and can create a parser incompatible with the
provider's prepared input.

**Do not use it when:** Format selection is the only variation. A small enum or
Simple Factory remains clearer when there is no creator workflow to specialize.

**Scheduled cycle:** Days 018–020.

### Abstract Factory — regional commerce service families

**App problem:** A white-label commerce app ships in EU and LATAM configurations.
Each region requires a coherent tax calculator, payment authorizer, and receipt
formatter whose regulatory assumptions must not be mixed.

**Direct Swift first:** Construct one explicit `RegionalServices` value at the
composition root and pass its concrete services to checkout.

**Pattern earns its place when:** Multiple selectable regions repeatedly assemble
complete families and independently selecting their members permits invalid
cross-region combinations.

**Do not use it when:** There is one family, the family is compile-time fixed, or
a single configuration value can enforce coherence without factory protocols.

**Scheduled cycle:** Days 022–024.

### Builder — privacy-aware support upload

**App problem:** A support request may include a message, redacted diagnostics,
screenshots, and a recording. Consent controls which attachments may be added,
and the final multipart request must validate size and privacy rules.

**Direct Swift first:** Use a value type with an initializer and explicit
optional fields, then validate before upload.

**Pattern earns its place when:** Conditional assembly spans ordered steps,
intermediate validation matters, and one initializer either admits invalid
combinations or hides the construction flow behind many optional parameters.

**Do not use it when:** The value is flat, all required data is available at
once, and an initializer with defaults expresses every valid state.

**Scheduled cycle:** Days 025–027.

### Prototype — collaborative canvas duplication

**App problem:** A collaborative design app duplicates a canvas made of nested
reference-backed groups, media nodes, and shared style objects. The duplicate
must preserve specialized node types while isolating editable child ownership.

**Direct Swift first:** Model the graph with structs and rely on assignment and
copy-on-write collections wherever value semantics are sufficient.

**Pattern earns its place when:** A required reference boundary causes edits in
the duplicate to mutate the original, and controlled deep copying must preserve
runtime node specializations without exposing graph construction to clients.

**Do not use it when:** The model is already a value graph, shared references are
intentional, or an explicit copy initializer is shorter and type-safe.

**Scheduled cycle:** Days 029–031.

### Singleton — process-wide audio session boundary

**App problem:** A recording app coordinates one process-wide audio session
that represents a genuinely shared operating-system resource. Feature modules
must not compete over category changes, interruption handling, and activation.

**Direct Swift first:** Create one `AudioSessionController` at the composition
root and inject it into every consumer.

**Pattern earns its place when:** A platform callback or legacy entry point
cannot receive dependencies and the underlying resource must have exactly one
coordinator for the process. Normal clients still receive an injected seam.

**Do not use it when:** The service can be injected normally, multiple instances
are harmless, or global access merely avoids passing a dependency.

**Scheduled cycle:** Days 085–087.

## Structural patterns

### Adapter — payment SDK boundary

**App problem:** Checkout authorizes a domain `PaymentRequest`, while two vendor
SDKs expose incompatible asynchronous request objects, status codes, and error
taxonomies.

**Direct Swift first:** Integrate the first SDK directly inside checkout and map
its result at the call site.

**Pattern earns its place when:** A second provider makes vendor models and
errors leak through checkout tests and business logic, or provider replacement
requires edits outside the integration boundary.

**Do not use it when:** There is one stable API used in one place and a local
mapping function contains the incompatibility without leaking vendor concepts.

**Scheduled cycle:** Days 008–010.

### Bridge — notification purpose and delivery channel

**App problem:** A commerce app sends security alerts, order updates, and
promotional reminders through push, email, or in-app inbox delivery. Message
purpose and transport evolve independently.

**Direct Swift first:** Use one notification function with exhaustive switches
for purpose and channel.

**Pattern earns its place when:** Each new purpose duplicates channel behavior,
each new channel edits every purpose, and tests must exercise a growing
purpose-by-channel product matrix.

**Do not use it when:** Only one axis varies or a small closed enum switch makes
all supported combinations explicit without duplication.

**Scheduled cycle:** Days 015–017.

### Composite — nested merchandise bundles

**App problem:** A marketplace sells individual items and nested curated
bundles. Cart previews need subtotal, availability, and item-count operations
over either a leaf product or an arbitrarily nested bundle.

**Direct Swift first:** Represent products and bundles with an indirect enum and
implement recursive functions over it.

**Pattern earns its place when:** Clients repeatedly branch between leaf and
container types, new tree operations duplicate traversal, and both must be
treated uniformly at an extension boundary.

**Do not use it when:** The tree is closed and an indirect enum plus recursive
functions remains exhaustive, compact, and easier to reason about.

**Scheduled cycle:** Days 064–066.

### Decorator — composable media-upload client

**App problem:** A creator app uploads large media through one client while
selected deployments add request signing, retry, and metrics in a defined order.

**Direct Swift first:** Put the required behavior in one upload function and use
small local helpers.

**Pattern earns its place when:** Optional feature combinations create flags or
subclasses, each behavior must wrap the same interface independently, and order
changes observable retry, signing, or measurement semantics.

**Do not use it when:** Every request always needs the same pipeline or simple
function composition expresses the order without identity or lifetime concerns.

**Scheduled cycle:** Days 046–048.

### Facade — checkout placement

**App problem:** A checkout screen must reserve inventory, authorize payment,
create an order, release reservations on failure, and record analytics without
owning subsystem choreography.

**Direct Swift first:** Keep the short orchestration sequence in the screen's
model with explicit dependencies.

**Pattern earns its place when:** Multiple clients duplicate the same use-case
ordering and compensation rules, causing subsystem details and partial-failure
risk to spread beyond checkout.

**Do not use it when:** There is one caller and a short, readable sequence, or a
facade would become a generic service locator or god object.

**Scheduled cycle:** Days 043–045.

### Flyweight — venue map annotations

**App problem:** A festival map displays tens of thousands of venue and event
annotations. Each annotation has unique coordinates and status but repeats the
same category icon, label style, and accessibility metadata.

**Direct Swift first:** Store a complete annotation value for every point and
measure peak memory with a representative data set.

**Pattern earns its place when:** Measurement shows repeated intrinsic data is a
material memory cost and sharing immutable category styles produces a meaningful
reduction without obscuring ownership.

**Do not use it when:** The data set is small, Swift storage already shares the
heavy resources, or lookup and cache complexity costs more than the measured
saving.

**Scheduled cycle:** Days 074–076.

### Proxy — expiring media access

**App problem:** A subscription app exposes remote lesson videos through a
stable media interface, but playback URLs expire and access depends on the
current entitlement. Clients should not implement token refresh and permission
checks.

**Direct Swift first:** Let the playback model check entitlement, request a URL,
and retry once after expiration.

**Pattern earns its place when:** Several clients duplicate access and URL
lifecycle policy while the underlying media service must remain substitutable
behind the same interface.

**Do not use it when:** One caller owns the policy, a distinct access service is
clearer, or the goal is merely stacking optional behavior—that belongs to
Decorator.

**Scheduled cycle:** Days 050–052.

## Behavioral patterns

### Chain of Responsibility — universal-link routing

**App problem:** A commerce app receives product, order, campaign, and account
recovery links. Feature modules may handle a link or explicitly pass it onward,
and authentication prerequisites affect ordering.

**Direct Swift first:** Use one exhaustive router function with guarded branches.

**Pattern earns its place when:** Independent feature ownership causes a central
router to change constantly, handler order is a real policy, and handled versus
unhandled outcomes require explicit tests.

**Do not use it when:** The route set is small and closed, exhaustive enum
switching is valuable, or more than one handler must always observe the request.

**Scheduled cycle:** Days 053–055.

### Command — reversible timeline edits

**App problem:** A video editor applies trim, split, move, and caption changes
that must support undo, redo, keyboard invocation, and optional offline queuing.

**Direct Swift first:** Connect UI actions to focused mutation functions and
store simple previous values where one-step undo is sufficient.

**Pattern earns its place when:** The app must preserve a sequence of reversible
intent independently of the invoking UI and each operation owns different state
needed for execution and reversal.

**Do not use it when:** Actions are immediate and irreversible, or a value-state
history provides undo more safely than operation objects.

**Scheduled cycle:** Days 039–041.

### Interpreter — notification inbox filter language

**App problem:** A support team filters an on-device notification inbox with a
small expression language such as `source:billing AND unread:true`, including
parentheses and a deliberately bounded set of operators.

**Direct Swift first:** Provide typed filter controls and compose predicates from
their selected values.

**Pattern earns its place when:** Users must save and share textual expressions,
the grammar is stable and small, and tokenization, precedence, and evaluation
need explicit independent tests.

**Do not use it when:** Typed UI controls suffice, the grammar is large or
untrusted enough to need a mature parser, or arbitrary scripting is expected.

**Scheduled cycle:** Days 081–083.

### Iterator — cursor-paginated photo library

**App problem:** Screens and background jobs traverse a remote photo library
whose API returns opaque page cursors, partial pages, and rate-limit errors.

**Direct Swift first:** Keep the cursor and fetch loop in the one consuming
screen.

**Pattern earns its place when:** Multiple consumers duplicate cursor state,
termination, cancellation, and error logic, while they only need an ordered
stream of photos.

**Do not use it when:** One request returns the whole collection or one local
loop owns pagination clearly. Prefer Swift's `AsyncSequence` over a custom
iterator hierarchy when it supplies the required semantics.

**Scheduled cycle:** Days 060–062.

### Mediator — delivery checkout form

**App problem:** Address, delivery-slot, promotion, and payment modules affect
one another's validity and availability. Direct callbacks risk cycles and stale
cross-field state.

**Direct Swift first:** Let one checkout form model coordinate a small, fixed set
of child values with explicit methods.

**Pattern earns its place when:** Independently owned modules accumulate
bidirectional references, coordination rules cannot live in one participant,
and feedback-loop prevention becomes a tested responsibility.

**Do not use it when:** A single view model already expresses the interaction
clearly or the mediator would merely forward every call without owning policy.

**Scheduled cycle:** Days 067–069.

### Memento — route-planning draft history

**App problem:** A travel planner edits an itinerary with private routing hints,
lodging choices, and transport constraints. Users need bounded restore points
without exposing mutable planner internals.

**Direct Swift first:** Keep previous immutable itinerary values in a bounded
array.

**Pattern earns its place when:** The originator has private derived state that
must be restored atomically, clients must not reconstruct it, and snapshot size
and version compatibility are observable constraints.

**Do not use it when:** The state is already a small public value, persistence is
the real requirement, or Command reversal stores less state more clearly.

**Scheduled cycle:** Days 057–059.

### Observer — authenticated-session changes

**App problem:** Authentication changes must update account UI, cart ownership,
sync scheduling, and analytics independently while respecting subscription
lifetime and delivery isolation.

**Direct Swift first:** Invoke the few known consumers directly after login or
logout.

**Pattern earns its place when:** The session owner must know an expanding set of
consumers, consumers have different lifetimes, and cancellation or delivery
semantics require focused tests.

**Do not use it when:** There is one consumer, direct data flow is sufficient, or
Swift Observation already provides exactly the UI invalidation required. Prefer
`AsyncStream` for event delivery before inventing a notification framework.

**Scheduled cycle:** Days 032–034.

### State — resumable encrypted upload

**App problem:** A secure backup moves through preparing, encrypting, uploading,
paused, failed, and completed states. Only some commands and transitions are
valid in each state.

**Direct Swift first:** Use one state enum and an exhaustive transition function.

**Pattern earns its place when:** State-specific behavior and transition rules
make one reducer difficult to maintain, contradictory flags appear, or adding a
state requires editing unrelated branches throughout the uploader.

**Do not use it when:** An enum and pure transition function keep impossible
states unrepresentable. Runtime algorithm choice without lifecycle transitions
is Strategy, not State.

**Scheduled cycle:** Days 036–038.

### Strategy — delivery promise ranking

**App problem:** Checkout ranks fulfillment options by lowest cost, earliest
arrival, or lowest carbon estimate according to a user or experiment setting.

**Direct Swift first:** Use an enum and one pure sorting function with an
exhaustive switch.

**Pattern earns its place when:** Ranking policies change independently, require
separate dependencies and tests, or must be selected and supplied at runtime
without growing a central conditional.

**Do not use it when:** The policies are small, closed, and stateless enough for
an enum or injected closure. Strategy varies one algorithm; it does not model
State transitions or Bridge's two independent axes.

**Scheduled cycle:** Days 011–013.

### Template Method — reading-list import pipeline

**App problem:** A reading app imports Safari archives and Pocket exports through
the same ordered pipeline: validate, decode, normalize URLs, deduplicate, and
persist. Only specific steps differ by source.

**Direct Swift first:** Implement two explicit import functions and extract
shared free functions when duplication appears.

**Pattern earns its place when:** The algorithm order is invariant, provider
implementations duplicate that skeleton, and controlled hooks vary steps without
allowing a provider to skip validation or persistence.

**Do not use it when:** Function composition or a value containing closures is
clearer, the step order varies, or inheritance exists only to demonstrate the
pattern.

**Scheduled cycle:** Days 071–073.

### Visitor — document accessibility operations

**App problem:** A publishing app has a stable hierarchy of paragraph, link,
image, and table nodes. It frequently adds whole-document operations such as
accessibility auditing, plain-text extraction, and localization inventory.

**Direct Swift first:** Model nodes as an enum and implement each operation with
an exhaustive switch.

**Pattern earns its place when:** Node types are genuinely stable, new operations
are frequent, and operation logic otherwise scatters across every node while
requiring behavior specialized by concrete node type.

**Do not use it when:** Node types change as often as operations, an enum keeps
dispatch exhaustive, or protocol requirements colocate behavior more clearly.

**Scheduled cycle:** Days 078–080.

## Boundaries that prevent misclassification

- **Factory Method / Abstract Factory / Builder:** Factory Method lets a creator
  workflow choose one parser; Abstract Factory creates a coherent regional
  service family; Builder validates incremental assembly of one support request.
- **Strategy / State / Bridge:** Strategy swaps one ranking algorithm; State
  governs lifecycle-dependent upload behavior; Bridge composes two independently
  changing notification dimensions.
- **Decorator / Proxy / Chain of Responsibility:** Decorator stacks optional
  upload behavior; Proxy controls access to one media service; Chain offers a
  link to ordered handlers until one accepts it.
- **Command / Memento:** Command retains reversible editing intent; Memento
  captures opaque planner state. The cheaper representation wins for each undo
  requirement.
- **Factory Method / Template Method:** Factory Method varies creation inside a
  broader bank-import workflow; Template Method fixes reading-list pipeline order
  and varies selected steps. Sharing the word “import” does not make their
  responsibilities interchangeable.

## Day 006 completion check

- All 23 GoF patterns have one distinct app scenario.
- Every scenario names a direct Swift starting point.
- Every pattern has observable pressure it must prove before adoption.
- Every pattern has an explicit no-pattern exit.
- Confusable patterns have separate responsibilities and evidence.
- No scenario, type graph, code, diagram, or narrative is adapted from the
  external review catalogue.
