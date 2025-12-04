//
//  SectionHeaderView.swift
//  NetOverride
//
//  Created by Anton Yashyn on 03.12.2025.
//

import SwiftUI

struct SectionHeaderView: View {
    let title: String
    @Binding var isEnabled: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.white)
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .tint(.green)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(.buttonBorder)
    }
}
