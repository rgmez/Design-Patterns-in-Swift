# README Experience

This document defines the reading experience for the repository landing page and the 23 canonical pattern guides. It complements the visual asset contract in [`visual-style.md`](visual-style.md); it does not replace it.

## Mode and goal

The documentation uses **Read** mode: a visitor should understand the decision, find a relevant example, and reach executable evidence without decoding the repository structure first.

The root README acts as the catalogue landing page. Pattern READMEs act as self-contained decision guides.

## Root README hierarchy

The landing page follows this order:

1. Product name, concise promise, release/toolchain/CI/license status, and primary navigation.
2. The evidence-first thesis and current catalogue status.
3. Routes for new readers, problem-led readers, reviewers, and people who want to run the package.
4. Quickstart commands.
5. The complete pattern catalogue organized by change boundary.
6. The shared reading model and repository map.
7. Project history and contributor evidence inside a collapsed disclosure.

Internal programme artifacts must not compete with the catalogue in the first reading path.

## Canonical pattern hierarchy

Every pattern guide begins with:

1. Pattern name and semantic icon.
2. Editorial header and normalized caption.
3. Category and navigation back to the catalogue, reading guide, and quickstart.
4. An `At a glance` block covering the problem, direct baseline, evidence that earns the pattern, and the condition that keeps the direct solution.
5. The full problem → direct Swift → turning point → pattern → evidence → trade-off story.

The summary must help a returning reader decide whether to continue; it must not replace the detailed evidence below it.

## Markdown rules

- Keep each prose paragraph and list item on one logical source line. Do not hard-wrap at a fixed column.
- Preserve semantic heading levels; do not use bold text as a heading substitute.
- Use tables only for compact comparisons or exact mappings. Prefer lists for narrative summaries and mobile reading.
- Keep code fences short, executable, and synchronized with source.
- Use `<details>` only for genuinely secondary material, never to hide the core decision or accessibility text.
- Give every image useful alt text and every editorial header one normalized `> **Caption:**` line.
- Keep emoji limited to the established semantic pattern and section icons.
- Use stable repository anchors for cross-guide navigation.
- Do not add decorative badges to individual pattern guides; status badges belong to the catalogue landing page.

## Accessibility and responsive reading

- The first meaningful text must not depend on an image.
- Image captions and Mermaid accessible descriptions remain required.
- Two-column tables are preferred; wider tables must carry exact information that would be harder to scan as prose.
- Links must name their destination or action instead of using “here”.
- Summary language must distinguish “use this pattern” from “this is the only implementation”.

## Verification

Before merging a README presentation change:

1. Render the root README and at least one short and one long pattern guide with GitHub's Markdown renderer.
2. Inspect the repository page at desktop and narrow mobile widths.
3. Confirm all local links, image targets, code fences, and Mermaid fences.
4. Confirm every canonical guide has one caption, one category, one catalogue navigation row, and one `At a glance` section.
5. Run the Impeccable detector once over the changed Markdown targets and resolve applicable findings.
