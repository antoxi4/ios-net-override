//
//  AddOverrideRecord.swift
//  NetOverride
//
//  Created by Anton Yashyn on 01.12.2025.
//

import Foundation
import SwiftUI

struct AddOverrideRecord: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let overrideRecord: OverrideRecord?
    
    @State private var domain: String = ""
    @State private var destination: String = ""
    
    init(overrideRecord: OverrideRecord? = nil) {
        self.overrideRecord = overrideRecord
    }

    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    TextField("Domain", text: $domain)
                    TextField("Destination", text: $destination)
                }
                .preferredColorScheme(.dark)
            }
            .onAppear {
                if let record = overrideRecord {
                    domain = record.domain
                    destination = record.destination
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(overrideRecord == nil ? "Add Record" : "Edit Record")
                        
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let existingRecord = overrideRecord {
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
        }
    }
}
