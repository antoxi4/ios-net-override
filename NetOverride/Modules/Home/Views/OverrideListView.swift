//
//  OverrideListView.swift
//  NetOverride
//
//  Created by Anton Yashyn on 04.12.2025.
//

import Foundation
import SwiftUICore
import SwiftUI

struct OverrideListView: View {
    @Binding var isOverrideOn: Bool
    
    let records: [OverrideRecord]
    let onEdit: (OverrideRecord) -> Void
    let onDelete: (OverrideRecord) -> Void
    let showCreateModal: () -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16, pinnedViews: [.sectionHeaders]) {
                Section {
                    ForEach(records) { record in
                        OverrideListItemView(
                            record: record,
                            isOverrideEnabled: $isOverrideOn,
                            onEdit: onEdit,
                            onDelete: onDelete
                        )
                    }
                } header: {
                    SectionHeaderView(title: "Override", isEnabled: $isOverrideOn)
                        .textCase(nil)
                }
            }
            .safeAreaPadding(.bottom)
            .listStyle(.insetGrouped)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: showCreateModal) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
    }
}
