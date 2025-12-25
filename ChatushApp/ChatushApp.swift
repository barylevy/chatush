//
//  ChatushApp.swift
//  Chatush
//
//  Created by Bari.Levi on 24/12/2025.
//

import SwiftUI
import Factory
import SwiftData

@main
struct ChatushApp: App {
    
    @Injected(\.modelContainer) private var modelContainer
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(modelContainer)
    }
}
