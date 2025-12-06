//
//  DNSProxy.swift
//  NetOverride
//
//  Created by Anton Yashyn on 06.12.2025.
//

import Foundation
import NetworkExtension

class DNSProxy {
    func getDNSProxyState() async throws -> DNSProxyState {
        return await withUnsafeContinuation({ continuation in
            NEDNSProxyManager.shared().loadFromPreferences { error in
                DispatchQueue.main.async {
                    let manager = NEDNSProxyManager.shared()
                    if manager.isEnabled {
                        continuation.resume(returning: .enabled)
                    } else {
                        continuation.resume(returning: .disabled)
                    }
                }
            }
        })
    }
    
    func storeRecords(records: [DNSRecord]) throws {
        guard let sharedDefaults = UserDefaults(suiteName: DNSProxy.appGroup) else {
            print("Failed to access shared UserDefaults")
            return
        }
        
        let recordsData = records.map { record in
            [
                "id": record.id,
                "destination": record.destination,
                "domain": record.domain
            ]
        }
        let encoder = PropertyListEncoder()
        let encodedData = try encoder.encode(recordsData)
        
        
        sharedDefaults.set(encodedData, forKey: "enabledOverrideRecords")
    }
    
    func getStoredRecords() throws -> [DNSRecord]  {
        guard let sharedDefaults = UserDefaults(suiteName: DNSProxy.appGroup) else {
            print("Failed to access shared UserDefaults")
            return []
        }
        
        guard let recordsData = sharedDefaults.data(forKey: "enabledOverrideRecords") else {
            return []
        }
        
        let decoder = PropertyListDecoder()
        let decodedData = try decoder.decode([[String:String]].self, from: recordsData)
        
        return decodedData.compactMap { dict in
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
            NEDNSProxyManager.shared().loadFromPreferences { error in
                // Ignore load errors - configuration might not exist yet
                
                if let error = error {
                    print("Error loading preferences: \(error)")
                }
                let manager = NEDNSProxyManager.shared()
                manager.localizedDescription = "DNS Override"
                
                // Configure the DNS proxy provider
                let providerProtocol = NEDNSProxyProviderProtocol()
                providerProtocol.providerBundleIdentifier = "xyz.yashyn.NetOverride.netextension"
                providerProtocol.providerConfiguration = [:] // Empty configuration
                
                manager.providerProtocol = providerProtocol
                manager.isEnabled = true
                
                // Important: Set this to true to allow the configuration on demand
//                if #available(iOS 14.0, *) {
//                    manager.isOnDemandEnabled = false
//                }
                
                manager.saveToPreferences { saveError in
                    if let saveError = saveError {
                        print("❌ Error saving DNS proxy: \(saveError)")
                        continuation.resume(throwing: saveError)
                    } else {
                        print("✅ DNS Proxy enabled successfully")
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    func disableDNSProxy() async throws {
        let manager = NEDNSProxyManager.shared()
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            manager.loadFromPreferences { error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                manager.isEnabled = false
                
                manager.saveToPreferences { saveError in
                    if let saveError = saveError {
                        continuation.resume(throwing: saveError)
                    } else {
                        print("✅ DNS Proxy disabled successfully")
                        continuation.resume()
                    }
                }
            }
        }
    }
}

extension DNSProxy {
    static let appGroup = "group.xyz.yashyn.NetOverride"
    enum DNSProxyState {
        case enabled
        case disabled
    }
    
    struct DNSRecord {
        let id: String
        let destination: String
        let domain: String
    }
}
