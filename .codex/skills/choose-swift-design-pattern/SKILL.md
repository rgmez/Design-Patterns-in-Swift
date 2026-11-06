---
name: choose-swift-design-pattern
description: Evaluate whether a concrete Swift app problem has earned a GoF design pattern or should retain a direct language or platform solution. Use when choosing or reviewing a pattern from current requirements; not for generic pattern definitions or implementing a preselected design.
---

# Choose Swift Design Pattern

Assess observable design pressure in an iOS, macOS, or server-side Swift
feature and produce one reviewable recommendation. A direct Swift or platform
solution is a successful outcome. Do not introduce abstraction to anticipate
hypothetical growth.

## Decision workflow

1. **Frame the current problem.** Identify the product behavior, the code that
   owns it today, and the concrete requirement that creates pressure. Separate
   observed facts from forecasts. If a missing fact could change the decision,
   return `insufficient evidence` and name only the fact needed.
2. **Establish the direct baseline.** Start with the smallest suitable Swift or
   platform mechanism: a value type, enum, function, initializer, collection
   operation, protocol extension, actor, `AsyncSequence`, Observation, or
   native framework API. Explain why this baseline already succeeds or name
   its specific remaining failure mode.
3. **Apply the evidence gate.** Recommend a pattern only when a current
   requirement creates observable pressure, the direct baseline has a named
   failure mode, the pattern moves responsibility to a better owner, and a
   test, type constraint, ownership rule, or measurement can verify the
   improvement. If any condition is false, choose `no pattern yet`.
4. **Test the boundary.** For a pattern candidate, state what responsibility it
   would move, what dependency or behavior varies, and which owner should
   absorb that variation. Reject candidates that merely rename the same
   branches behind protocols or extra types.
5. **Discriminate the nearest alternative.** Compare the candidate with the
   closest direct design or commonly confused pattern using the requirement's
   change boundary, not class-diagram similarity. Do not return a menu when the
   evidence supports one decision.
6. **Make reversal possible.** Name the concrete future requirement or missing
   evidence that would justify revisiting the verdict. Do not generalize from
   imagined scale.

## Verdicts

Return exactly one of these outcomes:

- **Use `<Pattern>`.** The evidence gate passes and one GoF pattern has a
  clearer responsibility boundary than the direct design.
- **No pattern yet.** The direct design handles the present requirements with
  less coupling, state, indirection, or invalid lifetime.
- **Insufficient evidence.** One material fact is missing and different answers
  would lead to different verdicts. Do not invent it.

## Response contract

Keep the recommendation compact and reviewable. Report:

- **Observed pressure:** current requirement and evidence, without speculative
  growth.
- **Direct baseline:** the smallest Swift or platform design to try or retain.
- **Verdict:** one of the three outcomes above.
- **Responsibility and cost:** what moves if a pattern is used, what complexity
  it removes, and what new types, indirection, state, or lifecycle it adds. For
  `no pattern yet`, state the complexity avoided.
- **Verification:** observable checks that would prove the selected boundary.
- **Closest alternative:** the discriminating reason it loses.
- **Reconsider when:** the concrete signal that would reverse the verdict.

Do not implement the recommendation unless the user also asks for an
implementation. Do not create a protocol for one implementation unless it is
an external boundary, a test seam, or immediate variation already demonstrated
by the requirements.
