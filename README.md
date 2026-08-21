# StatusOverlayKit

Lightweight SwiftUI overlays for success, loading, and transient status messages — with a consistent spring animation and glass-card styling out of the box.

## Requirements

- iOS 17+
- Swift 5.9+

## Installation

### Swift Package Manager

Add StatusOverlayKit as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/<your-org>/StatusOverlayKit.git", from: "1.0.0")
]
```

Or in Xcode: **File → Add Package Dependencies…** and enter the repository URL.

## Usage

### SuccessOverlay

A dimmed full-screen overlay with a glass card showing an SF Symbol, title, and subtitle.

```swift
import StatusOverlayKit

@State private var showSuccess = false

var body: some View {
    ZStack {
        // your content

        if showSuccess {
            SuccessOverlay(title: "Saved", subtitle: "Your changes were saved.")
        }
    }
}
```

### LoadingOverlay

A dimmed full-screen overlay with a glass card and a configurable spinner.

```swift
LoadingOverlay(message: "Saving...")

// or with a custom spinner
LoadingOverlay(message: "Saving...") {
    MyBrandedSpinner()
}
```

### presentTransientOverlay

Flip a boolean on, hold for a duration, then flip it off — the standard show/auto-dismiss pattern.

```swift
@State private var showSuccess = false

presentTransientOverlay($showSuccess)
```

Or drive a `StatusMessage` binding directly:

```swift
@State private var status: StatusMessage? = nil

presentTransientOverlay($status, StatusMessage(title: "Saved", subtitle: "Your changes were saved."))
```

### Surviving navigation with TransientStatusSignal

Post a `StatusMessage` before navigating, then consume it on the destination screen with `.consumesTransientStatus()`:

```swift
// Before navigating away
TransientStatusSignal.shared.pending = StatusMessage(title: "Deleted", subtitle: "Item removed.", icon: "trash.fill", tint: .red)

// On the destination screen
struct DestinationView: View {
    var body: some View {
        ContentView()
            .consumesTransientStatus()
    }
}
```

## License

StatusOverlayKit is available under the MIT license. See [LICENSE](LICENSE) for details.
