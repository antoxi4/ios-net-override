//
//  NetOverrideApp.swift
//  NetOverride
//
//  Created by Anton Yashyn on 30.11.2025.
//

import SwiftUI
import SwiftData

@main
struct NetOverrideApp: App {
    @StateObject var appRouter = AppRouter()

    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $appRouter) {
                HomeView(appRouter: appRouter)
                    .navigationDestination(for: AppRouter.Route.self) { value in
                        appRouter.getCurrentView(route: value)
                    }
            }
            .modelContainer(for: [
                OverrideRecord.self,
            ])
        }
    }
}
