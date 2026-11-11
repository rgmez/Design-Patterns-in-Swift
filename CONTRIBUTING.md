# 🤝 Contributing

<a id="contributing"></a>

Thanks for helping make this catalogue more useful. Contributions should improve an engineering decision, not increase the pattern count.

[Repository overview](README.md) · [Find a pattern by pressure](Documentation/find-pattern-by-pressure.md) · [README experience](Documentation/readme-experience.md) · [Visual style](Documentation/visual-style.md)

## Core rule

> A pattern earns its place only when it solves a concrete problem more clearly than Swift's direct language and platform features.

Before proposing a pattern, identify:

1. The current app requirement.
2. The smallest direct Swift or platform solution.
3. Its specific observed failure mode.
4. The responsibility that would move.
5. The test, ownership rule, type constraint, or measurement that verifies the improvement.
6. The condition that would reverse the decision.

“No pattern yet” and “insufficient evidence” are valid outcomes.

## Add or revise an example

Work in three reviewable stages when the change is substantial:

1. **Problem:** define the app scenario, direct baseline, invariants, acceptance tests, and visual thesis.
2. **Pressure:** implement or measure the requirement that makes the baseline harder to own safely.
3. **Pattern:** introduce the smallest justified boundary, complete tests and documentation, and remove comparative production code that no longer helps.

Do not create a protocol for one implementation unless it is an external boundary, a test seam, or immediate variation already demonstrated by the requirements.

## Repository structure

- `Sources/DesignPatterns/<Pattern>/` contains package-backed implementation evidence.
- `Tests/DesignPatternsTests/` contains Swift Testing suites.
- `<Category> Patterns/<Pattern>/README.md` is the canonical reader-facing guide.
- `Documentation/` contains problem definitions, pressure reviews, QA evidence, and shared authoring contracts.
- Historical sketches remain outside the Swift Package and must be clearly marked non-canonical.

## Required verification

Run from the repository root:

```sh
ruby scripts/validate_readmes.rb
swift build -Xswiftc -warnings-as-errors
swift test -Xswiftc -warnings-as-errors
git diff --check
```

Warnings are failures. Tests should prove behavior, invariants, ownership, lifecycle, ordering, diagnostics, or measured pressure rather than implementation trivia.

Use one outer Swift Testing suite per file, nested suites for behavior groups, `#expect` by default, and `#require` when later assertions depend on a prerequisite.

## Canonical README contract

Start from [`Documentation/pattern-readme-template.md`](Documentation/pattern-readme-template.md). Every guide must include:

- one editorial header, descriptive alt text, and normalized caption;
- category navigation and an `At a glance` decision summary;
- app problem, direct baseline, turning point, intent, and responsibilities;
- implementation walkthrough and accessible Mermaid explanation;
- verified run and test commands;
- trade-offs, nearby alternatives, and `When not to use it`;
- source map and contextual next/previous navigation.

Keep each prose paragraph and list item on one logical source line. Do not hard-wrap Markdown.

## Visual assets

Follow [`Documentation/visual-style.md`](Documentation/visual-style.md). Preserve the matte charcoal, white, muted gray, RG red, and warm orange-red system. Use the original RG logo without redrawing or regenerating it.

Generate the technical scene without text or logo, then add typography and the original mark deterministically. Every visual must explain the pattern; decorative concept art is not enough.

## Scope and review

- One primary pattern per example.
- Prefer value semantics, enums, functions, actors, Observation, `AsyncSequence`, protocol extensions, and native APIs when they already own the requirement.
- Keep external services, UI frameworks, persistence, networking, and concurrency outside the example unless they create the pressure being taught.
- Do not add shared registries, universal participant protocols, dependency containers, repositories, or coordinator layers to make unrelated examples look uniform.
- Do not delete historical material until its replacement is tested, documented, and linked.
- Keep private editorial drafts under ignored `Editorial/`; never force-add them.

## Commit messages

Commit subjects are written in English:

```text
[type]: <result>
```

Use `New:` for a new example or capability, `Fix:` for a correction, and `Update:` for documentation or neutral structural changes. Describe the verified result, not the activity performed.

## Final checklist

- [ ] The direct solution is visible and genuinely smaller.
- [ ] Current evidence earns the named pattern.
- [ ] The closest alternative is compared by ownership, not diagram shape.
- [ ] Tests pass without warnings and remain parallel-safe.
- [ ] Names, links, commands, diagrams, and snippets match the code.
- [ ] The guide explains cost and reversal, not only benefits.
- [ ] The diff contains no unrelated files, private drafts, or temporary artifacts.
