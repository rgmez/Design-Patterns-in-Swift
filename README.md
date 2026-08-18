# Design Patterns in Swift

This repository is a pragmatic, executable guide to the 23 Gang of Four design patterns in Swift. The catalogue is being rebuilt around one rule:

> A pattern earns its place only when it solves a concrete app problem more clearly than Swift's direct language and platform features.

Every canonical example starts with the simplest direct solution, shows the requirement that puts pressure on it, and documents the trade-offs of the smallest justified pattern. A documented decision to use no pattern is also a valid outcome.

## Current status

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

## Catalogue

The links below distinguish historical material from canonical, tested examples. A pattern is not marked complete merely because a directory or an old Swift file exists.

### Creational

- **Abstract Factory** — [historical draft](Creational%20Patterns/Abstract%20Factory/TaskAbstractFactory.md); scheduled for replacement on Days 022–024.
- **Builder** — [historical draft](Creational%20Patterns/Builder/Builder.md); scheduled for a direct-Swift reframe on Days 025–027.
- **Factory Method** — [historical draft](Creational%20Patterns/Factory/TaskFactory.md); scheduled for replacement on Days 018–020.
- **Prototype** — [historical draft](Creational%20Patterns/Prototype/Prototype.md); scheduled for a value-semantics reframe on Days 029–031.
- **Singleton** — scheduled for Days 085–087; see the [catalogue audit](Documentation/catalogue-audit.md#complete-gof-catalogue).

### Structural

- **Adapter** — [historical draft](Structural%20Patterns/Adapter/Adapter.md); first canonical cycle on Days 008–010.
- **Bridge** — [historical draft](Structural%20Patterns/Bridge/Bridge.md); scheduled for replacement on Days 015–017.
- **Composite** — scheduled for Days 064–066; see the [catalogue audit](Documentation/catalogue-audit.md#complete-gof-catalogue).
- **Decorator** — scheduled for Days 046–048; see the [catalogue audit](Documentation/catalogue-audit.md#complete-gof-catalogue).
- **Facade** — scheduled for Days 043–045; see the [catalogue audit](Documentation/catalogue-audit.md#complete-gof-catalogue).
- **Flyweight** — scheduled for Days 074–076; see the [catalogue audit](Documentation/catalogue-audit.md#complete-gof-catalogue).
- **Proxy** — scheduled for Days 050–052; see the [catalogue audit](Documentation/catalogue-audit.md#complete-gof-catalogue).

### Behavioral

- **Chain of Responsibility** — scheduled for Days 053–055; see the [catalogue audit](Documentation/catalogue-audit.md#complete-gof-catalogue).
- **Command** — scheduled for Days 039–041; see the [catalogue audit](Documentation/catalogue-audit.md#complete-gof-catalogue).
- **Interpreter** — scheduled for Days 081–083; see the [catalogue audit](Documentation/catalogue-audit.md#complete-gof-catalogue).
- **Iterator** — scheduled for Days 060–062; see the [catalogue audit](Documentation/catalogue-audit.md#complete-gof-catalogue).
- **Mediator** — scheduled for Days 067–069; see the [catalogue audit](Documentation/catalogue-audit.md#complete-gof-catalogue).
- **Memento** — scheduled for Days 057–059; see the [catalogue audit](Documentation/catalogue-audit.md#complete-gof-catalogue).
- **Observer** — scheduled for Days 032–034; see the [catalogue audit](Documentation/catalogue-audit.md#complete-gof-catalogue).
- **State** — scheduled for Days 036–038; see the [catalogue audit](Documentation/catalogue-audit.md#complete-gof-catalogue).
- **Strategy** — scheduled for Days 011–013; see the [catalogue audit](Documentation/catalogue-audit.md#complete-gof-catalogue).
- **Template Method** — scheduled for Days 071–073; see the [catalogue audit](Documentation/catalogue-audit.md#complete-gof-catalogue).
- **Visitor** — scheduled for Days 078–080; see the [catalogue audit](Documentation/catalogue-audit.md#complete-gof-catalogue).

## Documentation contracts

- [Pattern README template](Documentation/pattern-readme-template.md) defines the problem-first teaching unit, tests, alternatives, and the ‘When not to use it’ section.
- [Visual style](Documentation/visual-style.md) defines the shared editorial header and Mermaid diagram contract.
- [Quality gates](Documentation/quality-gates.md) defines the local and CI commands.
- [Package boundary](Documentation/package-boundary.md) explains why canonical examples share one module.

## Resources

- [Swift documentation](https://swift.org/documentation/)
- [LinkedIn](https://www.linkedin.com/in/robertogomezm/)

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
