<h1 align="center">Design Patterns in Swift</h1>

<p align="center"><strong>Learn 23 GoF patterns from the app problems that make them useful — and from one case where no pattern wins.</strong></p>

<p align="center">
  <a href="https://github.com/rgmez/Design-Patterns-in-Swift/releases/tag/v1.0.0"><img alt="Release v1.0.0" src="https://img.shields.io/badge/release-v1.0.0-C2410C"></a>
  <img alt="Swift 6.0" src="https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white">
  <img alt="macOS 14 or later" src="https://img.shields.io/badge/macOS-14%2B-1F2937?logo=apple&logoColor=white">
  <a href="https://github.com/rgmez/Design-Patterns-in-Swift/actions/workflows/ci.yml"><img alt="359 tests passing" src="https://img.shields.io/badge/tests-359%20passing-C2410C?logo=githubactions&logoColor=white"></a>
  <a href="LICENSE"><img alt="MIT License" src="https://img.shields.io/badge/license-MIT-555555"></a>
</p>

<p align="center"><a href="#choose-your-path">Choose a path</a> · <a href="#quickstart">Run the examples</a> · <a href="#pattern-catalogue">Browse the catalogue</a> · <a href=".codex/skills/choose-swift-design-pattern/SKILL.md">Use the decision skill</a></p>

> **The question behind every example:** What changed in the app that makes this pattern worth introducing?

Each guide starts with direct Swift, introduces one verified requirement, and adds a pattern only when it reduces coupling, invalid state, duplicated ownership, lifecycle risk, or measured resource cost. You will see what improves, what it costs, the closest alternative, and when to keep the simpler design.

**Catalogue status:** 23 patterns complete · 359 tests passing · 1 explicit no-pattern decision · v1.0.0 released

<a id="choose-your-path"></a>

## Choose your path

