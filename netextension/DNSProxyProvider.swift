//
//  DNSProxyProvider.swift
//  netextension
//
//  Created by Anton Yashyn on 06.12.2025.
//

import NetworkExtension
import Foundation

final class DNSProxyProvider: NEDNSProxyProvider {
    
    private var mappings: [String: String] = [:]
    private let fallbackDNS = "8.8.8.8"
    
    override func startProxy(options: [String : Any]? = nil, completionHandler: @escaping (Error?) -> Void) {
        loadMappings()
        NSLog("🚀 DNS Proxy STARTED with \(mappings.count) mappings: \(mappings)")
        NSLog("🚀 System DNS servers will be used for forwarding")
        completionHandler(nil)
    }
    
    override func stopProxy(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        NSLog("🛑 DNS Proxy STOPPED - reason: \(reason)")
        completionHandler()
    }
    
    override func sleep(completionHandler: @escaping () -> Void) {
        NSLog("😴 DNS Proxy going to sleep")
        completionHandler()
    }
    
    override func wake() {
        NSLog("👋 DNS Proxy waking up")
        loadMappings()
    }
    
    private func loadMappings() {
        let appGroup = "group.xyz.yashyn.NetOverride"
        guard let sharedDefaults = UserDefaults(suiteName: appGroup) else {
            NSLog("❌ Failed to access shared UserDefaults")
            return
        }
        
        guard let recordsData = sharedDefaults.data(forKey: "enabledOverrideRecords") else {
            NSLog("⚠️ No override records found")
            return
        }
        
        do {
            let decoder = PropertyListDecoder()
            let records = try decoder.decode([[String: String]].self, from: recordsData)
            
            mappings.removeAll()
            for record in records {
                if let domain = record["domain"], let destination = record["destination"] {
                    mappings[domain.lowercased()] = destination
                    NSLog("📝 Loaded mapping: \(domain) → \(destination)")
                }
            }
        } catch {
            NSLog("❌ Failed to decode override records: \(error.localizedDescription)")
        }
    }
    
    override func handleNewUDPFlow(_ flow: NEAppProxyUDPFlow, initialRemoteEndpoint remoteEndpoint: NWEndpoint) -> Bool {
        NSLog("🔵 NEW UDP FLOW to \(remoteEndpoint)")
        
        // Reload mappings on each flow to catch updates
        loadMappings()
        
        // Open the flow
        flow.open(withLocalEndpoint: nil) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                NSLog("❌ Error opening flow: \(error)")
                return
            }
            
