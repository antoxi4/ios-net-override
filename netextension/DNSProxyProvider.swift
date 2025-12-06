//
//  DNSProxyProvider.swift
//  netextension
//
//  Created by Anton Yashyn on 06.12.2025.
//

import NetworkExtension
import Foundation

final class DNSProxyProvider: NEDNSProxyProvider {
    // MARK: - Properties
    private var domainMappings: [String: String] = [:]
    private let fallbackDNS = "8.8.8.8"
    private let dnsProxy = DNSProxy()
    
    // MARK: - Lifecycle
    override func startProxy(options: [String : Any]? = nil, completionHandler: @escaping (Error?) -> Void) {
        loadDomainMappings()
        Logger.info("🚀 DNS Proxy started with \(domainMappings.count) domain(s)")
        completionHandler(nil)
    }
    
    override func stopProxy(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        Logger.info("🛑 DNS Proxy stopped")
        completionHandler()
    }
    
    override func sleep(completionHandler: @escaping () -> Void) {
        Logger.info("💤 DNS Proxy sleeping")
        completionHandler()
    }
    
    override func wake() {
        Logger.info("⏰ DNS Proxy waking")
        loadDomainMappings()
    }
    
    // MARK: - Configuration
    private func loadDomainMappings() {
        do {
            let records = try dnsProxy.getStoredRecords()
            domainMappings = records.reduce(into: [:]) { result, record in
                result[record.domain.lowercased()] = record.destination
            }
            Logger.info("✅ Loaded \(domainMappings.count) domain mapping(s)")
        } catch {
            Logger.error("❌ Failed to load mappings: \(error.localizedDescription)")
        }
    }
    
    // MARK: - UDP Flow Handling
    override func handleNewUDPFlow(_ flow: NEAppProxyUDPFlow, initialRemoteEndpoint remoteEndpoint: NWEndpoint) -> Bool {
        loadDomainMappings()
        
        flow.open(withLocalEndpoint: nil) { [weak self] error in
            if let error = error {
                Logger.error("❌ Flow open error: \(error.localizedDescription)")
                return
            }
            self?.startReadingDatagrams(from: flow, systemDNS: remoteEndpoint)
        }
        
        return true
    }
    
    private func startReadingDatagrams(from flow: NEAppProxyUDPFlow, systemDNS: NWEndpoint) {
        flow.readDatagrams { [weak self] datagrams, endpoints, error in
            guard let self = self else { return }
            
            if let error = error {
                Logger.error("❌ Read error: \(error.localizedDescription)")
                return
            }
            
            if let datagrams = datagrams, !datagrams.isEmpty {
                for (index, queryData) in datagrams.enumerated() {
                    let endpoint = endpoints?[safe: index].map { [$0] }
                    self.processDNSQuery(queryData, flow: flow, endpoints: endpoint, systemDNS: systemDNS)
                }
            }
            
            self.startReadingDatagrams(from: flow, systemDNS: systemDNS)
        }
    }
    
    // MARK: - DNS Query Processing
    private func processDNSQuery(_ queryData: Data, flow: NEAppProxyUDPFlow, endpoints: [NWEndpoint]?, systemDNS: NWEndpoint) {
        guard let domain = DNSParser.extractDomain(from: queryData) else {
            forwardToSystemDNS(queryData, flow: flow, endpoints: endpoints, systemDNS: systemDNS)
            return
        }
        
        let normalizedDomain = domain.lowercased()
        
        // Check for exact match
        if let ip = domainMappings[normalizedDomain] {
            Logger.info("✅ Override: \(domain) → \(ip)")
            sendCustomResponse(for: domain, ip: ip, queryData: queryData, flow: flow, endpoints: endpoints)
            return
        }
        
        // Check for subdomain match
        if isSubdomainOfConfigured(normalizedDomain) {
            Logger.info("🚫 Blocked subdomain: \(domain)")
            sendNXDomainResponse(queryData: queryData, flow: flow, endpoints: endpoints)
            return
        }
        
        forwardToSystemDNS(queryData, flow: flow, endpoints: endpoints, systemDNS: systemDNS)
    }
    
    private func isSubdomainOfConfigured(_ domain: String) -> Bool {
        domainMappings.keys.contains { domain.hasSuffix("." + $0) }
    }
    
    // MARK: - DNS Response Handling
    private func sendCustomResponse(for domain: String, ip: String, queryData: Data, flow: NEAppProxyUDPFlow, endpoints: [NWEndpoint]?) {
        guard let response = DNSResponseBuilder.createARecord(for: domain, ip: ip, queryData: queryData) else {
            return
        }
        sendResponse(response, flow: flow, endpoints: endpoints)
    }
    
    private func sendNXDomainResponse(queryData: Data, flow: NEAppProxyUDPFlow, endpoints: [NWEndpoint]?) {
        guard let response = DNSResponseBuilder.createNXDomain(queryData: queryData) else {
            return
        }
        sendResponse(response, flow: flow, endpoints: endpoints)
    }
    
