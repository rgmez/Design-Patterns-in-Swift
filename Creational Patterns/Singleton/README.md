# 🎙️ Singleton

![A microphone rail and a playback rail meet one red mechanical selector that grants access to a single audio-session chamber](../../Documentation/Assets/Patterns/creational/singleton-header.png)

> **Caption:** Two audio clients may request the chamber, but one immutable
> process controller decides who owns it.

**Category:** Creational

## 🎯 The app problem

A journaling app records voice notes and plays previews. Both features configure
the same operating-system audio session, so they cannot act as independent
owners: preview activation during recording could interrupt capture or leave the
process in the wrong configuration.

Most app code is created by a composition root and can receive one injected
`AudioSessionController`. One legacy preview-resume callback is different. Its
runtime constructs the callback from a type name and a zero-argument
initializer; it accepts no closure, context, factory, or prepared handler.

### Requirements

- Keep one accountable owner and purpose for the process-wide session.
- Reject a competing owner, including while activation is suspended.
- Let only the current owner release the session.
- Roll state back coherently when platform activation or deactivation fails.
- Give the runtime-created callback the same controller used by injected app
  clients.
- Keep tests parallel-safe without replacing or resetting global state.

Audio capture, permissions, route policy, interruptions, and UI state are
outside this example. They do not change who owns the single session.

## 🪶 Start with direct Swift

The [problem baseline](../../Documentation/singleton-problem.md) used one actor
created at the app composition root and injected into recording and preview
clients. The actor reserved ownership before awaiting the platform adapter, so
reentrancy could not admit a second client. That direct solution was preferable
while the app controlled every construction root.

An actor was already necessary for mutable coordination; Singleton was not.
Actor isolation serializes access to one instance, whereas dependency injection
makes that instance explicit. Neither feature makes two separately constructed
actors share state.

## ⚡ The turning point

The [pressure evidence](../../Documentation/singleton-pressure.md) introduced
the legacy callback runtime. When its callback built a second controller over
the same platform resource, both actors correctly observed their own `inactive`
state and both accepted ownership. The platform received recording and preview
activations instead of one activation plus an `occupied` error.

This is identity pressure, not concurrency pressure. The app cannot inject into
that one callback, and the runtime offers no registration seam that could
capture the existing controller. “Remember to construct only one” is not an
enforced invariant across those two roots.

## 🧭 Pattern intent

`AudioSessionController.shared` is the one immutable production identity for
the process resource. Its initializer is private. The app composition root
injects that actor into ordinary clients; only `LegacyPreviewResumeCallback()`
looks it up because the runtime prevents constructor injection.

The package-only `isolated(systemSession:)` factory creates fresh controllers
for tests and executable evidence. It cannot replace `shared`, mutate static
storage, or leak state between tests. Singleton therefore contains one proven
construction gap instead of becoming a general dependency strategy.

## 🧩 Participants and responsibilities

| App role | Swift type | Responsibility |
| --- | --- | --- |
| Process ownership boundary | [`AudioSessionController`](../../Sources/DesignPatterns/Singleton/AudioSessionController.swift) | Owns the immutable `shared` identity and serializes activation, release, and rollback state. |
| Legacy construction root | [`LegacyPreviewResumeCallback`](../../Sources/DesignPatterns/Singleton/AudioSessionController.swift) | Uses the shared controller only when a zero-argument runtime initializer prevents injection. |
| Ownership request | [`AudioSessionRequest`](../../Sources/DesignPatterns/Singleton/AudioSessionController.swift) | Carries the nonempty feature identifier and requested audio purpose. |
| Platform seam | [`SystemAudioSessionApplying`](../../Sources/DesignPatterns/Singleton/AudioSessionController.swift) | Isolates the external process resource and gives tests a deterministic actor substitute. |

There is no service locator, global dependency dictionary, mutable singleton,
reset hook, controller protocol, or custom global actor. The platform protocol
exists because it is both an external boundary and an immediate test seam.

## ⚙️ How the Swift implementation works

1. Static initialization creates one `AudioSessionController.shared` with the
   process adapter. The private initializer prevents another public production
   identity.
2. The app root passes that actor to ordinary recording and preview clients.
   The legacy runtime instead calls `LegacyPreviewResumeCallback()`; that exact
   initializer captures `.shared`.
3. `acquire(_:)` changes the actor state from inactive to activating before it
   awaits the platform. Any competing request observes the reserved owner and
   receives `AudioSessionControllerError.occupied`.
4. Successful activation records the active owner. Failed activation returns to
   inactive. Release requires the matching owner, and a failed deactivation
   restores the active state because the system resource may still be live.
5. Tests call `isolated(systemSession:)` with a fresh spy. They never activate,
   replace, or reset the process singleton.

The production identity and the test identity use the same actor behavior:

```swift
public static let shared = AudioSessionController(
    systemSession: ProcessSystemAudioSession()
)

package static func isolated(
    systemSession: any SystemAudioSessionApplying
) -> AudioSessionController {
    AudioSessionController(systemSession: systemSession)
}
```

`ProcessSystemAudioSession` is the executable package's minimal stand-in for the
operating-system adapter. A real app would keep its AVFoundation integration
behind the same `SystemAudioSessionApplying` boundary.

## 🗺️ Diagram

