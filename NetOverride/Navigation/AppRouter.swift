//
//  AppRouter.swift
//  NetOverride
//
//  Created by Anton Yashyn on 01.12.2025.
//

import Foundation
import SwiftUI

class AppRouter: ObservableObject {
    @Published var path = NavigationPath()
    
    func route(to: Route) {
        path.append(to)
    }
    
    func reset() {
        path = NavigationPath()
    }
}

extension AppRouter {
    @ViewBuilder
    func getCurrentView(route: Route) -> some View {
        switch route {
        case .home:
            HomeView(appRouter: self)
        }
    }
}

extension AppRouter {
    enum Route {
        case home
    }
}
