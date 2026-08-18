# Pattern Visual Style

This is the single visual contract for the pattern catalogue. Pattern READMEs
combine two complementary visuals:

- An editorial header that attracts attention and communicates one memorable
  thesis.
- A Mermaid diagram that precisely explains the implementation's relationships,
  creation flow, sequence, or states.

Neither replaces the other. Do not create pattern-specific visual guidelines or
duplicate this specification elsewhere.

## Master assets

| Asset | Purpose | Rule |
| --- | --- | --- |
| [`adapter-header-reference.png`](Assets/Brand/adapter-header-reference.png) | Approved composition and quality reference | Compare every final header against it; do not edit it. |
| [`rg-logo.png`](Assets/Brand/rg-logo.png) | Original RG brand mark | Composite this exact file; never redraw, regenerate, crop, stretch, or rewrite it. |

Both files are byte-for-byte local copies of the approved source assets. Keeping
them in the repository makes reviews reproducible without depending on a local
visualization workspace.

## Editorial header contract

Every final header must:

1. Use a panoramic 16:9 canvas. The approved reference is 1672 × 941 pixels.
2. Use a matte black or charcoal background with a very subtle red technical
   grid.
3. Place the typographic block in the upper-left quadrant with margins and scale
   close to the reference.
4. Set a small warm orange-red eyebrow containing the category, `PATTERN`, and
   `SWIFT`.
5. Set the pattern name large, white, uppercase, and visually dominant.
6. Put a short thesis below it: the first phrase in white and its key concept in
   warm orange-red.
7. Add one secondary line in muted gray. No other explanatory copy belongs in
   the image.
8. Composite the original RG logo in the upper-right corner at a consistent size
   and margin.
9. Reserve the middle and lower band for one purposeful technical scene.
10. Give that scene either an obvious left-to-right flow or one unmistakable
    central focus.

The result should feel like one collection: premium editorial technical
illustration, disciplined Swiss composition, and restrained cinematic depth.
Use dark industrial materials and precise red accents rather than generic
concept art.

## Closed palette

- Matte black and charcoal for the canvas and primary materials.
- White for the pattern name and primary thesis.
- Muted gray for secondary text and supporting surfaces.
- RG red and warm orange-red for the eyebrow, key concept, flow, and controlled
  accents.

Do not introduce blue, purple, green, rainbow gradients, or familiar SaaS/AI
gradient palettes.

## One metaphor, matched to the category

The scene must make the pattern's job understandable without a paragraph. Change
the metaphor between patterns, not the visual system.

- **Creational:** construction, controlled selection, assembly, or a mould.
- **Structural:** connections, layers, wrappers, composition, or boundaries.
- **Behavioral:** flow, states, signals, coordination, or responsibility transfer.

Every object must contribute to that metaphor. Avoid robots, generic people,
brains, hands, decorative circuit-board wallpaper, neon cyberpunk, floating
dashboards, stock 3D icons, toy-like isometric objects, excessive glow, and props
without explanatory purpose.

## Deterministic production workflow

1. Write the visual thesis from behavior already implemented and tested.
2. Choose one category-appropriate metaphor and specify the direction or focal
   point.
3. Generate one 16:9 scene **without text, logo, lettering, or marks**. Do not
   request multiple variants by default.
4. Inspect the scene and correct one specific defect per iteration.
5. Add the eyebrow, pattern name, thesis, secondary line, and original logo in a
   deterministic layout step. The image generator must never handle the logo or
   final typography.
6. Compare the composed result with the approved Adapter reference using the
   five-part review below.
7. Save the accepted file at
   `Documentation/Assets/Patterns/<category>/<pattern>-header.png`, using
   lowercase kebab-case for category and pattern.
8. Add the header to the pattern `README.md` with meaningful alt text and a
   one-sentence caption.

Keep only the cared-for proposal and the files required to reproduce or consume
it. Iteration debris and unused duplicate formats do not belong in the pattern
directory.

## Five-part visual review

A header is complete only when all five answers are yes:

- **Composition:** Does it preserve the upper text band, upper-right logo, and
  central/lower technical scene with the reference's proportions and margins?
- **Palette:** Is it confined to charcoal, white, muted gray, RG red, and warm
  orange-red?
- **Hierarchy:** Are the eyebrow, dominant name, two-part thesis, secondary line,
  and scene readable in that order without competing decoration?
- **Logo:** Is the original asset undistorted, unmodified, and consistently
  positioned?
- **Detail:** Is there enough industrial detail to explain the metaphor without
  noise, fake code, or generic concept-art elements?

If the header looks as though it belongs to another collection, reject it even
when it is attractive on its own.

## Technical diagram contract

Use Mermaid inside the canonical pattern `README.md` when nodes, relationships,
states, or sequences are sufficient:

- A creation flow for creational patterns.
- A relationship or composition diagram for structural patterns.
- A sequence or state diagram for behavioral patterns.

Use names from the real app domain, show only relationships necessary to explain
the implementation, and validate that Mermaid renders. Follow every diagram with
a paragraph explaining what matters and a plain-language accessible description
of the same information. Do not add an SVG copy unless a real consumer requires
one.

## Definition of Done

Before a pattern's visual work is marked complete, verify:

- The editorial header passes the five-part comparison against the approved
  Adapter reference.
- The final file follows the required path and naming convention.
- The generator never recreated the typography or logo.
- The original logo remains exact and undistorted.
- The README has descriptive alt text and a one-sentence caption.
- The Mermaid diagram renders, matches real Swift type names and behavior, and
  includes an equivalent accessible description.
