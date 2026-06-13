import Foundation
import Security

enum KeychainHelper {
    private static let service = Bundle.main.bundleIdentifier ?? "AIschedule"

    static func saveAPIKey(_ apiKey: String, account: String) throws {
        let data = Data(apiKey.utf8)
        let query = baseQuery(account: account)
        let attributes = [kSecValueData as String: data]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var newItem = query
            newItem[kSecValueData as String] = data
            try check(SecItemAdd(newItem as CFDictionary, nil))
        } else {
            try check(status)
        }
    }

    static func loadAPIKey(account: String) throws -> String? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return nil
        }

        try check(status)
        guard let data = result as? Data else {
            throw KeychainHelperError.invalidData
        }
        return String(data: data, encoding: .utf8)
    }

    static func deleteAPIKey(account: String) throws {
        let status = SecItemDelete(baseQuery(account: account) as CFDictionary)
        if status != errSecItemNotFound {
            try check(status)
        }
    }

    private static func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    private static func check(_ status: OSStatus) throws {
        guard status == errSecSuccess else {
            throw KeychainHelperError.unexpectedStatus(status)
        }
    }
}

enum KeychainHelperError: LocalizedError {
    case invalidData
    case unexpectedStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .invalidData:
            "钥匙串中的 API Key 数据无效。"
        case .unexpectedStatus(let status):
            "钥匙串操作失败（\(status)）。"
        }
    }
}
