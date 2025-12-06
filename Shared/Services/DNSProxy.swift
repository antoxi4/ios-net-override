//
//  DNSProxy.swift
//  NetOverride
//
//  Created by Anton Yashyn on 06.12.2025.
//

import Foundation
import NetworkExtension

class DNSProxy {
    // MARK: - Properties
    private static let appGroup = "group.xyz.yashyn.NetOverride"
    private static let recordsKey = "enabledOverrideRecords"
    
    // MARK: - Public Methods
    func getDNSProxyState() async -> DNSProxyState {
        await withCheckedContinuation { continuation in
            NEDNSProxyManager.shared().loadFromPreferences { _ in
                let isEnabled = NEDNSProxyManager.shared().isEnabled
                continuation.resume(returning: isEnabled ? .enabled : .disabled)
            }
        }
    }
    
    func storeRecords(_ records: [DNSRecord]) throws {
        guard let defaults = UserDefaults(suiteName: Self.appGroup) else {
            throw DNSProxyError.sharedDefaultsUnavailable
        }
        
        let recordsData = records.map { [
            "id": $0.id,
            "destination": $0.destination,
            "domain": $0.domain
        ]}
        
        let encodedData = try PropertyListEncoder().encode(recordsData)
        defaults.set(encodedData, forKey: Self.recordsKey)
    }
    
    func getStoredRecords() throws -> [DNSRecord] {
        guard let defaults = UserDefaults(suiteName: Self.appGroup) else {
            throw DNSProxyError.sharedDefaultsUnavailable
        }
        
        guard let data = defaults.data(forKey: Self.recordsKey) else {
            return []
        }
        
        let decoded = try PropertyListDecoder().decode([[String: String]].self, from: data)
        return decoded.compactMap { dict in
            guard let id = dict["id"],
                  let destination = dict["destination"],
                  let domain = dict["domain"] else {
                return nil
            }
            return DNSRecord(id: id, destination: destination, domain: domain)
        }
    }
    
    func enableDNSProxy() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            NEDNSProxyManager.shared().loadFromPreferences { _ in
                let manager = NEDNSProxyManager.shared()
                manager.localizedDescription = "DNS Override"
                
                let providerProtocol = NEDNSProxyProviderProtocol()
                providerProtocol.providerBundleIdentifier = "xyz.yashyn.NetOverride.netextension"
                
                manager.providerProtocol = providerProtocol
                manager.isEnabled = true
                
                manager.saveToPreferences { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    func disableDNSProxy() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            NEDNSProxyManager.shared().loadFromPreferences { loadError in
                if let loadError = loadError {
                    continuation.resume(throwing: loadError)
                    return
                }
                
                let manager = NEDNSProxyManager.shared()
                manager.isEnabled = false
                
                manager.saveToPreferences { saveError in
                    if let saveError = saveError {
                        continuation.resume(throwing: saveError)
                    } else {
                        continuation.resume()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Types
extension DNSProxy {
    enum DNSProxyState {
        case enabled
        case disabled
    }
    
    struct DNSRecord {
        let id: String
        let destination: String
        let domain: String
    }
    
    enum DNSProxyError: LocalizedError {
        case sharedDefaultsUnavailable
        
        var errorDescription: String? {
            switch self {
            case .sharedDefaultsUnavailable:
                return "Unable to access shared storage"
            }
        }
    }
}
