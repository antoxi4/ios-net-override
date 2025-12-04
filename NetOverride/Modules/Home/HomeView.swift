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
    unowned let appRouter: AppRouter
    
    @Query(sort: \OverrideRecord.createdAt, order: .reverse) var records: [OverrideRecord]
    
    @State var isCreateModalVisible = false
    @State var isOverrideOn = false
    @State var editingRecord: OverrideRecord?
    
    init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16, pinnedViews: [.sectionHeaders]) {
                Section {
                    ForEach(records) { record in
                        OverrideListItemView(
                            record: record, 
                            isOverrideEnabled: $isOverrideOn, 
                            onEdit: { editRecord in
                                editingRecord = editRecord
                            }
                        )
                    }
                } header: {
                    SectionHeaderView(title: "Override", isEnabled: $isOverrideOn)
                        .textCase(nil)
                }
            }
            .safeAreaPadding(.bottom)
            .listStyle(.insetGrouped)
            .sheet(isPresented: $isCreateModalVisible) {
                AddOverrideRecord(overrideRecord: nil)
            }
            .sheet(item: $editingRecord, onDismiss: {
                editingRecord = nil
            }) { record in
                AddOverrideRecord(overrideRecord: record)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: showCreateModal) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
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
        isCreateModalVisible = true
    }
}
