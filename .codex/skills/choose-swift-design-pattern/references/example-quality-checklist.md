# Example Quality Checklist

Use this checklist to review a proposal or implementation only when the user explicitly asks for that evaluation. A decision-only request does not require implementation evidence.

- [ ] The problem is a current, concrete app requirement with observable pressure.
- [ ] The smallest direct Swift or platform baseline is stated.
- [ ] The baseline's specific failure mode and the evidence for it are named.
- [ ] Responsibility moves to a clearer owner; the pattern is not renamed branching.
- [ ] The public Swift API is minimal and expresses the actual variation.
- [ ] Ownership, lifetime, isolation, ordering, and error behavior are explicit where relevant.
- [ ] Tests prove behavior, invariants, or the boundary that justified the pattern.
- [ ] Documentation, a diagram, and `When not to use it` guidance are included when the example or repository convention requires them.
- [ ] Trade-offs state the new types, indirection, state, lifecycle, or maintenance cost.
- [ ] A concrete signal identifies when the decision should be reversed.
- [ ] The nearest alternative is named with the discriminating reason it loses.

For a decision-only request, stop after evidence, baseline, verdict, responsibility/cost, verification, closest alternative, and reconsideration signal. Do not demand an implementation, tests, diagram, or README unless the requested deliverable includes them.
