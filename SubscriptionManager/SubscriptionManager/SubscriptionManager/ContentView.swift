//
//  ContentView 2.swift
//  SubscriptionManager
//
//  Created by Srinivasa Rithik Ghantasala on 4/24/25.
//


import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthenticationService()
    
    var body: some View {
        ZStack {
            if authService.isAuthenticated {
                if authService.isEmailVerified {
                    // Fully authenticated and verified user
                    MainTabView()
                        .environmentObject(authService)
                } else {
                    // User is authenticated but email not verified
                    EmailVerificationView()
                        .environmentObject(authService)
                }
            } else {
                // Not authenticated
                WelcomeView()
                    .environmentObject(authService)
            }
            
            if authService.isLoading {
                LoadingView()
            }
        }
        .alert(isPresented: .constant(authService.errorMessage != nil)) {
            Alert(
                title: Text("Error"),
                message: Text(authService.errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK")) {
                    authService.errorMessage = nil
                }
            )
        }
    }
}
