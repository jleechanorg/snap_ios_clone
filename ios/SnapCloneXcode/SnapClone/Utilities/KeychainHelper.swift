import Foundation
import Security

class KeychainHelper {
    static let shared = KeychainHelper()
    
    private init() {}
    
    // MARK: - Generic Keychain Operations
    
    func save<T: Codable>(_ object: T, service: String, account: String) {
        do {
            let data = try JSONEncoder().encode(object)
            save(data, service: service, account: account)
        } catch {
            print("Failed to encode object for keychain: \(error)")
        }
    }
    
    func read<T: Codable>(_ type: T.Type, service: String, account: String) -> T? {
        guard let data = read(service: service, account: account) else { return nil }
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("Failed to decode object from keychain: \(error)")
            return nil
        }
    }
    
    // MARK: - Data Operations
    
    private func save(_ data: Data, service: String, account: String) {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ] as [String: Any]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("Failed to save to keychain: \(status)")
        }
    }
    
    private func read(service: String, account: String) -> Data? {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ] as [String: Any]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            return dataTypeRef as? Data
        } else {
            return nil
        }
    }
    
    func delete(service: String, account: String) {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ] as [String: Any]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Convenience Methods for App
    
    private let authTokenService = "com.snapclone.authtoken"
    private let userCredentialsService = "com.snapclone.credentials"
    
    func saveAuthToken(_ token: String, for userId: String) {
        save(token.data(using: .utf8) ?? Data(), service: authTokenService, account: userId)
    }
    
    func getAuthToken(for userId: String) -> String? {
        guard let data = read(service: authTokenService, account: userId),
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        return token
    }
    
    func deleteAuthToken(for userId: String) {
        delete(service: authTokenService, account: userId)
    }
    
    func saveUserCredentials(_ credentials: UserCredentials) {
        save(credentials, service: userCredentialsService, account: credentials.userId)
    }
    
    func getUserCredentials(for userId: String) -> UserCredentials? {
        return read(UserCredentials.self, service: userCredentialsService, account: userId)
    }
    
    func deleteUserCredentials(for userId: String) {
        delete(service: userCredentialsService, account: userId)
    }
    
    func clearAllCredentials() {
        // This is a more aggressive clear - use with caution
        let secItemClasses = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity
        ]
        
        for itemClass in secItemClasses {
            let spec: NSDictionary = [kSecClass: itemClass]
            SecItemDelete(spec)
        }
    }
}

// MARK: - Supporting Types

struct UserCredentials: Codable {
    let userId: String
    let email: String
    let username: String
    let displayName: String
    let profileImageURL: String?
    let lastLoginDate: Date
    
    init(from user: User) {
        self.userId = user.id ?? ""
        self.email = user.email
        self.username = user.username
        self.displayName = user.displayName
        self.profileImageURL = user.profileImageURL
        self.lastLoginDate = Date()
    }
}