import SwiftUI

public enum LocalLensTheme {
    public static let accent = Color.accentColor
    public static let success = Color.green
    public static let warning = Color.orange
    public static let danger = Color.red
    public static let info = Color.blue

    public enum Typography {
        public static let title = Font.title3.weight(.semibold)
        public static let section = Font.headline
        public static let body = Font.body
        public static let metadata = Font.caption
        public static let monoCaption = Font.caption.monospaced()
    }

    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 24
    }

    public enum Metrics {
        public static let thumbnailSize = CGSize(width: 48, height: 48)
        public static let popoverWidth: CGFloat = 520
        public static let settingsMinWidth: CGFloat = 760
        public static let settingsMinHeight: CGFloat = 560
    }

    public static func statusColor(for state: IndexState) -> Color {
        switch state {
        case .complete: success
        case .partial, .stale: warning
        case .failed, .cancelled, .missing: danger
        case .discovered, .queued, .indexing: info
        }
    }
}
