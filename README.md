# 📘 Design Patterns in Swift

This repository is a pragmatic, executable guide to the 23 Gang of Four design patterns in Swift. The catalogue is being rebuilt around one rule:

> A pattern earns its place only when it solves a concrete app problem more clearly than Swift's direct language and platform features.

Every canonical example starts with the simplest direct solution, shows the requirement that puts pressure on it, and documents the trade-offs of the smallest justified pattern. A documented decision to use no pattern is also a valid outcome.

## 🚧 Current status

The foundation is ready for the first pattern cycle. The repository now has one Swift Package library target, a Swift Testing target, warning-as-error build gates, and a CI workflow. Historical playground files remain outside the package until each scheduled replacement is tested and documented.

- [Foundation review](Documentation/foundation-review.md) — evidence and readiness decision for Day 007.
- [Catalogue audit](Documentation/catalogue-audit.md) — baseline status and conceptual decisions for all 23 patterns.
- [Real-app domain map](Documentation/app-domain-map.md) — concrete scenarios assigned to each pattern.
- [100-day roadmap](ROADMAP.md) — one problem, pressure, and solution cycle per pattern.

Run the package from the repository root:

```sh
swift build -Xswiftc -warnings-as-errors
swift test -Xswiftc -warnings-as-errors
```

## 🗂️ Pattern catalogue

The catalogue distinguishes historical material from canonical, tested examples. A pattern is complete only when its replacement is tested and documented. See the [catalogue audit](Documentation/catalogue-audit.md) for the decisions behind all 23 patterns.

### 🏗️ Creational patterns

Patterns that control how values and object graphs are created.

- 🧰 **Abstract Factory** — [Historical draft](Creational%20Patterns/Abstract%20Factory/TaskAbstractFactory.md) · Days 022–024
- 🛠️ **Builder** — [Historical draft](Creational%20Patterns/Builder/Builder.md) · Days 025–027
- 🏭 **Factory Method** — [Historical draft](Creational%20Patterns/Factory/TaskFactory.md) · Days 018–020
- 🧬 **Prototype** — [Historical draft](Creational%20Patterns/Prototype/Prototype.md) · Days 029–031
- 1️⃣ **Singleton** — Planned · Days 085–087

### 🌉 Structural patterns

Patterns that compose types behind focused, stable interfaces.

- 🔌 **Adapter** — [Canonical example](Structural%20Patterns/Adapter/README.md) · [Historical draft](Structural%20Patterns/Adapter/Adapter.md) · Days 008–010 ✅
- 🌁 **Bridge** — [Historical draft](Structural%20Patterns/Bridge/Bridge.md) · Days 015–017
- 🧱 **Composite** — Planned · Days 064–066
- 🎨 **Decorator** — Planned · Days 046–048
- 🏢 **Facade** — Planned · Days 043–045
- 🪶 **Flyweight** — Planned · Days 074–076
- 🛡️ **Proxy** — Planned · Days 050–052

### 🧠 Behavioral patterns

Patterns that distribute responsibilities and coordinate behavior.

- 🔗 **Chain of Responsibility** — Planned · Days 053–055
- 🎮 **Command** — Planned · Days 039–041
- 🗣️ **Interpreter** — Planned · Days 081–083
- 🔁 **Iterator** — Planned · Days 060–062
- 🤝 **Mediator** — Planned · Days 067–069
- 📸 **Memento** — Planned · Days 057–059
- 👀 **Observer** — Planned · Days 032–034
- 🚦 **State** — Planned · Days 036–038
- ♟️ **Strategy** — Planned · Days 011–013
- 📋 **Template Method** — Planned · Days 071–073
- 🚪 **Visitor** — Planned · Days 078–080

## 📐 Documentation contracts

- [Pattern README template](Documentation/pattern-readme-template.md) defines the problem-first teaching unit, tests, alternatives, and the ‘When not to use it’ section.
- [Visual style](Documentation/visual-style.md) defines the shared editorial header and Mermaid diagram contract.
- [Quality gates](Documentation/quality-gates.md) defines the local and CI commands.
- [Package boundary](Documentation/package-boundary.md) explains why canonical examples share one module.

## 📚 Resources

- [Swift documentation](https://swift.org/documentation/)
- [LinkedIn](https://www.linkedin.com/in/robertogomezm/)

## 📜 License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
