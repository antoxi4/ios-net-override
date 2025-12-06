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