            NSLog("✅ Flow opened successfully, starting to read...")
            self.readFromFlow(flow, systemDNS: remoteEndpoint)
        }
        
        return true
    }
    
    private func readFromFlow(_ flow: NEAppProxyUDPFlow, systemDNS: NWEndpoint) {
        flow.readDatagrams { [weak self] datagrams, endpoints, error in
            guard let self = self else { return }
            
            if let error = error {
                NSLog("❌ Error reading datagrams: \(error)")
                return
            }
            
            guard let datagrams = datagrams, !datagrams.isEmpty else {
                // Continue reading
                self.readFromFlow(flow, systemDNS: systemDNS)
                return
            }
            
            NSLog("📦 Received \(datagrams.count) datagram(s)")
            
            // Process each datagram
            for (index, queryData) in datagrams.enumerated() {
                NSLog("📦 Datagram \(index + 1): \(queryData.count) bytes")
                
                var endpointArray: [NWEndpoint]? = nil
                if let endpoints = endpoints, index < endpoints.count {
                    endpointArray = [endpoints[index]]
                }
                
                self.handleDNSQuery(queryData, flow: flow, endpoints: endpointArray, systemDNS: systemDNS)
            }
            
            // Continue reading for more queries
            self.readFromFlow(flow, systemDNS: systemDNS)
        }
    }
    
    private func handleDNSQuery(_ queryData: Data, flow: NEAppProxyUDPFlow, endpoints: [NWEndpoint]?, systemDNS: NWEndpoint) {
        guard let domain = parseDomain(from: queryData) else {
            NSLog("❌ Failed to parse domain from query")
            forwardToUpstreamDNS(queryData, flow: flow, endpoints: endpoints, systemDNS: systemDNS)
            return
        }
        
        NSLog("🔍 DNS Query for: \(domain)")
        
        // Check for exact domain match
        if let ip = mappings[domain.lowercased()] {
            NSLog("✅ Found exact mapping: \(domain) -> \(ip)")
            if let responseData = createDNSResponse(for: domain, ip: ip, queryData: queryData) {
                flow.writeDatagrams([responseData], sentBy: endpoints ?? []) { error in
                    if let error = error {
                        NSLog("❌ Error writing response: \(error)")
                    } else {
                        NSLog("✅ Successfully sent custom response for \(domain) -> \(ip)")
                    }
                }
                return
            }
        }
        
        // Check if this is a subdomain of any configured domain
        for configuredDomain in mappings.keys {
            if domain.hasSuffix("." + configuredDomain) {
                NSLog("🚫 Subdomain of configured domain \(configuredDomain), returning NXDOMAIN for \(domain)")
                if let nxdomainResponse = createNXDomainResponse(queryData: queryData) {
                    flow.writeDatagrams([nxdomainResponse], sentBy: endpoints ?? []) { error in
                        if let error = error {
                            NSLog("❌ Error writing NXDOMAIN response: \(error)")
                        } else {
                            NSLog("✅ Successfully sent NXDOMAIN for subdomain \(domain)")
                        }
                    }
                }
                return
            }
        }
        
        NSLog("🔄 No mapping found for \(domain), forwarding to system DNS")
        forwardToUpstreamDNS(queryData, flow: flow, endpoints: endpoints, systemDNS: systemDNS)
    }
    
    private func forwardToUpstreamDNS(_ queryData: Data, flow: NEAppProxyUDPFlow, endpoints: [NWEndpoint]?, systemDNS: NWEndpoint) {
        let dnsServer = extractHostFromEndpoint(systemDNS)
        NSLog("🔄 Forwarding to system DNS (\(dnsServer))...")
        
        // Use BSD sockets for upstream DNS query
        DispatchQueue.global().async {
            var hints = addrinfo()
            hints.ai_family = AF_INET
            hints.ai_socktype = SOCK_DGRAM
            hints.ai_protocol = IPPROTO_UDP
            
            var servinfo: UnsafeMutablePointer<addrinfo>?
            let result = getaddrinfo(dnsServer, "53", &hints, &servinfo)
            
            guard result == 0, let info = servinfo else {
                NSLog("❌ Failed to resolve upstream DNS")
                return
            }
            
            defer { freeaddrinfo(servinfo) }
            
            let sockfd = socket(info.pointee.ai_family, info.pointee.ai_socktype, info.pointee.ai_protocol)
            guard sockfd >= 0 else {
                NSLog("❌ Failed to create socket")
                return
            }
            
            defer { close(sockfd) }
            
            // Set timeout
            var timeout = timeval(tv_sec: 5, tv_usec: 0)
            setsockopt(sockfd, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
            
            // Send query
            let sent = queryData.withUnsafeBytes { bytes in
                sendto(sockfd, bytes.baseAddress, queryData.count, 0, info.pointee.ai_addr, info.pointee.ai_addrlen)
            }
            
            guard sent == queryData.count else {
                NSLog("❌ Failed to send DNS query (sent \(sent) of \(queryData.count) bytes)")
                return
            }
            
            NSLog("✅ Sent \(sent) bytes to upstream DNS")
            
            // Receive response
            var buffer = [UInt8](repeating: 0, count: 512)
            let received = recvfrom(sockfd, &buffer, buffer.count, 0, nil, nil)
            
            guard received > 0 else {
                NSLog("❌ Failed to receive DNS response (received: \(received))")
                return
            }
            
            let responseData = Data(buffer.prefix(received))
            NSLog("✅ Received \(responseData.count) bytes from upstream DNS")
            
            flow.writeDatagrams([responseData], sentBy: endpoints ?? []) { error in
                if let error = error {
                    NSLog("❌ Error writing upstream response: \(error)")
                } else {
                    NSLog("✅ Successfully forwarded upstream response")
                }
            }
        }
    }
    
    private func extractHostFromEndpoint(_ endpoint: NWEndpoint) -> String {
        let endpointString = endpoint.description
        if let colonIndex = endpointString.firstIndex(of: ":") {
            return String(endpointString[..<colonIndex])
        }
        return endpointString.isEmpty ? fallbackDNS : endpointString
    }
    
    private func parseDomain(from data: Data) -> String? {
        guard data.count > 12 else { return nil }
        var offset = 12 // Skip header
        var domain = ""
        while offset < data.count {
            let length = Int(data[offset])
            offset += 1
            if length == 0 { break }
            guard offset + length <= data.count else { return nil }
            if let str = String(data: data[offset..<offset+length], encoding: .utf8) {
                domain += str + "."
            } else {
                return nil
            }
            offset += length
        }
        return domain.hasSuffix(".") ? String(domain.dropLast()) : domain
    }
    
    private func createNXDomainResponse(queryData: Data) -> Data? {
        var response = Data(queryData)
        
        // Set response flags for NXDOMAIN
        response[2] = 0x85 // QR=1, Opcode=0, AA=1, RD=1
        response[3] = 0x83 // RA=1, RCODE=3 (NXDOMAIN)
        
        // Answer count = 0
        response[6] = 0
        response[7] = 0
        response[8] = 0
        response[9] = 0
        response[10] = 0
        response[11] = 0
        
        return response
    }
    
    private func createDNSResponse(for domain: String, ip: String, queryData: Data) -> Data? {
        var response = Data(queryData)
        
        // Set response flags
        response[2] = 0x81 // QR=1, RD=1
        response[3] = 0x80 // RA=1
        
        // Set answer count
        response[6] = 0
        response[7] = 1 // ANCOUNT = 1
        
        // Answer section
        response.append(0xc0)
        response.append(0x0c) // Pointer to question name
        
        // Type A
        response.append(0)
        response.append(1)
        
        // Class IN
        response.append(0)
        response.append(1)
        
        // TTL 300 seconds
        response.append(0)
        response.append(0)
        response.append(0x01)
        response.append(0x2c)
        
        // RDATA length 4
        response.append(0)
        response.append(4)
        
        // IP address
        let ipParts = ip.split(separator: ".").compactMap { UInt8($0) }
        guard ipParts.count == 4 else { return nil }
        response.append(contentsOf: ipParts)
        
        return response
    }
}
