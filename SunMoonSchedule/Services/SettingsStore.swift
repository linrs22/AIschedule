import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    private static let deepSeekAPIKeyAccount = "deepSeekAPIKey"
    private static let legacyDeepSeekAPIKeyKey = "deepSeekAPIKey"

    @Published private(set) var deepSeekAPIKey: String

    private init() {
        // Never migrate a previously stored plaintext key into a distributed build.
        UserDefaults.standard.removeObject(forKey: Self.legacyDeepSeekAPIKeyKey)
        deepSeekAPIKey = (try? KeychainHelper.loadAPIKey(account: Self.deepSeekAPIKeyAccount)) ?? ""
    }

    var hasDeepSeekAPIKey: Bool {
        !deepSeekAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func saveDeepSeekAPIKey(_ apiKey: String) throws {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedKey.isEmpty {
            try KeychainHelper.deleteAPIKey(account: Self.deepSeekAPIKeyAccount)
        } else {
            try KeychainHelper.saveAPIKey(trimmedKey, account: Self.deepSeekAPIKeyAccount)
        }
        deepSeekAPIKey = trimmedKey
    }
}
