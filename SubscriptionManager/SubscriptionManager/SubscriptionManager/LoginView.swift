//
//  LoginView.swift
//  SubscriptionManager
//
//  Created by Srinivasa Rithik Ghantasala on 4/24/25.
//


import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthenticationService
    
    @State private var email = ""
    @State private var password = ""
    @State private var showForgotPassword = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // App logo
                Image(systemName: "creditcard.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                    .padding(.top, 40)
                
                // Login form
                VStack(spacing: 20) {
                    Text("Welcome Back")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 15) {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        
                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                    
                    Button(action: {
                        showForgotPassword = true
                    }) {
                        Text("Forgot password?")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 5)
                }
                
                Spacer()
                
                // Login button
                Button(action: login) {
                    Text("Login")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(!isFormValid || authService.isLoading)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationBarItems(
                leading: Button(action: {
                    dismiss()
                }) {
                    Text("Cancel")
                        .foregroundColor(.blue)
                }
            )
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
                    .environmentObject(authService)
            }
            .overlay(
                Group {
                    if authService.isLoading {
                        LoadingView()
                    }
                }
            )
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    private func login() {
        authService.signIn(email: email, password: password) { _ in
            // Authentication state will be handled by the AuthStateDidChangeListener
            dismiss()
        }
    }
}