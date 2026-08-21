import SwiftUI

// MARK: - Animation

/// The spring all transient overlays use to show and dismiss. Reuse this so
/// every popup enters and exits with the same feel.
public let statusOverlaySpring: Animation = .spring(response: 0.35, dampingFraction: 0.8)

// MARK: - Present Helpers

/// Flips `flag` on, holds for `duration`, then flips it off — the standard
/// show/auto-dismiss pattern for boolean-gated overlays.
public func presentTransientOverlay(_ flag: Binding<Bool>, duration: Double = 1.5) {
    withAnimation(statusOverlaySpring) {
        flag.wrappedValue = true
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
        withAnimation(statusOverlaySpring) {
            flag.wrappedValue = false
        }
    }
}

/// Shows `message`, holds for `duration`, then clears it — unless a newer
/// message replaced it in the meantime.
public func presentTransientOverlay(
    _ current: Binding<StatusMessage?>,
    _ message: StatusMessage,
    duration: Double = 1.5
) {
    withAnimation(statusOverlaySpring) {
        current.wrappedValue = message
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
        withAnimation(statusOverlaySpring) {
            if current.wrappedValue == message {
                current.wrappedValue = nil
            }
        }
    }
}

// MARK: - StatusMessage

/// Carries an overlay's content — title, subtitle, icon, tint — so it can
/// survive navigation boundaries via `TransientStatusSignal`.
public struct StatusMessage: Equatable {
    public let title: String
    public let subtitle: String
    public var icon: String
    public var tint: Color

    public init(
        title: String,
        subtitle: String,
        icon: String = "checkmark.circle.fill",
        tint: Color = .green
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.tint = tint
    }
}

// MARK: - TransientStatusSignal

/// Singleton bus for a `StatusMessage` that must survive a navigation hop.
/// Post before navigating; the destination consumes it via `.consumesTransientStatus()`.
public final class TransientStatusSignal: ObservableObject {
    public static let shared = TransientStatusSignal()
    private init() {}

    @Published public var pending: StatusMessage? = nil
}

// MARK: - SuccessOverlay

/// Dimmed full-screen overlay with a glass card showing an SF Symbol, title,
/// and subtitle. Defaults to a green checkmark; pass a different `icon`/`tint`
/// for neutral actions such as logout or deletion.
public struct SuccessOverlay: View {
    public let title: String
    public let subtitle: String
    public var icon: String
    public var tint: Color

    public init(
        title: String,
        subtitle: String,
        icon: String = "checkmark.circle.fill",
        tint: Color = .green
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.tint = tint
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: icon)
                    .font(.system(size: 56, weight: .medium))
                    .foregroundStyle(tint)

                VStack(spacing: 6) {
                    Text(title)
                        .font(.system(.title3, weight: .semibold))

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
            .background {
                RoundedRectangle(cornerRadius: 38, style: .continuous)
                    .soGlassCard()
            }
            .padding(.horizontal, 30)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
    }
}

// MARK: - LoadingOverlay

/// Dimmed full-screen overlay with a glass card showing a configurable spinner
/// and a message label.
///
/// Supply any spinner via `init(message:spinner:)`, or use the convenience
/// `init(message:)` which defaults to a plain `ProgressView`.
///
/// Example — custom spinner:
/// ```swift
/// LoadingOverlay(message: "Saving...") { MyBrandedSpinner() }
/// ```
public struct LoadingOverlay<Spinner: View>: View {
    public let message: String
    let spinner: Spinner

    public init(message: String, @ViewBuilder spinner: () -> Spinner) {
        self.message = message
        self.spinner = spinner()
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                spinner

                Text(message)
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(28)
            .background {
                RoundedRectangle(cornerRadius: 38, style: .continuous)
                    .soGlassCard()
            }
            .padding(.horizontal, 30)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
    }
}

extension LoadingOverlay where Spinner == ProgressView<EmptyView, EmptyView> {
    /// Convenience — shows a standard `ProgressView` spinner.
    public init(message: String) {
        self.init(message: message) { ProgressView() }
    }
}

// MARK: - consumesTransientStatus

private struct ConsumesTransientStatus: ViewModifier {
    @State private var statusMessage: StatusMessage? = nil

    func body(content: Content) -> some View {
        content
            .overlay {
                if let statusMessage {
                    SuccessOverlay(
                        title: statusMessage.title,
                        subtitle: statusMessage.subtitle,
                        icon: statusMessage.icon,
                        tint: statusMessage.tint
                    )
                }
            }
            .animation(statusOverlaySpring, value: statusMessage)
            .onAppear {
                guard let pending = TransientStatusSignal.shared.pending else { return }
                TransientStatusSignal.shared.pending = nil

                withAnimation(statusOverlaySpring) {
                    statusMessage = pending
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(statusOverlaySpring) {
                        statusMessage = nil
                    }
                }
            }
    }
}

public extension View {
    /// Attach to any screen that is the landing point of a `TransientStatusSignal`.
    /// On appear, consumes the pending message and shows it as a transient `SuccessOverlay`.
    func consumesTransientStatus() -> some View {
        modifier(ConsumesTransientStatus())
    }
}

// MARK: - Internal: glass card background

private extension Shape {
    @ViewBuilder
    func soGlassCard() -> some View {
        if #available(iOS 26.0, *) {
            self
                .fill(.regularMaterial)
                .glassEffect(.clear, in: self)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        } else {
            self
                .fill(.ultraThinMaterial)
                .clipShape(self)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        }
    }
}
