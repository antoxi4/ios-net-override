//
//  AddOverrideRecord.swift
//  NetOverride
//
//  Created by Anton Yashyn on 01.12.2025.
//

import Foundation
import SwiftUI

struct AddOverrideRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let record: OverrideRecord?
    
    @State private var domain: String = ""
    @State private var destination: String = ""
    
    init(overrideRecord: OverrideRecord? = nil) {
        self.record = overrideRecord
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    TextField("Domain", text: $domain)
                        .listRowBackground(Color("BgSecondary"))
                    TextField("Destination", text: $destination)
                        .listRowBackground(Color("BgSecondary"))
                }
                .scrollContentBackground(.hidden)
                .preferredColorScheme(.dark)
            }
            .contentShape(Rectangle())
            .onAppear {
                if let record = record {
                    domain = record.domain
                    destination = record.destination
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(record == nil ? "Add Record" : "Edit Record")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let existingRecord = record {
                            existingRecord.domain = domain
                            existingRecord.destination = destination
                        } else {
                            let newRecord = OverrideRecord(destination: destination, domain: domain)
                            modelContext.insert(newRecord)
                        }
                        do {
                            try modelContext.save()
                        } catch {
                            print("Failed to save: \(error)")
                        }
                        dismiss()
                    }
                    .disabled(domain.isEmpty || destination.isEmpty)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbarBackground(Color("BgPrimary"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
        .presentationBackground(Color("BgPrimary"))
    }
}
