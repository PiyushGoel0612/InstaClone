//
//  InstaCloneApp.swift
//  InstaClone
//
//  Created by Piyush Goel on 11/12/25.
//

import SwiftUI
import CoreData

@main
struct InstaCloneApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        URLCache.shared = URLCache(
            memoryCapacity: 50 * 1024 * 1024,   // 50 MB
            diskCapacity: 500 * 1024 * 1024     // 500 MB
        )
    }

    var body: some Scene {
        WindowGroup {
            LoginView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
