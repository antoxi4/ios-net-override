//
//  OverrideListItemView.swift
//  NetOverride
//
//  Created by Anton Yashyn on 01.12.2025.
//

import Foundation
import SwiftUI

struct OverrideListItemView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var record: OverrideRecord
    @Binding var isOverrideEnabled: Bool
    let onEdit: (OverrideRecord) -> Void
    
    private var iconColor: Color {
        if (!isOverrideEnabled) {
            return Color.red
        } else if (record.enabled) {
            return Color.green
        } else {
            return Color.gray
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "network").foregroundStyle(iconColor)
            VStack(alignment: .leading, spacing: 4) {
                Text(record.domain)
                    .font(.headline)
                    .foregroundStyle(Color("TextPrimary"))
                Label(record.destination, systemImage: "arrow.forward")
                    .font(.subheadline)
                    .foregroundStyle(Color("TextSecondary"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Toggle("", isOn: $record.enabled)
                .tint(Color.blue)
                .fixedSize()
        }
        .padding()
        .foregroundStyle(Color.white)
        .background(Color("BgSecondary"))
        .clipShape(.buttonBorder)
        .onChange(of: record.enabled) { oldValue, newValue in
            do {
                try modelContext.save()
            } catch {
                print("Failed to save: \(error)")
            }
        }
        .contextMenu {
            Button {
                onEdit(record)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                modelContext.delete(record)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        
    }
}
