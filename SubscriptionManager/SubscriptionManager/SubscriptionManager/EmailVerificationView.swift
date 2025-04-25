//
//  EmailVerificationView.swift
//  SubscriptionManager
//
//  Created by Srinivasa Rithik Ghantasala on 4/25/25.
//


import SwiftUI

struct EmailVerificationView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isCheckingVerification = false
    @State private var isResendingEmail = false
    
    var body: some View {
        VStack(spacing: 25) {
            // Header
            Image(systemName: "envelope.badge")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .padding(.top, 50)
            
            Text("Verify Your Email")
                .font(.title)
                .fontWeight(.bold)
            
            if let email = authService.pendingVerificationEmail {
                Text("We've sent a verification link to:\n\(email)")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text("Please verify your email address to continue")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Text("Check your inbox and click the verification link to proceed.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .padding(.top, 5)
            
            // Action buttons
            VStack(spacing: 15) {
                Button(action: checkVerification) {
                    HStack {
                        if isCheckingVerification {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise.circle")
                        }
                        Text("I've Verified My Email")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .disabled(isCheckingVerification || isResendingEmail)
                
                Button(action: resendVerificationEmail) {
                    HStack {
                        if isResendingEmail {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "envelope")
                        }
                        Text("Resend Verification Email")
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue, lineWidth: 1)
                    )
                }
                .disabled(isCheckingVerification || isResendingEmail)
                
                Button(action: {
                    authService.signOut()
                }) {
                    Text("Sign Out")
                        .foregroundColor(.red)
                        .padding(.top, 20)
                }
            }
            .padding(.horizontal, 30)
            .padding(.top, 30)
            
            Spacer()
        }
        .padding()
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(alertMessage.contains("success") ? "Success" : "Notice"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func checkVerification() {
        isCheckingVerification = true
        
        authService.checkEmailVerification { success in
            isCheckingVerification = false
            
            if !success {
                alertMessage = "Your email is not verified yet. Please check your inbox and click the verification link."
                showingAlert = true
            }
            // If successful, the auth listener will update the UI
        }
    }
    
    private func resendVerificationEmail() {
        isResendingEmail = true
        
        authService.resendVerificationEmail { success in
            isResendingEmail = false
            
            if success {
                alertMessage = "Verification email has been sent successfully. Please check your inbox."
                showingAlert = true
            }
            // If there's an error, it will be shown through the authService.errorMessage
        }
    }
}