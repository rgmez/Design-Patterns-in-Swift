# Catalogue Guidance

Use this map when two names seem plausible. Ask the discriminating question about the current change boundary; do not choose from class-diagram resemblance.

| Nearby choices | Discriminating question |
| --- | --- |
| Simple Factory / Factory Method / Abstract Factory | Is the change central selection, creator-owned construction inside a workflow, or selection of a coherent product family? |
| Builder / State | Are transitions constructing a value that does not exist yet, or changing the behavior of an existing context? |
| Strategy / State / Bridge | Does the caller choose one policy, does event history choose behavior, or do two independent dimensions combine? |
| Decorator / Proxy / Chain of Responsibility | Must all selected wrappers run, must one substitute govern one subject, or must one ordered handler make the terminal decision? |
| Command / Memento | Must history preserve intent and reversal data, or an opaque snapshot of complete owner state? |
| Adapter / Facade / Mediator | Is the boundary translating incompatible vocabulary, simplifying a subsystem entry point, or coordinating peer reactions over time? |
| Composite / Iterator / Visitor | Is the need uniform part-whole behavior, controlled value production order, or new operations over stable element kinds? |
| Template Method / Strategy / Factory Method | Is one step inside a fixed algorithm varying, the whole behavior replaceable, or one product created inside a workflow? |

## Reading route

Open [decision-matrix.md](decision-matrix.md) first when the requirement is known but the candidate boundary is not. Use its pressure, baseline, and rejection columns to keep the direct Swift design visible and to reject premature structure.

Open the linked canonical README from the matrix when one candidate survives: it contains the app problem, turning point, implementation ownership, tests, trade-offs, alternatives, and `When not to use it` guidance. The README is the evidence to review before implementation; this map does not replace it.

If the discriminating question cannot be answered from current evidence, return `Insufficient evidence` and name the one missing fact. If the direct baseline has no specific failure mode, return `No pattern yet`.
