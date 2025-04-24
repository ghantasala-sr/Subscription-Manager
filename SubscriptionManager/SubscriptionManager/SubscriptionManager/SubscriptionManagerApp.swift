//
//  SubscriptionManagerApp.swift
//  SubscriptionManager
//
//  Created by Srinivasa Rithik Ghantasala on 4/23/25.
//

import SwiftUI
import FirebaseCore

@main
struct SubscriptionManagerApp: App {
    init() {
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
