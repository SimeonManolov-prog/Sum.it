import Foundation
import Security

/// HuggingFace connection settings. The token lives in the Keychain, never in source.
@Observable
final class AISettings {
    static let shared = AISettings()
    static let suggestedModels = [
        "XiaomiMiMo/MiMo-V2.6-Pro-RL",
        "meta-llama/Llama-3.1-8B-Instruct",
        "Qwen/Qwen2.5-7B-Instruct",
        "mistralai/Mistral-7B-Instruct-v0.3",
    ]

    var token: String { didSet { Keychain.write(token) } }
    var model: String { didSet { UserDefaults.standard.set(model, forKey: "hf.model") } }

    var hasToken: Bool { !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    private init() {
        token = Keychain.read() ?? ""
        model = UserDefaults.standard.string(forKey: "hf.model") ?? Self.suggestedModels[0]
    }
}

private enum Keychain {
    private static let service = "com.stellargalaxylabs.sumit"
    private static let account = "huggingface-token"

    private static var base: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account]
    }

    static func read() -> String? {
        var q = base
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var out: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess, let d = out as? Data else { return nil }
        return String(data: d, encoding: .utf8)
    }

    static func write(_ value: String) {
        SecItemDelete(base as CFDictionary)
        let v = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !v.isEmpty else { return }
        var q = base
        q[kSecValueData as String] = Data(v.utf8)
        q[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        SecItemAdd(q as CFDictionary, nil)
    }
}
