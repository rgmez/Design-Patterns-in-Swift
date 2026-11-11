# Historical Examples

These files preserve the repository's starting point. They are deliberately
outside `Sources/DesignPatterns`, are not compiled by the Swift Package, and do
not represent the current catalogue.

Use the canonical guide and its linked package source when learning or applying
a pattern. Use the historical file only to study why recognizable structure is
not enough without a real app pressure, a direct baseline, and behavioral
evidence.

| Historical area | What it actually demonstrates | Canonical replacement |
| --- | --- | --- |
| [Factory tasks](../Creational%20Patterns/Factory/TaskFactory.md) | A centralized Simple Factory switch, not Factory Method. | [Bank import Factory Method](../Creational%20Patterns/Factory%20Method/README.md) |
| [Abstract Factory tasks](../Creational%20Patterns/Abstract%20Factory/TaskAbstractFactory.md) | One task factory with alternative products, not multiple coherent families. | [Regional commerce Abstract Factory](../Creational%20Patterns/Abstract%20Factory/README.md) |
| [Task Builder](../Creational%20Patterns/Builder/Builder.md) | Fluent mutation around a flat value that a Swift initializer can express. | [Privacy-aware support upload Builder](../Creational%20Patterns/Builder/README.md) |
| [Task Prototype](../Creational%20Patterns/Prototype/Prototype.md) | Explicit cloning without a reference-ownership problem. | [Editable document graph Prototype](../Creational%20Patterns/Prototype/README.md) |
| [External task Adapter](../Structural%20Patterns/Adapter/Adapter.md) | A recognizable target/adaptee skeleton with no realistic SDK contract pressure. | [Payment SDK Adapter](../Structural%20Patterns/Adapter/README.md) |
| [Task Bridge collection](../Structural%20Patterns/Bridge/Bridge.md) | Three composition sketches, including Strategy-like variation, without two proven independent axes. | [Notification purpose/channel Bridge](../Structural%20Patterns/Bridge/README.md) |

The evidence behind each classification is preserved in the
[initial catalogue audit](catalogue-audit.md#existing-examples). Historical code
should not be copied into app targets, used to count pattern coverage, or cited
as passing package tests.
