# Flyweight Measurement Review

Review date: 2026-11-11

Bonus 004 defines exactly what the festival-map example measures and removes
API names that implied a complete memory profile.

## Observed pressure

The direct builder creates 20,000 distinct artwork objects. Each object owns an
array containing 4,096 `UInt8` RGBA elements, while only four category images
exist. The Flyweight builder creates one immutable artwork object per used
category and lets annotations share its identity.

The model can count those elements and identities deterministically. It cannot
infer the resident memory of a real application from them.

## Measurement contract

| Evidence | Included | Excluded |
| --- | --- | --- |
| Annotation count | Number of returned model annotations | Renderer views, layers, and recycled annotations |
| Artwork identity count | Distinct `ObjectIdentifier` values retained by the result | Framework-internal image or texture identities |
| Decode construction count | Calls implied by the deterministic model builder | Platform decoder work, lazy decoding, GPU upload |
| Decoded pixel payload | Logical `UInt8` element count in owned RGBA arrays | Array capacity, object headers, allocator rounding, strings, dictionaries, metadata |
| Process memory | Nothing | RSS, dirty/resident pages, compressed memory, framework caches, renderer copies, GPU memory |

For the representative fixture, the exact model-owned pixel payload changes
from 81,920,000 bytes to 16,384 bytes, a difference of 81,903,616 bytes. This is
also 78.109375 MiB of logical RGBA elements. It is not a claim that process RSS
falls by 78.109375 MiB.

## API correction

`DirectFestivalMapMemoryProfile` and the `.memory` property overstated the
measurement boundary. They are now:

```swift
DirectFestivalMapPayloadProfile
profiledMap.payload
```

The category breakdown is likewise named
`FestivalCategoryPayloadProfile`. The behavior and arithmetic are unchanged;
the compiler-enforced API now matches what the tests can prove.

## Decision

**Use Flyweight** for the documented decoded-buffer boundary. The evidence gate
passes because many live model objects repeat a small, immutable, exactly
countable payload, and one category-scoped catalogue removes that ownership
without global cache lifetime.

This verdict is not transferable automatically to `UIImage`, `NSImage`, an
asset catalogue, MapKit, another map SDK, or a GPU renderer. Prefer platform
asset identifiers or direct values when the real rendering stack already shares
resources.

## Verification and reversal

```sh
swift test -Xswiftc -warnings-as-errors --filter FlyweightPressureTests
swift test -Xswiftc -warnings-as-errors --filter FlyweightTests
```

Keep the deterministic payload assertions in the fast unit suite. Measure a
production app separately with Instruments, VM Tracker, Allocations, or the
renderer's own diagnostics before claiming an RSS, allocation, decode-time, or
GPU-memory benefit.

Reverse the pattern decision when the platform demonstrably deduplicates the
four resources, the live result is small, or intrinsic artwork is mostly unique.
Those facts remove the measured ownership pressure even though this synthetic
fixture continues to show repeated array elements.
