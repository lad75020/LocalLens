import SwiftUI

struct GlassPill<Content: View>: View { let content: Content; init(@ViewBuilder content: () -> Content) { self.content = content() }; var body: some View { content.padding(8).background(.thinMaterial, in: Capsule()) } }
