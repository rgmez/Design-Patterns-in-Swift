# Pattern-Selection Skill Validation

Validation date: 2026-11-08

This report closes Internal Day 097 by validating
`choose-swift-design-pattern` as both a skill package and a decision workflow.
The evaluation uses the four unfamiliar app prompts defined on Day 093, but
keeps their expected answers and rubrics away from the agents until after each
response is complete.

## Validation boundary

This day evaluates the current skill; it does not refine it. Two independent
agents each received only two prompts, the skill path, and an instruction not
to read the scenario specification or another result. They ran in fresh
contexts and loaded only the references routed by the skill.

The raw responses and validation receipt remain outside the versioned evidence
tree under `.build/automation/day-097/`, which is ignored by Git:

| Local artifact | SHA-256 |
| --- | --- |
| `forward-tests-ab.md` | `c4f8ed65466094f47a19f0be948b340d3097662cc3891fcda2146db5af1e0a2d` |
| `forward-tests-cd.md` | `e2662e10097d258a9b388b8cb151e2fd08c7372e8162018b8d30a4ae0e1ad872` |
| `validation.txt` | `f1801e7c29288c87523c1a0da6491da07c4925a9a2cdbba4788c18945f353805` |

These local files are reproducibility aids, not product documentation. This
report records the durable result without copying generated answers into the
skill or teaching them as hidden examples.

## Structural validation

The official `skill-creator` quick validator reports `Skill is valid!`. Its
frontmatter, naming, required fields, and unfinished-placeholder checks pass.
The installed validator imports `PyYAML`, which is absent from the environment,
so it ran with a temporary minimal `yaml.safe_load` compatibility module outside
the repository. Ruby's standard YAML parser independently confirmed that the
frontmatter is a mapping containing only `name` and `description`.

Manual structural review also confirms:

- the description distinguishes pattern selection and review from definitions
  and implementation of an already selected pattern;
- `SKILL.md` exposes the evidence gate and all three verdicts before routing to
  optional detail;
- every reference is linked from the entry point at the point where it becomes
  relevant;
- no scaffold placeholder, duplicated README, script, asset, or unused resource
  remains; and
- the agent metadata stays consistent with the skill's evidence-first purpose.

## Forward-test results

A scenario passes only when both its verdict and responsibility boundary are
correct. Exact wording, headings, and type counts are not scored.

| Scenario | Observed verdict | Boundary evidence | Result |
| --- | --- | --- | --- |
| Carrier SDK boundary | Use Adapter | Provider-owned request, unit, async, result, and error translation keeps carrier types out of checkout. | Pass |
| Offline map lifecycle | Use State | Event history owns transitions, UI actions, and worker decisions; callers do not select behavior. | Pass |
| Campaign invite URL | No pattern yet | Immutable validated input plus `URLComponents` already handles the added optional value without partial lifetime. | Pass |
| Document export axes | Use Bridge | Content intent and delivery destination remain independently owned axes that compose at runtime. | Pass |

All four responses also state a direct Swift baseline, the cost of the verdict,
observable verification, one losing alternative, and a concrete reversal
signal. None returns a pattern menu, invents a requirement, leaks a vendor type,
adds a registry, or recommends Builder for fluent syntax.

## Evidence to refine on Day 098

The tests pass, but two output-shape observations deserve narrow review before
the skill is considered finished:

1. The Adapter response compares the recommendation with the direct enum and
   switch rather than explicitly exercising the Adapter-versus-Facade boundary.
   That is a valid closest alternative, but it leaves the intended neighbour
   distinction implicit.
2. The State response describes a protocol and one concrete type per state even
   though the request asks for a decision, not an implementation. The boundary
   is correct, but the representation is more prescriptive than the verdict
   requires.

Day 098 should decide whether these are prompt-specific choices or whether the
skill needs a small clarification: prefer the most plausible competing boundary
when a neighbour is genuinely in play, and avoid prescribing a canonical type
shape in decision-only answers. It must not add examples from these prompts to
the skill or turn the response contract into a fixed template.

## Repository validation

```sh
swift build -Xswiftc -warnings-as-errors
swift test -Xswiftc -warnings-as-errors
git diff --check
git check-ignore -v Editorial/
git check-ignore -v .build/automation/day-097/forward-tests-ab.md
```

- The warning-as-error build succeeds.
- The complete suite passes 350 tests in 188 suites.
- The raw evaluation artifacts and `Editorial/` remain ignored.
- No production Swift, test, pattern README, visual, or skill instruction changes
  are part of this validation day.

## Completion decision

Internal Day 097 is complete: the skill is structurally valid and all four
independent forward tests make the correct evidence-based decision. The two
observed output-shape issues are bounded refinement inputs, not failed verdicts.

Day 098 will refine only what these results justify. It has not started, and it
is the next editorial milestone; this day does not create or update a LinkedIn
draft.
