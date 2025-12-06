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
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            OverrideRecord.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Add default record if none exist
            let context = container.mainContext
            let fetchDescriptor = FetchDescriptor<OverrideRecord>()
            let existingRecords = try? context.fetch(fetchDescriptor)
            
            if existingRecords?.isEmpty ?? true {
                let defaultRecord = OverrideRecord(destination: "192.168.88.252", domain: "parasol-router.test")
                defaultRecord.enabled = true
                context.insert(defaultRecord)
                try? context.save()
            }
            
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $appRouter.path) {
                HomeView(appRouter: appRouter)
                    .navigationDestination(for: AppRouter.Route.self) { value in
                        appRouter.getCurrentView(route: value)
                    }
            }
            .modelContainer(sharedModelContainer)
        }
    }
}
