# Design Patterns in Swift

Learn design patterns by following the app problems that make them useful.

This guide explores the 23 Gang of Four patterns through concrete Swift examples:
checkout payments, video editing, file uploads, session changes, and more.
**16 examples are implemented and tested; 7 are planned.**

The central question is simple:

> What changed in the app that makes this pattern worth introducing?

Each example begins with a direct Swift solution. A new requirement reveals its
limits, then a pattern introduces a focused way to handle that change. You will
see what improves, what complexity it adds, and when to keep the simpler design.

## Start here

You can read each example independently. If you are new to patterns, start with
these three:

| Example | The question it answers | What you will learn |
| --- | --- | --- |
| [Adapter](Structural%20Patterns/Adapter/README.md) | How can checkout work with two incompatible payment SDKs? | Translate each provider's requests, results, and errors into one app-owned contract. |
| [Strategy](Behavioral%20Patterns/Strategy/README.md) | How can checkout change the way it ranks delivery options? | Keep interchangeable ranking rules and their inputs together. |
| [Observer](Behavioral%20Patterns/Observer/README.md) | How can screens react to session changes for only as long as they need to? | Separate a session change from the lifetime of its subscribers. |

Together, they show three different reasons to introduce a pattern: integrating
an external API, varying a business rule, and coordinating independent consumers.

## How to read an example

Follow the same story in every pattern README:

1. **Understand the app problem.** What does the user need, and which rules must
   the implementation preserve?
2. **Look at the direct solution.** Start with ordinary Swift: a value type, a
   function, an enum, or a small service.
3. **Find the turning point.** A concrete requirement changes. Identify what the
   direct solution now has to know, repeat, or coordinate.
4. **Follow the pattern.** Read the responsibilities, implementation walkthrough,
   and diagram to see where that knowledge moves.
5. **Judge the trade-off.** Check the tests, alternatives, and “When not to use
   it” section before deciding whether the pattern fits your own app.

For example, the first payment SDK can be called directly from checkout. Adding
a second SDK brings different request formats, success responses, and errors.
Adapter moves those translations into one adapter per provider, so checkout can
work with a stable payment operation. That earns a boundary, but also adds types
and mappings to maintain. With one simple integration, the direct approach may
still be enough.

A pattern describes how responsibilities fit together. In Swift, the example
may use structs, closures, protocols, or an `AsyncSequence`; it does not need to
reproduce a class hierarchy from a textbook.

## Run the examples

The implemented examples live in one Swift Package. You need **Swift 6.0 or
later**; the package declares **macOS 14 or later** as its supported platform.
From the repository root, run:

```sh
swift build -Xswiftc -warnings-as-errors
swift test -Xswiftc -warnings-as-errors
```

The first command compiles the examples together. The second runs their
behavioral tests. Both treat compiler warnings as errors, matching CI.

To focus on the Adapter suites:

```sh
swift test -Xswiftc -warnings-as-errors --filter Adapter
```

These are library examples exercised through tests. Each pattern README links
to its implementation and test files, and explains which behaviors to inspect.

## Find a pattern by its problem

The tables below link to the implemented guides. Pick the app problem closest
to yours; the category helps explain what kind of responsibility changes.

### Creating values and objects

Creational patterns help when creation itself has rules: selecting related
services, assembling a request over time, or duplicating an editable object graph.

| Pattern | App problem explored |
| --- | --- |
| [Abstract Factory](Creational%20Patterns/Abstract%20Factory/README.md) | Select tax, payment, and receipt policies as one consistent regional checkout family. |
| [Builder](Creational%20Patterns/Builder/README.md) | Assemble a support request across screens while enforcing attachment consent and size limits. |
| [Factory Method](Creational%20Patterns/Factory%20Method/README.md) | Let each bank provider prepare and create a normalized statement import within a shared workflow. |
| [Prototype](Creational%20Patterns/Prototype/README.md) | Duplicate an editable document, reconnect its internal links, and share only the resources that should remain shared. |

**Planned:** Singleton.

### Connecting and composing types

Structural patterns help when existing parts need to work together through a
clear boundary, or when their combinations need to change independently.

