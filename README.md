# 📘 Design Patterns in Swift

This repository is a pragmatic, executable guide to the 23 Gang of Four design patterns in Swift. The catalogue is being rebuilt around one rule:

> A pattern earns its place only when it solves a concrete app problem more clearly than Swift's direct language and platform features.

Every canonical example starts with the simplest direct solution, shows the requirement that puts pressure on it, and documents the trade-offs of the smallest justified pattern. A documented decision to use no pattern is also a valid outcome.

## 🚧 Current status

The foundation and the first eleven pattern cycles are complete. Abstract
Factory, Adapter, Bridge, Builder, Command, Facade, Factory Method, Observer,
Prototype, State, and Strategy provide canonical, tested examples; historical
playground files remain outside the package until each scheduled replacement is
tested and documented.
The weekly reviews validate each pair's behavior and keep adjacent patterns in
their proper conceptual lanes.

- [Foundation review](Documentation/foundation-review.md) — evidence and
  readiness decision for Day 007.
- [Adapter and Strategy review](Documentation/week-02-review.md) — integration
  boundaries versus runtime behavior.
- [Bridge and Factory Method review](Documentation/week-03-review.md) —
  independent axes versus provider-owned creation.
- [Abstract Factory and Builder review](Documentation/week-04-review.md) —
  coherent families versus ordered assembly.
- [Prototype and Observer review](Documentation/week-05-review.md) — copy
  ownership versus subscription lifetime.
- [State and Command review](Documentation/week-06-review.md) — lifecycle
  behavior versus reversible intent and history ownership.
- [Catalogue audit](Documentation/catalogue-audit.md) — baseline status and
  conceptual decisions for all 23 patterns.
- [Real-app domain map](Documentation/app-domain-map.md) — concrete scenarios
  assigned to each pattern.
- [100-day roadmap](ROADMAP.md) — one problem, pressure, and solution cycle per
  pattern.

Run the package from the repository root:

```sh
swift build -Xswiftc -warnings-as-errors
swift test -Xswiftc -warnings-as-errors
```

## 🗂️ Pattern catalogue

The catalogue distinguishes historical material from canonical, tested examples. A pattern is complete only when its replacement is tested and documented. See the [catalogue audit](Documentation/catalogue-audit.md) for the decisions behind all 23 patterns.

### 🏗️ Creational patterns

Patterns that control how values and object graphs are created.

- 🧰 **Abstract Factory** — [Canonical example](Creational%20Patterns/Abstract%20Factory/README.md) · [Problem baseline](Documentation/abstract-factory-problem.md) · [Pressure review](Documentation/abstract-factory-pressure.md) · [Historical draft](Creational%20Patterns/Abstract%20Factory/TaskAbstractFactory.md) · Days 022–024 ✅
- 🛠️ **Builder** — [Canonical example](Creational%20Patterns/Builder/README.md) · [Problem baseline](Documentation/builder-problem.md) · [Pressure review](Documentation/builder-pressure.md) · [Historical draft](Creational%20Patterns/Builder/Builder.md) · Days 025–027 ✅
- 🏭 **Factory Method** — [Canonical example](Creational%20Patterns/Factory%20Method/README.md) · [Problem baseline](Documentation/factory-method-problem.md) · [Pressure review](Documentation/factory-method-pressure.md) · [Historical draft](Creational%20Patterns/Factory/TaskFactory.md) · Days 018–020 ✅
- 🧬 **Prototype** — [Canonical example](Creational%20Patterns/Prototype/README.md) · [Problem baseline](Documentation/prototype-problem.md) · [Pressure review](Documentation/prototype-pressure.md) · [Historical draft](Creational%20Patterns/Prototype/Prototype.md) · Days 029–031 ✅
- 1️⃣ **Singleton** — Planned · Days 085–087

### 🌉 Structural patterns

Patterns that compose types behind focused, stable interfaces.

- 🔌 **Adapter** — [Canonical example](Structural%20Patterns/Adapter/README.md) · [Historical draft](Structural%20Patterns/Adapter/Adapter.md) · Days 008–010 ✅
- 🌁 **Bridge** — [Canonical example](Structural%20Patterns/Bridge/README.md) · [Problem baseline](Documentation/bridge-problem.md) · [Pressure review](Documentation/bridge-pressure.md) · [Historical draft](Structural%20Patterns/Bridge/Bridge.md) · Days 015–017 ✅
- 🧱 **Composite** — Planned · Days 064–066
- 🎨 **Decorator** — Planned · Days 046–048
- 🏢 **Facade** — [Canonical example](Structural%20Patterns/Facade/README.md) · [Problem baseline](Documentation/facade-problem.md) · [Pressure review](Documentation/facade-pressure.md) · Days 043–045 ✅
- 🪶 **Flyweight** — Planned · Days 074–076
- 🛡️ **Proxy** — Planned · Days 050–052

### 🧠 Behavioral patterns

Patterns that distribute responsibilities and coordinate behavior.

- 🔗 **Chain of Responsibility** — Planned · Days 053–055
- 🎮 **Command** — [Canonical example](Behavioral%20Patterns/Command/README.md) · [Problem baseline](Documentation/command-problem.md) · [Pressure review](Documentation/command-pressure.md) · Days 039–041 ✅
- 🗣️ **Interpreter** — Planned · Days 081–083
- 🔁 **Iterator** — Planned · Days 060–062
- 🤝 **Mediator** — Planned · Days 067–069
- 📸 **Memento** — Planned · Days 057–059
- 👀 **Observer** — [Canonical example](Behavioral%20Patterns/Observer/README.md) · Days 032–034 ✅
- 🚦 **State** — [Canonical example](Behavioral%20Patterns/State/README.md) · [Problem baseline](Documentation/state-problem.md) · [Pressure review](Documentation/state-pressure.md) · Days 036–038 ✅
- ♟️ **Strategy** — [Canonical example](Behavioral%20Patterns/Strategy/README.md) · Days 011–013 ✅
- 📋 **Template Method** — Planned · Days 071–073
- 🚪 **Visitor** — Planned · Days 078–080

## 📐 Documentation contracts

- [Pattern README template](Documentation/pattern-readme-template.md) defines the problem-first teaching unit, tests, alternatives, and the ‘When not to use it’ section.
- [Visual style](Documentation/visual-style.md) defines the shared editorial header and Mermaid diagram contract.
- [Quality gates](Documentation/quality-gates.md) defines the local and CI commands.
- [Package boundary](Documentation/package-boundary.md) explains why canonical examples share one module.

## 📚 Resources

- [Swift documentation](https://swift.org/documentation/)
- [LinkedIn](https://www.linkedin.com/in/rgmez)

## 📜 License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
