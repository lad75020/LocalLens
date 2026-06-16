import Foundation

extension ProviderSetting {
    var providerModeForGeneratedContent: ProviderMode {
        switch locality {
        case .localLoopback, .localNetwork: return .localLoopback
        case .remote: return .remoteOptIn
        }
    }
}
