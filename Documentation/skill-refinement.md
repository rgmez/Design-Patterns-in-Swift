# 📖 Pattern-Selection Skill Refinement

<a id="pattern-selection-skill-refinement"></a>

Refinement date: 2026-11-09

This report closes Internal Day 098 by applying only the corrections supported by the [Day 097 validation](skill-validation.md). The skill already chose the right verdict and responsibility boundary in all four forward tests. This day does not add new pattern triggers, examples, source code, or catalogue rules.

[← Repository overview](../README.md) · [Pattern catalogue](../README.md#pattern-catalogue) · [Reading guide](../README.md#reading-guide)

## Evidence reviewed

Two responses had useful but imprecise output shapes:

1. The Adapter answer rejected a direct enum and switch even though Facade was the more instructive neighbouring boundary for an external SDK integration.
2. The State answer chose the correct lifecycle owner but prescribed a private protocol and one concrete type per state in a decision-only response.

Neither observation invalidated its verdict. They showed that the response contract needed to distinguish architectural selection from implementation encoding, and to define how the closest alternative is selected.

## Narrow corrections

The [skill entry point](../.codex/skills/choose-swift-design-pattern/SKILL.md) now makes three constraints explicit:

- If a request names a competing pattern, compare it. Otherwise inspect the candidate's canonical neighbour group and prefer a plausible boundary from that group over an incidental implementation variant.
- A decision-only answer describes ownership and cost without naming protocols, classes, one type per participant, or another concrete Swift representation.
- Avoiding an implementation choice must not downgrade an evidence-backed pattern. The verdict selects a responsibility boundary; representation is a separate decision for an implementation request.

These are output and reasoning constraints, not new catalogue facts. The existing evidence gate, three verdicts, progressive references, and reversal requirement remain unchanged.

## Independent forward tests

Fresh evaluators received only the revised skill, one unfamiliar prompt, and the references routed by the skill. They did not receive the scenario rubric, previous responses, or suspected corrections.

| Scenario | Required refinement evidence | Observed result | Result |
| --- | --- | --- | --- |
| Carrier SDK boundary | Keep Adapter, compare the incompatible-contract boundary with a plausible neighbour. | Chose Adapter, kept carrier translation at each external boundary, and rejected Facade because one entry point would not own vocabulary translation. | Pass |
| Offline map lifecycle | Keep State without prescribing its Swift type shape. | Chose State, assigned transitions, UI actions, and worker decisions to the current lifecycle owner, rejected Strategy, and described only indirection and graph-visibility costs. | Pass |

The refinement loop also caught two insufficient formulations before closure. One still allowed Adapter to compare itself with an incidental provider-selection Strategy; another made representation neutrality sound like a reason to return `No pattern yet`. Those outputs were rejected rather than counted as passing evidence. The final wording corrects the general ambiguity without copying either scenario into the skill.

Accepted evaluation outputs and the validation receipt remain ignored under `.build/automation/day-098/`. They are reproducibility aids, not maintained product documentation.

## Validation

```sh
swift build -Xswiftc -warnings-as-errors
swift test -Xswiftc -warnings-as-errors
git diff --check
git check-ignore -v Editorial/
git check-ignore -v .build/automation/day-098/forward-tests-final.md
```

- The skill frontmatter parses as a mapping containing only `name` and `description`.
- The official `skill-creator` quick validator passes using the same temporary local YAML compatibility shim documented on Day 097 because PyYAML remains unavailable.
- The warning-as-error build succeeds.
- The complete suite passes 350 tests in 188 suites.
- The accepted evaluation artifact and Public Day 027 draft remain ignored.
- No production Swift, test, pattern README, or visual changes in this day.

## Completion decision

Internal Day 098 is complete. The skill keeps its evidence-led decisions while making neighbour comparisons more useful and decision-only answers less prescriptive. Public Day 027 is drafted privately from verified repository evidence; publication remains a separate manual decision.

Day 099 will run release-candidate QA and prepare release notes. It has not started, and no tag or release has been created.
