# ✅ Build and Test Quality Gates

<a id="build-and-test-quality-gates"></a>

Canonical examples must compile together, execute their tests, and produce no compiler warnings. The same commands run locally and in GitHub Actions.

[← Repository overview](../README.md) · [Pattern catalogue](../README.md#pattern-catalogue) · [Reading guide](../README.md#reading-guide)

## Local validation

From the repository root:

```sh
swift build -Xswiftc -warnings-as-errors
swift test -Xswiftc -warnings-as-errors
```

The explicit compiler flag makes warnings fail both commands. This prevents an example from being marked complete while relying on deprecated APIs or other diagnostics that would otherwise remain easy to overlook.

Validate the documentation and patch formatting as well:

```sh
ruby scripts/validate_readmes.rb
git diff --check
```

The documentation validator checks the 23 canonical guides, category coverage, local file and image targets, Markdown section links, and supported Mermaid declarations. Section checks recognize explicit anchors, repeated headings, and percent-encoded fragments while ignoring fenced examples. GitHub source-line references are separate from heading navigation. These checks complement the rendered review in [README experience](readme-experience.md#verification); they do not prove that a Mermaid diagram renders or that an external URL is reachable.

## Initial test target

`DesignPatternsTests` uses Swift Testing and imports the single `DesignPatterns` library module.

The initial package-boundary test deliberately has no fake assertion and no production sentinel. Compiling and executing the test proves that Swift Package Manager can discover the suite and load the canonical module. The test can be removed when the first behavioral pattern test provides the same coverage.

New test files should:

- Use Swift Testing rather than XCTest unless an XCTest-only capability is required.
- Organize behavior under one outer suite with focused nested suites.
- Test observable outcomes instead of `print` output or implementation details.
- Avoid shared mutable state, network calls, timing assumptions, and execution order dependencies.
- Keep fixtures local until real repetition justifies a shared helper.

## Continuous integration

[`.github/workflows/ci.yml`](../.github/workflows/ci.yml) runs for pull requests and pushes to `master`. It uses one macOS job with read-only repository permissions and performs four validation operations after checkout:

1. Report the selected Swift version for diagnostics.
2. Validate the README experience and documentation links.
3. Build the package with warnings treated as errors.
4. Run the complete test suite with warnings treated as errors.

There is no platform matrix, dependency cache, coverage service, or wrapper script yet. The package has no requirement that would justify their maintenance cost.

The workflow uses the current major version of the official [`actions/checkout`](https://github.com/actions/checkout) action and an explicit [`macos-26`](https://github.com/actions/runner-images) runner label. These versions should be reviewed during scheduled foundation or release checks rather than changed speculatively.
