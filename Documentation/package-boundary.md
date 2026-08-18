# Swift Package Boundary

The repository now has one Swift Package library target for canonical pattern
examples:

```text
DesignPatternsInSwift
└── Sources
    └── DesignPatterns
```

The target intentionally starts without a public API. Adding catalogue types,
protocols, or placeholder examples merely to populate the module would create
structure before a real example needs it.

## Decision

All reviewed examples will compile together inside the single `DesignPatterns`
module. A pattern does not receive its own target, framework, or package.
Subdirectories may organize source files, but they do not create module
boundaries.

This keeps the package useful for two purposes:

- `swift build` verifies that canonical examples coexist without symbol
  collisions or top-level playground behavior.
- The `DesignPatternsTests` target verifies examples through ordinary module
  imports rather than executable print statements.

## Why historical examples are not included

The [baseline audit](catalogue-audit.md) found that the existing files compile
only in isolation. They repeat global names such as `Task`, `TaskType`, and
`MyTask`, and several execute sample code at the top level.

Moving those files under `Sources/` today would force a large mechanical rewrite
and would make unreviewed examples appear canonical. They remain in their
historical directories until the corresponding three-day pattern cycle produces
a tested replacement.

## Source rules

When a canonical example is added:

1. Place it under `Sources/DesignPatterns/<Category>/<Pattern>/`.
2. Prefer names from the real app domain over generic names such as `Task`,
   `Manager`, or `Product`.
3. Keep executable demonstrations out of library source files; express behavior
   through tests and documented usage instead.
4. Add a new target only when a real platform, dependency, or deployment
   boundary requires separate compilation.
5. Do not add a shared protocol or base type solely because several examples
   belong to the same catalogue.

## Validation

From the repository root:

```sh
swift build
```

The `.build/` directory is a local Swift Package Manager artifact and is ignored
by Git.

Build and test commands shared with CI are documented in the
[quality gates](quality-gates.md).
