import SwiftUI

public enum AccessibilitySupport {
    public static let searchField = "searchField"
    public static let indexingStatusSummary = "indexingStatusSummary"
    public static let settingsButton = "settingsButton"
    public static let settingsStatusMessage = "settingsStatusMessage"
    public static let failureDashboard = "failureDashboard"
    public static let privacyStorageSummary = "settingsPrivacyStorageSummary"

    public static func label(_ title: String, hint: String? = nil) -> String {
        hint.map { "\(title). \($0)" } ?? title
    }
}

public struct ReducedMotionAwareModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    public func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : .snappy(duration: 0.18), value: reduceMotion)
    }
}

public struct ReducedTransparencyFallback: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    public func body(content: Content) -> some View {
        content.background(reduceTransparency ? Color(nsColor: .windowBackgroundColor) : Color.clear)
    }
}

public extension View {
    func localLensAccessibility(id: String, label: String, hint: String? = nil) -> some View {
        accessibilityIdentifier(id)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
    }

    func reducedMotionAware() -> some View {
        modifier(ReducedMotionAwareModifier())
    }

    func reducedTransparencyFallback() -> some View {
        modifier(ReducedTransparencyFallback())
    }

    func keyboardFocusRing(_ active: Bool) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(active ? Color.accentColor.opacity(0.65) : Color.clear, lineWidth: 2)
        )
    }
}
