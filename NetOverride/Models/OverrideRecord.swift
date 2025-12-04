//
//  OverrideRecord.swift
//  NetOverride
//
//  Created by Anton Yashyn on 01.12.2025.
//

import Foundation
import SwiftData

@Model
class OverrideRecord: Identifiable {
    var id: UUID = UUID()
    var destination: String
    var domain: String
    var enabled: Bool = false
    var createdAt: Date = Date()
    
    init(destination: String, domain: String) {
        self.destination = destination
        self.domain = domain
    }
}
