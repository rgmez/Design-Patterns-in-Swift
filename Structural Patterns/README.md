# 🌉 Structural Patterns

Connect and compose types around app-owned boundaries, keeping external interfaces and subsystem choreography explicit.

[← Pattern catalogue](../README.md#pattern-catalogue) · [Quickstart](../README.md#quickstart) · [No-pattern decision](../Documentation/no-pattern-decision.md) · [Creational](../Creational%20Patterns/README.md) · [Behavioral](../Behavioral%20Patterns/README.md)

<a id="how-to-use-this-category"></a>

## 🧭 How to use this category

Start with the direct baseline in the guide, then identify whether the pressure is translation, independent dimensions, uniform traversal, composition, orchestration, sharing, or guarded access.

Recommended route: [Adapter](Adapter/README.md) → [Facade](Facade/README.md) → [Decorator](Decorator/README.md).

Use [Bridge](Bridge/README.md) when two dimensions grow independently, [Composite](Composite/README.md) when leaves and containers need one operation, and [Proxy](Proxy/README.md) when a same-operation substitute must govern access or lifecycle.

<a id="pattern-catalogue"></a>

## 📚 Pattern catalogue

### 🔌 [Adapter](Adapter/README.md)

- **Use it when:** Multiple external interfaces must translate into one app-owned contract without leaking vendor types.
- **Keep it simple when:** One stable integration needs only a small local mapping.

### 🌁 [Bridge](Bridge/README.md)

- **Use it when:** Two dimensions both grow, combine freely, and deserve separate ownership.
- **Keep it simple when:** Only one behavior family varies or the product matrix is small and closed.

### 🗂️ [Composite](Composite/README.md)

- **Use it when:** Leaves and containers must respond uniformly without repeated client branching.
- **Keep it simple when:** The structure is flat or traversal order is the real concern.

### 🎨 [Decorator](Decorator/README.md)

- **Use it when:** Selectable behaviors share one operation, every selected layer participates, and composition order matters.
- **Keep it simple when:** Behavior is fixed, one guard controls access, or processing should stop at one handler.

### 🏢 [Facade](Facade/README.md)

- **Use it when:** Several clients need one stable app-level operation over a subsystem they already understand.
- **Keep it simple when:** There is one caller or the issue is interface translation or peer coordination.

### 🪶 [Flyweight](Flyweight/README.md)

- **Use it when:** Many live objects repeat a small, immutable, exactly countable intrinsic payload.
- **Keep it simple when:** The renderer already deduplicates resources, the live set is small, or most intrinsic data is unique.

### 🛡️ [Proxy](Proxy/README.md)

- **Use it when:** A same-operation substitute must govern access or lifecycle for one subject.
- **Keep it simple when:** Direct access is safe or independent behaviors should compose as decorators.

<a id="category-boundary"></a>

## 🎯 Category boundary

Structural patterns define how existing types connect, compose, traverse, share, or expose a boundary. They do not decide peer behavior or object lifecycle when a direct mapping, focused function, or closed value model remains clearer.

<a id="evidence-and-references"></a>

## 🔗 Evidence and references

[Source examples](../Sources/DesignPatterns/) · [Tests](../Tests/DesignPatternsTests/) · [README experience](../Documentation/readme-experience.md)
