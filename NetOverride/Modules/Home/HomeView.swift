//
//  HomeView.swift
//  NetOverride
//
//  Created by Anton Yashyn on 01.12.2025.
//

import Foundation
import SwiftUI
import SwiftData

struct HomeView: RouteView {
    @ObservedObject var appRouter: AppRouter
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \OverrideRecord.createdAt, order: .reverse) private var records: [OverrideRecord]
    
    @State private var isOverrideOn = false
    @State private var isCreateModalVisible = false
    @State private var editingRecord: OverrideRecord?
    
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
    }
}

// MARK: Handlers
private extension HomeView {
    private func showCreateModal() {
        self.appRouter.route(to: .home)
        self.isCreateModalVisible = true
    }
    
    private func startEditing(record: OverrideRecord) {
        self.$editingRecord.wrappedValue = record
    }
    
    private func deleteRecord(record: OverrideRecord) {
        self.modelContext.delete(record)
    }
}
