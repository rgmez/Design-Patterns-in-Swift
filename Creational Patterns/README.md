# 🏗️ Creational Patterns

Create values and objects around real construction pressure, while keeping a direct Swift baseline visible.

[← Pattern catalogue](../README.md#pattern-catalogue) · [Quickstart](../README.md#quickstart) · [No-pattern decision](../Documentation/no-pattern-decision.md) · [Structural](../Structural%20Patterns/README.md) · [Behavioral](../Behavioral%20Patterns/README.md)

<a id="how-to-use-this-category"></a>

## 🧭 How to use this category

Start with the direct solution described in each guide, then follow the turning point that makes construction a separate design concern.

Recommended route: [Builder](Builder/README.md) → [Factory Method](Factory%20Method/README.md) → [Prototype](Prototype/README.md).

Use [Abstract Factory](Abstract%20Factory/README.md) when several complete product families must vary while remaining compatible, and [Singleton](Singleton/README.md) only when one process identity must cross a construction root with no injection seam.

<a id="pattern-catalogue"></a>

## 📚 Pattern catalogue

### 🧰 [Abstract Factory](Abstract%20Factory/README.md)

- **Use it when:** Several complete product families must vary while remaining internally compatible.
- **Keep it simple when:** The family is closed, only one product varies, or one typed composition function prevents invalid combinations.

### 🛠️ [Builder](Builder/README.md)

- **Use it when:** Inputs arrive in ordered stages and partial construction has real validation or privacy rules.
- **Keep it simple when:** Defaults, optional fields, or fluent syntax are the only motivation.

### 🏭 [Factory Method](Factory%20Method/README.md)

- **Use it when:** Creator-owned preparation and product creation change together while the surrounding workflow stays fixed.
- **Keep it simple when:** Only parser selection varies or a closure keeps the variation local without invalid pairings.

### 🧬 [Prototype](Prototype/README.md)

- **Use it when:** A reference graph needs a controlled copy policy owned by each runtime subtype.
- **Keep it simple when:** Value semantics, copy-on-write collections, or ordinary reconstruction already produce an independent value.

### 🎙️ [Singleton](Singleton/README.md)

- **Use it when:** One accountable process identity must cross a construction root with no injection or registration seam.
- **Keep it simple when:** Constructor injection works or the state belongs to a user, document, window, scene, or request.

<a id="category-boundary"></a>

## 🎯 Category boundary

Creational patterns decide how values and objects are assembled, selected, copied, or owned. They do not replace the direct solution when a small switch, initializer, closure, or injected instance already keeps the construction rules clear.

<a id="evidence-and-references"></a>

## 🔗 Evidence and references

[Source examples](../Sources/DesignPatterns/) · [Tests](../Tests/DesignPatternsTests/) · [README experience](../Documentation/readme-experience.md)