    private func sendResponse(_ data: Data, flow: NEAppProxyUDPFlow, endpoints: [NWEndpoint]?) {
        flow.writeDatagrams([data], sentBy: endpoints ?? []) { error in
            if let error = error {
                Logger.error("❌ Write error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - DNS Forwarding
    private func forwardToSystemDNS(_ queryData: Data, flow: NEAppProxyUDPFlow, endpoints: [NWEndpoint]?, systemDNS: NWEndpoint) {
        let dnsServer = extractHost(from: systemDNS)
        
        DispatchQueue.global().async { [weak self] in
            guard let response = self?.queryUpstreamDNS(dnsServer: dnsServer, queryData: queryData) else {
                return
            }
            self?.sendResponse(response, flow: flow, endpoints: endpoints)
        }
    }
    
    private func queryUpstreamDNS(dnsServer: String, queryData: Data) -> Data? {
        var hints = addrinfo()
        hints.ai_family = AF_INET
        hints.ai_socktype = SOCK_DGRAM
        hints.ai_protocol = IPPROTO_UDP
        
        var servinfo: UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo(dnsServer, "53", &hints, &servinfo) == 0, let info = servinfo else {
            Logger.error("❌ DNS resolution failed")
            return nil
        }
        defer { freeaddrinfo(servinfo) }
        
        let sockfd = socket(info.pointee.ai_family, info.pointee.ai_socktype, info.pointee.ai_protocol)
        guard sockfd >= 0 else {
            Logger.error("❌ Socket creation failed")
            return nil
        }
        defer { close(sockfd) }
        
        // Set 5 second timeout
        var timeout = timeval(tv_sec: 5, tv_usec: 0)
        setsockopt(sockfd, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
        
        // Send query
        let sent = queryData.withUnsafeBytes { bytes in
            sendto(sockfd, bytes.baseAddress, queryData.count, 0, info.pointee.ai_addr, info.pointee.ai_addrlen)
        }
        guard sent == queryData.count else {
            Logger.error("❌ Send failed")
            return nil
        }
        
        // Receive response
        var buffer = [UInt8](repeating: 0, count: 512)
        let received = recvfrom(sockfd, &buffer, buffer.count, 0, nil, nil)
        guard received > 0 else {
            Logger.error("❌ Receive failed")
            return nil
        }
        
        return Data(buffer.prefix(received))
    }
    
    private func extractHost(from endpoint: NWEndpoint) -> String {
        let description = endpoint.description
        if let colonIndex = description.firstIndex(of: ":") {
            return String(description[..<colonIndex])
        }
        return description.isEmpty ? fallbackDNS : description
    }
}

// MARK: - DNS Parser
private enum DNSParser {
    static func extractDomain(from data: Data) -> String? {
        guard data.count > 12 else { return nil }
        
        var offset = 12  // Skip DNS header
        var domain = ""
        
        while offset < data.count {
            let length = Int(data[offset])
            offset += 1
            
            if length == 0 { break }
            guard offset + length <= data.count,
                  let label = String(data: data[offset..<offset+length], encoding: .utf8) else {
                return nil
            }
            
            domain += label + "."
            offset += length
        }
        
        return domain.isEmpty ? nil : String(domain.dropLast())
    }
}

// MARK: - DNS Response Builder
private enum DNSResponseBuilder {
    static func createNXDomain(queryData: Data) -> Data? {
        var response = Data(queryData)
        guard response.count >= 12 else { return nil }
        
        response[2] = 0x85  // QR=1, Opcode=0, AA=1, RD=1
        response[3] = 0x83  // RA=1, RCODE=3 (NXDOMAIN)
        response[6...11] = Data(repeating: 0, count: 6)  // Zero out answer counts
        
        return response
    }
    
    static func createARecord(for domain: String, ip: String, queryData: Data) -> Data? {
        guard let ipBytes = parseIPv4(ip) else { return nil }
        
        var response = Data(queryData)
        guard response.count >= 12 else { return nil }
        
        response[2] = 0x81  // QR=1, RD=1
        response[3] = 0x80  // RA=1
        response[6] = 0
        response[7] = 1     // ANCOUNT = 1
        
        // Response section
        response.append(contentsOf: [0xc0, 0x0c])  // Name pointer
        response.append(contentsOf: [0x00, 0x01])  // Type A
        response.append(contentsOf: [0x00, 0x01])  // Class IN
        response.append(contentsOf: [0x00, 0x00, 0x01, 0x2c])  // TTL: 300s
        response.append(contentsOf: [0x00, 0x04])  // RDLENGTH: 4
        response.append(contentsOf: ipBytes)
        
        return response
    }
    
    private static func parseIPv4(_ ip: String) -> [UInt8]? {
        let parts = ip.split(separator: ".").compactMap { UInt8($0) }
        return parts.count == 4 ? parts : nil
    }
}

// MARK: - Array Extension
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
