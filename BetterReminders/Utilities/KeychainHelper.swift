import Foundation
import Security

enum KeychainHelper {
    private static let service = "com.betterreminders.apikey"

    static func sanitizeAPIKey(_ key: String) -> String {
        key
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: " ", with: "")
    }

    static func isValidOpenAIKeyFormat(_ key: String) -> Bool {
        let sanitized = sanitizeAPIKey(key)
        return sanitized.hasPrefix("sk-") && sanitized.count >= 20
    }

    static func saveAPIKey(_ key: String) throws {
        let sanitized = sanitizeAPIKey(key)
        guard isValidOpenAIKeyFormat(sanitized) else {
            throw KeychainError.invalidFormat
        }

        let data = Data(sanitized.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "openai",
        ]
        SecItemDelete(query as CFDictionary)
        var addQuery = query
        addQuery[kSecValueData as String] = data
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    static func loadAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "openai",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        let key = String(data: data, encoding: .utf8).map(sanitizeAPIKey)
        return key?.isEmpty == false ? key : nil
    }

    static func deleteAPIKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "openai",
        ]
        SecItemDelete(query as CFDictionary)
    }

    enum KeychainError: LocalizedError {
        case saveFailed(OSStatus)
        case invalidFormat

        var errorDescription: String? {
            switch self {
            case .saveFailed(let status):
                return "Failed to save API key (status: \(status))"
            case .invalidFormat:
                return "Invalid API key format. Use an OpenAI API key from platform.openai.com that starts with sk-."
            }
        }
    }
}
