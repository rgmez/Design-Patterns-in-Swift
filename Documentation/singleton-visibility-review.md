# 🔎 Singleton Visibility Review

<a id="singleton-visibility-review"></a>

Review date: 2026-11-11

Bonus 003 narrows the production Singleton from a public convenience API to two explicit construction boundaries in one source file.

[← Repository overview](../README.md) · [Pattern catalogue](../README.md#pattern-catalogue) · [Reading guide](../README.md#reading-guide)

## Observed pressure

The legacy preview runtime can construct only `LegacyPreviewResumeCallback()` with a zero-argument initializer. It cannot receive the injected `AudioSessionController` used by normal app clients. Two independently constructed controllers can therefore claim the same process audio resource.

Actor isolation already protects the mutable state of one controller. It does not make separately constructed actors share identity. Singleton remains justified only for this construction gap.

## Previous API weakness

`AudioSessionController.shared` was public. The README asked ordinary callers to ignore that convenience and use dependency injection, but the compiler made the hidden-dependency path available to every module importing the package.

That was broader than the documented policy. Code review, rather than the API, had to prevent a feature from reaching for `shared` instead of accepting an injected controller.

## Narrowed boundary

The production identity is now `fileprivate`:

```swift
fileprivate static let production = AudioSessionController(
    systemSession: ProcessSystemAudioSession()
)
```

Only two types in the same file can resolve it:

- `AudioSessionCompositionRoot`, a `package` value that gives app targets one controller to inject into ordinary clients; and
- `LegacyPreviewResumeCallback`, whose public zero-argument initializer is the one verified exception to constructor injection.

External modules cannot name the static identity. Other package files cannot name it either. Tests see the package composition root and callback controller, not the singleton storage itself.

## Concurrency boundary

No actor behavior changed. `AudioSessionController` still reserves ownership before awaiting the external platform actor, rejects competing owners during suspension, and rolls state back after activation or deactivation failure.

The visibility change solves dependency distribution, not serialization:

- actor instance isolation protects one controller's mutable state;
- the file-private static identity ensures the two construction roots converge;
- the package composition root preserves explicit injection for normal clients.

No global actor, `@MainActor`, mutable static state, reset hook, `@unchecked Sendable`, or unsafe nonisolated escape is introduced.

## Verification

`SingletonTests.ControlledProductionIdentity` proves that:

1. two production composition roots receive the same controller identity; and
2. the zero-argument legacy callback receives that same controller.

`SingletonTests.InjectedClients` continues to prove that an explicitly injected controller shares ownership state and that isolated tests never mutate the production instance.

The compiler provides the access-control proof: code outside `AudioSessionController.swift` cannot reference `production` because it is `fileprivate`.

```sh
swift test -Xswiftc -warnings-as-errors --filter SingletonTests
swift test -Xswiftc -warnings-as-errors --filter SingletonProblemTests
swift package dump-symbol-graph --minimum-access-level public
```

The generated public symbol graph contains `AudioSessionController` but no `production` or `shared` storage accessor.

## Decision and reversal

**Use Singleton**, confined behind the composition root and the non-injectable callback. The new API removes public shared lookup without pretending the process identity no longer exists.

Delete the static identity and inject one actor everywhere if the legacy runtime gains a registration closure, context value, factory, or prepared callback. Replace the singleton assumption with scoped composition if the product gains a second legitimate audio-session scope.
