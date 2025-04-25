//
//  ChangePasswordView.swift
//  SubscriptionManager
//
//  Created by Srinivasa Rithik Ghantasala on 4/25/25.
//


import SwiftUI
import FirebaseAuth

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthenticationService
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showingSuccessAlert = false
    
    var body: some View {
        Form {
            Section(header: Text("Current Password")) {
                SecureField("Enter current password", text: $currentPassword)
                    .textContentType(.password)
            }
            
            Section(header: Text("New Password")) {
                SecureField("New password", text: $newPassword)
                    .textContentType(.newPassword)
                
                SecureField("Confirm new password", text: $confirmPassword)
                    .textContentType(.newPassword)
                
                if !passwordsMatch {
                    Text("Passwords do not match")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                if !passwordMeetsRequirements {
                    Text("Password must be at least 8 characters")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            Section {
                Button(action: changePassword) {
                    Text("Update Password")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(isFormValid ? .blue : .gray)
                }
                .disabled(!isFormValid || isLoading)
            }
        }
        .navigationTitle("Change Password")
        .overlay(
            Group {
                if isLoading {
                    LoadingView()
                }
            }
        )
        .alert(isPresented: .constant(errorMessage != nil)) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK")) {
                    errorMessage = nil
                }
            )
        }
        .alert(isPresented: $showingSuccessAlert) {
            Alert(
                title: Text("Success"),
                message: Text("Your password has been changed successfully."),
                dismissButton: .default(Text("OK")) {
                    dismiss()
                }
            )
        }
    }
    
    private var passwordsMatch: Bool {
        return newPassword == confirmPassword
    }
    
    private var passwordMeetsRequirements: Bool {
        return newPassword.count >= 8
    }
    
    private var isFormValid: Bool {
        return !currentPassword.isEmpty &&
               !newPassword.isEmpty &&
               !confirmPassword.isEmpty &&
               passwordsMatch &&
               passwordMeetsRequirements &&
               currentPassword != newPassword
    }
    
    private func changePassword() {
        isLoading = true
        
        // Get the current user
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            errorMessage = "Current user not found"
            isLoading = false
            return
        }
        
        // Reauthenticate the user with their current password
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        
        user.reauthenticate(with: credential) { _,error  in

            if let error = error {
                self.errorMessage = "Authentication failed"
                self.isLoading = false
                return
            }
            
            // Now update to the new password
            user.updatePassword(to: self.newPassword) { error in
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to update password: \(error.localizedDescription)"
                    return
                }
                
                // Password updated successfully
                self.showingSuccessAlert = true
            }
        }
    }
}