```mermaid
flowchart LR
    Static["Static initialization"] --> Shared["AudioSessionController.shared"]
    AppRoot["App composition root"] -->|injects same actor| Recorder["Voice-note recorder"]
    AppRoot -->|injects same actor| Preview["Preview player"]
    Shared --> AppRoot
    Runtime["Legacy callback runtime"] -->|zero-argument init| Callback["LegacyPreviewResumeCallback"]
    Callback -->|only shared lookup| Shared
    Shared -->|one owner at a time| Session["Process audio session"]
    Tests["Parallel tests"] -->|isolated(systemSession:)| Fresh["Fresh controller + spy"]
```

Observe the creation paths rather than the activation sequence. Static
initialization creates one production actor. The app root distributes it
explicitly, while the runtime-created callback takes the single exceptional
lookup path. Tests branch to fresh instances and never touch production state.

**Accessible description:** Static initialization creates one shared audio
session controller. The app composition root injects that same actor into the
recorder and preview player. A legacy runtime constructs a callback with no
arguments, so that callback alone looks up the shared actor. The actor controls
the one process audio session, while parallel tests create separate controllers
and spies through the package-only isolated factory.

## ▶️ Run the example

From the repository root:

```sh
swift build -Xswiftc -warnings-as-errors
swift test -Xswiftc -warnings-as-errors --filter Singleton
```

The package requires Swift 6.0 and macOS 14 or later. It uses no credentials,
network, audio hardware, or UI framework; deterministic actor spies prove the
ownership behavior.

## 🧪 Tests

[`SingletonProblemTests.swift`](../../Tests/DesignPatternsTests/SingletonProblemTests.swift)
keeps the direct ownership, rollback, suspension, and two-root pressure
evidence. [`SingletonTests.swift`](../../Tests/DesignPatternsTests/SingletonTests.swift)
proves that:

- repeated production access returns the same actor identity;
- the zero-argument legacy callback captures that production identity;
- an injected callback observes the same active owner and cannot bypass it;
- isolated test controllers do not share state or mutate the process singleton;
- the original controller still rejects competing owners and preserves coherent
  state across platform failures.

Swift Testing runs these suites in parallel. No suite is serialized because no
test mutates shared production state.

## ⚖️ Trade-offs

### What improves

- Two independent construction roots converge on one ownership state machine.
- The legacy callback cannot silently create a second authority over the
  process resource.
- `static let` makes the production identity immutable and initialization
  thread-safe.
- Ordinary dependencies remain visible in initializers and tests remain
  parallel-safe.
- Actor isolation and Singleton identity solve separate, explicit problems.

### What it costs

- The shared controller lives for the process lifetime and cannot be reclaimed
  with a feature.
- The zero-argument callback has one hidden dependency that its signature cannot
  reveal.
- Production callers could still misuse the public `shared` entry point by
  reaching for convenience instead of injection; code review must preserve the
  narrow policy.
- External integration tests cannot replace the shared platform adapter. They
  should exercise injected clients or the package's isolated tests instead.
- A second legitimate audio-session scope would invalidate the singleton
  assumption and require a different composition model.

## 🔀 Alternatives considered

| Alternative | Prefer it when | Why it does not meet this example now |
| --- | --- | --- |
| One injected actor | Every caller is built by the app composition root. | The legacy runtime constructs one callback itself and accepts no dependency value. |
| Registered closure or handler | The platform accepts a closure, context pointer, factory, or prepared object. | This runtime accepts only a type and zero-argument initializer; if that changes, remove the shared lookup. |
| SwiftUI environment | The dependency flows through a view hierarchy. | The callback is outside the view tree, and UI infrastructure should not own the audio session. |
| Custom global actor | Multiple declarations need one executor. | A global actor controls isolation, not the identity or lifecycle of an audio-session controller. |
| Service locator | Many dynamically selected dependencies truly require runtime discovery. | A locator would globalize unrelated services and hide ordinary constructor dependencies to solve one gap. |
| Static functions | The operation is stateless. | Ownership, transition rollback, and the current owner are mutable process state. |

Singleton is also not a replacement for dependency injection. Here injection is
the default distribution mechanism; Singleton supplies one identity only where
the external runtime makes injection impossible.

## 🚫 When not to use it

- Do not add `shared` when the composition root can inject the dependency.
- Do not use Singleton merely to avoid one initializer argument.
- Prefer a value, function, or static namespace for immutable or stateless work.
- Use an actor without Singleton when concurrent access needs serialization but
  multiple independent instances are valid.
- Use a custom global actor only when declarations need a shared executor; it
  does not enforce resource identity.
- Avoid Singleton for user-, account-, document-, window-, scene-, or request-
  scoped state.
- Remove this shared path if the legacy runtime gains a registration seam.
- Never add a mutable `static var`, test reset, or service locator to make a
  singleton easier to test.

## 🗂️ Source map

- [`AudioSessionController.swift`](../../Sources/DesignPatterns/Singleton/AudioSessionController.swift) — ownership actor, process identity, isolated test factory, platform seam, and legacy callback.
- [`SingletonProblemTests.swift`](../../Tests/DesignPatternsTests/SingletonProblemTests.swift) — direct ownership behavior and two-root pressure evidence.
- [`SingletonTests.swift`](../../Tests/DesignPatternsTests/SingletonTests.swift) — controlled identity, callback boundary, and test-isolation checks.
- [`singleton-problem.md`](../../Documentation/singleton-problem.md) — direct injected baseline and requirements.
- [`singleton-pressure.md`](../../Documentation/singleton-pressure.md) — measured identity failure and rejected alternatives.
- [`singleton-header.png`](../../Documentation/Assets/Patterns/creational/singleton-header.png) — editorial header.
