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
    @State private var isLoading = false
    
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
        .contentMargins(16)
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle("DNS Overrides")
        .toolbarColorScheme(.dark, for: .navigationBar, .tabBar)
        .toolbarBackground(Color("BgPrimary"), for: .navigationBar, .tabBar)
        .toolbarBackground(.visible, for: .navigationBar, .tabBar)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("BgPrimary"))
        .overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
        }
        .onAppear {
            Task {
                await checkProxyStatus()
            }
        }
        .onChange(of: records) {
            
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
        let state = await dnsProxyService.getDNSProxyState()
        isOverrideOn = state == .enabled
    }
    
    private func handleRecordsUpdate() async {
        do {
            let isProxyActive = await dnsProxyService.getDNSProxyState() == .enabled
            
            if (isProxyActive) {
                isLoading = true
                try await dnsProxyService.disableDNSProxy()
                try await dnsProxyService.enableDNSProxy()
                isLoading = false
            }
        } catch {
            isLoading = false
            Logger.error(error)
        }
    }
    
    private func handleProxyToggle(enabled: Bool) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            if enabled {
                // Store records before enabling
                let enabledRecords = records.filter { $0.enabled }
                let recordsData: [DNSProxy.DNSRecord] = enabledRecords.map { record in
                        .init(id: record.id.uuidString, destination: record.destination, domain: record.domain)
                }
                try dnsProxyService.storeRecords(recordsData)
                
                try await dnsProxyService.enableDNSProxy()
            } else {
                try await dnsProxyService.disableDNSProxy()
            }
        } catch {
            Logger.error("Error toggling DNS proxy: \(error)")
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
