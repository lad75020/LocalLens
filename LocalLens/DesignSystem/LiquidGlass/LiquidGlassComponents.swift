import SwiftUI

public enum LiquidGlassToken {
    public static let cornerRadius: CGFloat = 18
    public static let compactCornerRadius: CGFloat = 12
    public static let hairlineOpacity = 0.16
    public static let surfaceOpacity = 0.12
    public static let actionSpacing: CGFloat = 8
}

public struct GlassPill<Content: View>: View {
    private let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View { content.padding(.horizontal, 10).padding(.vertical, 6).localLensGlassCapsule() }
}

public struct GlassActionButton<Label: View>: View {
    let action: () -> Void
    let label: Label
    public init(action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.action = action
        self.label = label()
    }
    public var body: some View {
        Button(action: action) { label }
            .buttonStyle(.plain)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .localLensGlassCapsule()
    }
}

public struct GlassPanel<Content: View>: View {
    let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View {
        content
            .padding(14)
            .localLensGlassPanel(cornerRadius: LiquidGlassToken.cornerRadius)
    }
}

public extension View {
    @ViewBuilder
    func localLensGlassCapsule() -> some View {
        if #available(macOS 26.0, *) {
            self.glassEffect(.regular, in: .capsule)
        } else {
            self.background(.thinMaterial, in: Capsule())
                .overlay(Capsule().stroke(.white.opacity(LiquidGlassToken.hairlineOpacity), lineWidth: 0.5))
        }
    }

    @ViewBuilder
    func localLensGlassPanel(cornerRadius: CGFloat = LiquidGlassToken.cornerRadius) -> some View {
        if #available(macOS 26.0, *) {
            self.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            self.background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).stroke(.white.opacity(LiquidGlassToken.hairlineOpacity), lineWidth: 0.5))
        }
    }

    func contrastSafeGlassSurface(cornerRadius: CGFloat = LiquidGlassToken.compactCornerRadius) -> some View {
        background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).stroke(.primary.opacity(0.08), lineWidth: 0.5))
    }
}