- **New to design patterns?** Start with [Adapter](Structural%20Patterns/Adapter/README.md), [Strategy](Behavioral%20Patterns/Strategy/README.md), and [Observer](Behavioral%20Patterns/Observer/README.md). They introduce external boundaries, interchangeable policy, and independent subscriber lifetimes.
- **Solving a concrete app problem?** Use the [pressure-led pattern finder](Documentation/find-pattern-by-pressure.md) or jump to the [pattern catalogue](#pattern-catalogue).
- **Reviewing an architecture proposal?** Read the [no-pattern decision](Documentation/no-pattern-decision.md), then use the [`choose-swift-design-pattern` skill](.codex/skills/choose-swift-design-pattern/SKILL.md).
- **Evaluating the evidence?** Run the package locally, inspect the linked tests, and read the [complete catalogue review](Documentation/catalogue-review.md).

### A friendly first route

- 🔌 **[Adapter](Structural%20Patterns/Adapter/README.md)** — integrate incompatible payment SDKs behind one app-owned contract.
- ♟️ **[Strategy](Behavioral%20Patterns/Strategy/README.md)** — switch delivery-ranking policy without moving campaign rules into the ranker.
- 👀 **[Observer](Behavioral%20Patterns/Observer/README.md)** — deliver session changes to consumers with independent lifetimes.
- ➡️ **[No pattern](Documentation/no-pattern-decision.md)** — keep a localized product-share URL as one immutable request and one pure function.

<a id="quickstart"></a>

## Quickstart

The examples live in one Swift Package and require Swift 6.0 or later on macOS 14 or later.

```sh
swift build -Xswiftc -warnings-as-errors
swift test -Xswiftc -warnings-as-errors
```

Run one teaching area with a suite filter:

```sh
swift test -Xswiftc -warnings-as-errors --filter Adapter
```

The package contains deterministic library examples rather than live SDKs, credentials, or UI automation. Each canonical guide links to the exact source and tests behind its claims.

<a id="pattern-catalogue"></a>

## Pattern catalogue

Choose by the problem that is changing, not by the class diagram you remember.

### 🏗️ Creational — creating values and objects

| Pattern | App problem explored |
| --- | --- |
| 🧰 [Abstract Factory](Creational%20Patterns/Abstract%20Factory/README.md) | Select tax, payment, and receipt policies as one consistent regional checkout family. |
| 🛠️ [Builder](Creational%20Patterns/Builder/README.md) | Assemble a support request across screens while enforcing attachment consent and size limits. |
| 🏭 [Factory Method](Creational%20Patterns/Factory%20Method/README.md) | Let each bank provider prepare and create a normalized statement import inside a shared workflow. |
| 🧬 [Prototype](Creational%20Patterns/Prototype/README.md) | Duplicate an editable document graph, reconnect internal links, and share only immutable resources. |
| 🎙️ [Singleton](Creational%20Patterns/Singleton/README.md) | Keep one accountable owner for a process-wide audio session while confining shared lookup to a runtime callback. |

### 🌉 Structural — connecting and composing types

| Pattern | App problem explored |
| --- | --- |
| 🔌 [Adapter](Structural%20Patterns/Adapter/README.md) | Give checkout one payment contract despite incompatible provider SDKs. |
| 🌁 [Bridge](Structural%20Patterns/Bridge/README.md) | Add notification purposes and delivery channels independently. |
| 🗂️ [Composite](Structural%20Patterns/Composite/README.md) | Traverse one file or a nested workspace folder without client-side branching. |
| 🎨 [Decorator](Structural%20Patterns/Decorator/README.md) | Compose authentication, retry, and metrics around an upload in an explicit order. |
| 🏢 [Facade](Structural%20Patterns/Facade/README.md) | Give checkout, Buy Again, and payment retry one order-placement operation with consistent compensation. |
| 🪶 [Flyweight](Structural%20Patterns/Flyweight/README.md) | Share four immutable marker resources across 20,000 unique festival-map locations. |
| 🛡️ [Proxy](Structural%20Patterns/Proxy/README.md) | Guard lesson playback with subscription checks and one expired-URL replacement. |

### 🧠 Behavioral — coordinating behavior and change

| Pattern | App problem explored |
| --- | --- |
| 🔗 [Chain of Responsibility](Behavioral%20Patterns/Chain%20of%20Responsibility/README.md) | Route universal links through ordered feature handlers until one handles or rejects the request. |
| 🎮 [Command](Behavioral%20Patterns/Command/README.md) | Represent video-timeline edits from multiple entry points with bounded undo and redo. |
| 🧩 [Interpreter](Behavioral%20Patterns/Interpreter/README.md) | Parse a bounded support-inbox language with explicit expressions and positioned diagnostics. |
| 🔁 [Iterator](Behavioral%20Patterns/Iterator/README.md) | Traverse cursor-paginated photos lazily through an `AsyncSequence`. |
| 🔀 [Mediator](Behavioral%20Patterns/Mediator/README.md) | Resolve promotion-driven delivery corrections before validating payment. |
| 📸 [Memento](Behavioral%20Patterns/Memento/README.md) | Restore itinerary checkpoints without exposing the editor's private state. |
| 👀 [Observer](Behavioral%20Patterns/Observer/README.md) | Notify session consumers while respecting each subscription's lifetime. |
| 🚦 [State](Behavioral%20Patterns/State/README.md) | Keep backup transitions, UI actions, and worker behavior consistent with lifecycle phase. |
| ♟️ [Strategy](Behavioral%20Patterns/Strategy/README.md) | Switch delivery-ranking policy without moving campaign rules into the ranker. |
| 🛤️ [Template Method](Behavioral%20Patterns/Template%20Method/README.md) | Keep validation, normalization, deduplication, persistence, and reporting in one fixed order. |
| 🔎 [Visitor](Behavioral%20Patterns/Visitor/README.md) | Add operations across stable publishing elements without repeating concrete-type switches. |

### 🧭 Knowing when to stop

| Decision | App problem explored |
| --- | --- |
| ➡️ [No pattern](Documentation/no-pattern-decision.md) | Keep localized product-share URLs direct until construction gains ordered, validated stages. |

<a id="reading-guide"></a>

## How every guide works

1. **App problem** — the user outcome and invariants that matter.
2. **Direct Swift** — the smallest value, enum, function, actor, `AsyncSequence`, or platform API that already works.
3. **Turning point** — the verified requirement that creates pressure.
4. **Pattern boundary** — the responsibility that moves and the minimum Swift representation needed.
5. **Executable evidence** — exact build commands, tests, and measurements.
6. **Decision** — trade-offs, nearby alternatives, `When not to use it`, and the signal that would reverse the choice.

The diagrams explain relationships, sequences, or states. The editorial headers communicate one memorable thesis. Neither replaces the code or the tests.

## Repository map

| Location | What it contains |
| --- | --- |
| [Creational Patterns/](Creational%20Patterns/), [Structural Patterns/](Structural%20Patterns/), [Behavioral Patterns/](Behavioral%20Patterns/) | Canonical pattern guides alongside clearly marked historical material. |
| [`Sources/DesignPatterns/`](Sources/DesignPatterns/) | Package-backed implementations organized by pattern. |
| [`Tests/DesignPatternsTests/`](Tests/DesignPatternsTests/) | Swift Testing suites that verify behavior and decision boundaries. |
| [`Documentation/`](Documentation/) | Problem definitions, pressure reviews, QA evidence, and visual guidance. |
| [Historical examples](Documentation/historical-examples.md) | Superseded sketches, what they actually demonstrate, and their canonical replacements. |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | Evidence-first workflow, verification commands, README contract, and commit conventions. |

<details>
<summary><strong>Project history, QA, and contributor references</strong></summary>

### Programme and reviews

- [100-day roadmap](ROADMAP.md)
- [100-day retrospective](Documentation/retrospective.md)
- [Bonus-track plan](Documentation/bonus-track.md)
- [Bonus-track final review](Documentation/bonus-track-review.md)
- [v1.0.0 release notes](Documentation/v1.0-release-candidate.md)

### Catalogue and decision evidence

- [Starting catalogue audit](Documentation/catalogue-audit.md)
- [Complete catalogue review](Documentation/catalogue-review.md)
- [Real-app domain map](Documentation/app-domain-map.md)
- [Find a pattern by pressure](Documentation/find-pattern-by-pressure.md)
- [Pattern decision signals](Documentation/skill-decision-signals.md)
- [Independent skill scenarios](Documentation/skill-evaluation-scenarios.md)
- [Skill validation](Documentation/skill-validation.md)
- [Skill refinement](Documentation/skill-refinement.md)

### Authoring and quality system

- [Contribution guide](CONTRIBUTING.md)
- [Pattern README template](Documentation/pattern-readme-template.md)
- [README experience](Documentation/readme-experience.md)
- [Visual style](Documentation/visual-style.md)
- [Quality gates](Documentation/quality-gates.md)
- [Package boundary](Documentation/package-boundary.md)

### Review archive

[Foundation](Documentation/foundation-review.md) · [02](Documentation/week-02-review.md) · [03](Documentation/week-03-review.md) · [04](Documentation/week-04-review.md) · [05](Documentation/week-05-review.md) · [06](Documentation/week-06-review.md) · [07](Documentation/week-07-review.md) · [08](Documentation/week-08-review.md) · [09](Documentation/week-09-review.md) · [10](Documentation/week-10-review.md) · [11](Documentation/week-11-review.md) · [12](Documentation/week-12-review.md) · [Catalogue](Documentation/catalogue-review.md)

</details>

## Resources and license

- [Swift documentation](https://swift.org/documentation/)
- [Roberto Gómez on LinkedIn](https://www.linkedin.com/in/rgmez)
- [MIT License](LICENSE)
