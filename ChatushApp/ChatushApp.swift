//
//  ChatushApp.swift
//  Chatush
//
//  Created by Bari.Levi on 24/12/2025.
//

import Factory
import SwiftData
import SwiftUI

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
