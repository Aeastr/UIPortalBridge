<div align="center">
  <h1><b>UIPortalBridge</b></h1>
  <p>
    A lightweight wrapper around Apple's private <code>_UIPortalView</code> for UIKit and SwiftUI.
  </p>
</div>

<p align="center">
  <a href="https://developer.apple.com/ios/"><img src="https://img.shields.io/badge/iOS-17%2B-purple.svg" alt="iOS 17+"></a>
  <a href="https://swift.org/"><img src="https://img.shields.io/badge/Swift-6.0-orange.svg" alt="Swift 6.0"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License: MIT"></a>
</p>

Portal views display a live mirror of another view. The mirrored content updates in real-time.

Looking for SwiftUI transitions? See [Portal](https://github.com/Aeastr/Portal) (experimental, pure SwiftUI) or [Transmission](https://github.com/nathantannar4/Transmission) (mature, UIKit-backed).

> **WARNING: Private API Usage**
>
> This package uses Apple's private `_UIPortalView` API. Apps using private APIs **may be rejected by App Store Review**. Use at your own discretion. UIPortalBridge, Aether, and any maintainers assume no responsibility for App Store rejections, app crashes, or any other issues arising from the use of this package. By importing `UIPortalBridge`, you accept full responsibility for any consequences.

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/Aeastr/UIPortalBridge", from: "1.0.0")
]
```

```swift
import UIPortalBridge
```

## UIKit

```swift
let sourceView = UILabel()
sourceView.text = "Hello"

let portal = UIPortalView()
portal.sourceView = sourceView

// Optional configuration
portal.hidesSourceView = false  // Hide the source while portaling
portal.matchesAlpha = true      // Match source alpha
portal.matchesTransform = true  // Match source transform
portal.matchesPosition = true   // Match source position
```

Check `portal.isAvailable` to verify the private API is available on the current iOS version.

## SwiftUI

### Basic Usage

```swift
struct ContentView: View {
    @State private var container = SourceViewContainer {
        Text("Original Content")
            .padding()
            .background(.blue)
    }

    var body: some View {
        VStack {
            // Source view
            SourceViewRepresentable(
                container: container,
                content: Text("Original Content")
                    .padding()
                    .background(.blue)
            )

            // Portal (live mirror)
            PortalView(source: container)
        }
    }
}
```

### PortalView Options

```swift
PortalView(
    source: container,
    hidesSource: false,
    matchesAlpha: true,
    matchesTransform: true,
    matchesPosition: true
)
```

### Using with Raw UIView

If you have a `UIView` reference:

```swift
PortalViewRepresentable(
    sourceView: myUIView,
    hidesSourceView: false,
    matchesAlpha: true,
    matchesTransform: true,
    matchesPosition: true
)
```

## API

### UIPortalView

| Property | Type | Default | Description |
|:---------|:-----|:--------|:------------|
| `sourceView` | `UIView?` | `nil` | The view to mirror |
| `isAvailable` | `Bool` | - | Whether the private API is available (read-only) |
| `hidesSourceView` | `Bool` | `false` | Hide source while portaling |
| `matchesAlpha` | `Bool` | `true` | Match source alpha |
| `matchesTransform` | `Bool` | `true` | Match source transform |
| `matchesPosition` | `Bool` | `true` | Match source position |

### SourceViewContainer

Holds a SwiftUI view and exposes its underlying `UIView` for portaling.

| Property | Type | Description |
|:---------|:-----|:------------|
| `view` | `UIView` | The underlying UIView |

| Method | Description |
|:-------|:------------|
| `update(content:)` | Update the container's content |

## License

MIT
