//
//  WelcomeView.swift
//  SubscriptionManager
//
//  Created by Srinivasa Rithik Ghantasala on 4/24/25.
//


import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @State private var showSignUp = false
    @State private var showLogin = false
    
    var body: some View {
        ZStack {
            // Animated background (simplified for brevity)
            Color.blue.opacity(0.1).ignoresSafeArea()
            
            VStack(spacing: 30) {
                // App logo & title
                VStack(spacing: 15) {
                    Image(systemName: "creditcard.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                    
                    Text("SubscriptSmart")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)
                }
                .padding(.top, 60)
                
                Spacer()
                
                // App description
                VStack(spacing: 20) {
                    Text("Manage all your subscriptions in one place")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text("Track payments, get reminders, and save money with AI-powered recommendations")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 20) {
                    Button(action: {
                        showSignUp = true
                    }) {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 30)
                    
                    Button(action: {
                        showLogin = true
                    }) {
                        Text("I already have an account")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.bottom, 50)
            }
            .padding()
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView()
                .environmentObject(authService)
        }
        .sheet(isPresented: $showLogin) {
            LoginView()
                .environmentObject(authService)
        }
    }
}