//
//  MainTabView.swift
//  SubscriptionManager
//
//  Created by Srinivasa Rithik Ghantasala on 4/24/25.
//


import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @StateObject private var subscriptionService = SubscriptionService()
    @StateObject private var preferencesService = UserPreferencesService()
    @StateObject private var familyMemberService = FamilyMemberService()
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie.fill")
                }
            
            SubscriptionsListView()
                .tabItem {
                    Label("Subscriptions", systemImage: "list.bullet")
                }
            
            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "lightbulb.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .environmentObject(subscriptionService)
        .environmentObject(preferencesService)
        .environmentObject(familyMemberService)
        .onAppear {
            if let userId = authService.currentUser?.id {
                subscriptionService.setupSubscriptionsListener(for: userId)
                preferencesService.setupPreferencesListener(for: userId)
                familyMemberService.setupFamilyMembersListener(for: userId)
            }
        }
    }
}