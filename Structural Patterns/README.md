# 🌉 Structural Patterns

Connect and compose types around app-owned boundaries, keeping external interfaces and subsystem choreography explicit.

[← Pattern catalogue](../README.md#pattern-catalogue) · [Quickstart](../README.md#quickstart) · [No-pattern decision](../Documentation/no-pattern-decision.md) · [Creational](../Creational%20Patterns/README.md) · [Behavioral](../Behavioral%20Patterns/README.md)

## How to use this category

Start with the direct baseline in the guide, then identify whether the pressure is translation, independent dimensions, uniform traversal, composition, orchestration, sharing, or guarded access.

Recommended route: [Adapter](Adapter/README.md) → [Facade](Facade/README.md) → [Decorator](Decorator/README.md).

Use [Bridge](Bridge/README.md) when two dimensions grow independently, [Composite](Composite/README.md) when leaves and containers need one operation, and [Proxy](Proxy/README.md) when a same-operation substitute must govern access or lifecycle.

## Pattern catalogue

| Pattern | Use it when | Keep it simple when |
| --- | --- | --- |
| [Adapter](Adapter/README.md) | Multiple external interfaces must translate into one app-owned contract without leaking vendor types. | One stable integration needs only a small local mapping. |
| [Bridge](Bridge/README.md) | Two dimensions both grow, combine freely, and deserve separate ownership. | Only one behavior family varies or the product matrix is small and closed. |
| [Composite](Composite/README.md) | Leaves and containers must respond uniformly without repeated client branching. | The structure is flat or traversal order is the real concern. |
| [Decorator](Decorator/README.md) | Selectable behaviors share one operation, every selected layer participates, and composition order matters. | Behavior is fixed, one guard controls access, or processing should stop at one handler. |
| [Facade](Facade/README.md) | Several clients need one stable app-level operation over a subsystem they already understand. | There is one caller or the issue is interface translation or peer coordination. |
| [Flyweight](Flyweight/README.md) | Many live objects repeat a small, immutable, exactly countable intrinsic payload. | The renderer already deduplicates resources, the live set is small, or most intrinsic data is unique. |
| [Proxy](Proxy/README.md) | A same-operation substitute must govern access or lifecycle for one subject. | Direct access is safe or independent behaviors should compose as decorators. |

## Category boundary

Structural patterns define how existing types connect, compose, traverse, share, or expose a boundary. They do not decide peer behavior or object lifecycle when a direct mapping, focused function, or closed value model remains clearer.

## Evidence and references

[Source examples](../Sources/DesignPatterns/) · [Tests](../Tests/DesignPatternsTests/) · [README experience](../Documentation/readme-experience.md)
