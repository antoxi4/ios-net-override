//
//  RouteView.swift
//  NetOverride
//
//  Created by Anton Yashyn on 01.12.2025.
//

import SwiftUI

protocol RouteView: View {
    var appRouter: AppRouter { get }
    
    init(appRouter: AppRouter)
}
