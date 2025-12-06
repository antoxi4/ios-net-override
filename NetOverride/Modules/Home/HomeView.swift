//
//  HomeView.swift
//  NetOverride
//
//  Created by Anton Yashyn on 01.12.2025.
//

import Foundation
import SwiftUI
import SwiftData
import NetworkExtension

struct HomeView: RouteView {
    @ObservedObject var appRouter: AppRouter
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \OverrideRecord.createdAt, order: .reverse) private var records: [OverrideRecord]
    
    @State private var isOverrideOn = false
    @State private var isCreateModalVisible = false
    @State private var editingRecord: OverrideRecord?
    @State private var showPermissionAlert: Bool = false
    
    private let dnsProxyService = DNSProxy()
    
    var body: some View {
        OverrideListView(
            isOverrideOn: $isOverrideOn,
            records: records,
            onEdit: self.startEditing,
            onDelete: self.deleteRecord,
            showCreateModal: self.showCreateModal
        )
        .sheet(isPresented: $isCreateModalVisible) {
            AddOverrideRecordView(overrideRecord: nil)
                .background(Color("BgPrimary"))
        }
        .sheet(
            item: $editingRecord,
            onDismiss: {
                editingRecord = nil
            },
            content: { record in
                AddOverrideRecordView(overrideRecord: record)
                    .background(Color("BgPrimary"))
            }
        )
        .alert(
            "Action Required",
            isPresented: $showPermissionAlert,
            actions: {
                Button(role: .destructive) {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                } label: {
                    Text("Open Settings")
                }
            },
            message: {Text("Go to Settings → General → VPN & Device Management → DNS and toggle ON 'DNS Override' to activate the proxy.\n\nIMPORTANT: Make sure your WiFi is connected.")}
        )
        .contentMargins(16)
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle("DNS Overrides")
        .toolbarColorScheme(.dark, for: .navigationBar, .tabBar)
        .toolbarBackground(Color("BgPrimary"), for: .navigationBar, .tabBar)
        .toolbarBackground(.visible, for: .navigationBar, .tabBar)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("BgPrimary"))
        .onAppear {
            Task {
                await checkProxyStatus()
            }
        }
        .onChange(of: isOverrideOn) { _, newValue in
            Task {
                await handleProxyToggle(enabled: newValue)
            }
        }
    }
}

// MARK: Handlers
private extension HomeView {
    private func checkProxyStatus() async {
        do {
            let state = try await dnsProxyService.getDNSProxyState()
            
            isOverrideOn = state == .enabled
        } catch {
            print("Failed to check proxy status: \(error)")
        }
    }
    
    private func handleProxyToggle(enabled: Bool) async {
        do {
            if enabled {
                // Store records before enabling
                let enabledRecords = records.filter { $0.enabled }
                let recordsData: [DNSProxy.DNSRecord] = enabledRecords.map { record in
                    .init(id: record.id.uuidString, destination: record.destination, domain: record.domain)
                }
                try dnsProxyService.storeRecords(records: recordsData)
                
                try await dnsProxyService.enableDNSProxy()
            } else {
                try await dnsProxyService.disableDNSProxy()
            }
        } catch {
            print("Error toggling DNS proxy: \(error)")
            // Revert toggle on error
            DispatchQueue.main.async {
                isOverrideOn = !enabled
            }
        }
    }
    
    private func showCreateModal() {
        self.isCreateModalVisible = true
    }
    
    private func startEditing(record: OverrideRecord) {
        self.$editingRecord.wrappedValue = record
    }
    
    private func deleteRecord(record: OverrideRecord) {
        self.modelContext.delete(record)
    }
}
