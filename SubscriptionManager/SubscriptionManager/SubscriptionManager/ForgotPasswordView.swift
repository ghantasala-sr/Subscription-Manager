//
//  ForgotPasswordView.swift
//  SubscriptionManager
//
//  Created by Srinivasa Rithik Ghantasala on 4/24/25.
//


import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthenticationService
    
    @State private var email = ""
    @State private var resetSent = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                if resetSent {
                    // Success message
                    VStack(spacing: 20) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .padding(.top, 40)
                        
                        Text("Reset Email Sent")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("We've sent password reset instructions to your email. Please check your inbox.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Return to Login")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                } else {
                    // Request form
                    VStack(alignment: .center, spacing: 20) {
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .padding(.top, 40)
                        
                        Text("Reset Your Password")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Enter your email address and we'll send you instructions to reset your password.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                        
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                        
                        Button(action: resetPassword) {
                            Text("Send Reset Instructions")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(!email.isEmpty ? Color.blue : Color.gray)
                                .cornerRadius(10)
                        }
                        .disabled(email.isEmpty || authService.isLoading)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                }
                
                Spacer()
            }
            .navigationBarItems(
                leading: Button(action: {
                    dismiss()
                }) {
                    Text("Cancel")
                        .foregroundColor(.blue)
                }
            )
            .overlay(
                Group {
                    if authService.isLoading {
                        LoadingView()
                    }
                }
            )
        }
    }
    
    private func resetPassword() {
        authService.resetPassword(email: email) { success in
            if success {
                resetSent = true
            }
        }
    }
}