| Pattern | App problem explored |
| --- | --- |
| [Adapter](Structural%20Patterns/Adapter/README.md) | Give checkout one payment contract despite incompatible provider SDKs. |
| [Bridge](Structural%20Patterns/Bridge/README.md) | Add notification purposes and delivery channels independently. |
| [Decorator](Structural%20Patterns/Decorator/README.md) | Compose authentication, retry, and metrics around an upload, with explicit ordering. |
| [Facade](Structural%20Patterns/Facade/README.md) | Give checkout, Buy Again, and payment retry one order-placement operation that coordinates inventory, payment, and cleanup. |
| [Proxy](Structural%20Patterns/Proxy/README.md) | Guard lesson playback with subscription access checks and one expired-URL replacement. |

**Planned:** Composite, Flyweight.

### Coordinating behavior and change

Behavioral patterns help decide who handles an event, how behavior varies, and
who owns subscriptions, traversal, or history.

| Pattern | App problem explored |
| --- | --- |
| [Chain of Responsibility](Behavioral%20Patterns/Chain%20of%20Responsibility/README.md) | Route universal links through ordered feature handlers, stopping when one handles or rejects the request. |
| [Command](Behavioral%20Patterns/Command/README.md) | Represent video timeline edits from multiple entry points and support bounded undo and redo. |
| [Iterator](Behavioral%20Patterns/Iterator/README.md) | Traverse cursor-paginated photos lazily through an `AsyncSequence`. |
| [Memento](Behavioral%20Patterns/Memento/README.md) | Save and restore itinerary checkpoints without exposing the editor's private state. |
| [Observer](Behavioral%20Patterns/Observer/README.md) | Notify independent session consumers while respecting each subscription's lifetime. |
| [State](Behavioral%20Patterns/State/README.md) | Keep backup actions, worker behavior, and pause/resume rules consistent with the current lifecycle phase. |
| [Strategy](Behavioral%20Patterns/Strategy/README.md) | Switch delivery ranking policies without moving campaign-specific rules into the ranker. |

**Planned:** Interpreter, Mediator, Template Method, Visitor.

## Where to find things

| Location | What it contains |
| --- | --- |
| `Creational Patterns/`, `Structural Patterns/`, `Behavioral Patterns/` | The pattern READMEs linked above, alongside historical material. Start with a README. |
| [`Sources/DesignPatterns/`](Sources/DesignPatterns/) | The implemented examples compiled by the package, organized by pattern. |
| [`Tests/DesignPatternsTests/`](Tests/DesignPatternsTests/) | Swift Testing suites that verify the examples' behavior. |
| [`Documentation/`](Documentation/) | Supporting problem analyses, design decisions, and progress reviews. |

Some older `.md` examples and playground files remain for reference. They are
outside the Swift Package. The linked pattern READMEs describe the current,
tested implementations; a planned pattern does not yet have a tested replacement.

## Follow the series or contribute

The learning guides above are the entry point. Use these supporting documents
when you want to understand the series plan or add an example:

- [100-day roadmap](ROADMAP.md): the sequence of problem, changing requirement,
  and solution work for all 23 patterns, with review milestones.
- [Catalogue audit](Documentation/catalogue-audit.md): the starting assessment
  of the historical examples and the decisions behind their replacements.
- [App domain map](Documentation/app-domain-map.md): the scenarios chosen for
  each pattern.
- [Pattern README template](Documentation/pattern-readme-template.md): the
  structure used to explain and evaluate an example.
- [Quality gates](Documentation/quality-gates.md) and
  [package boundary](Documentation/package-boundary.md): how examples are
  compiled, tested, and organized.
- [Visual style](Documentation/visual-style.md): conventions for headers and
  diagrams.

Review evidence is available in the [foundation review](Documentation/foundation-review.md)
and the weekly reviews:
[02](Documentation/week-02-review.md) ·
[03](Documentation/week-03-review.md) ·
[04](Documentation/week-04-review.md) ·
[05](Documentation/week-05-review.md) ·
[06](Documentation/week-06-review.md) ·
[07](Documentation/week-07-review.md) ·
[08](Documentation/week-08-review.md) ·
[09](Documentation/week-09-review.md).

## Resources and license

- [Swift documentation](https://swift.org/documentation/)
- [Roberto Gómez on LinkedIn](https://www.linkedin.com/in/rgmez)

Licensed under the [MIT License](LICENSE).
