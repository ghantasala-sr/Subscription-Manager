//
//  SignUpView.swift
//  SubscriptionManager
//
//  Created by Srinivasa Rithik Ghantasala on 4/24/25.
//


import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthenticationService
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var monthlyBudget = 100.0
    @State private var yearlyBudget = 1200.0
    @State private var currentStep = 0
    
    var body: some View {
        NavigationView {
            VStack {
                // Progress indicator
                HStack(spacing: 0) {
                    ForEach(0..<3) { step in
                        Rectangle()
                            .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(height: 4)
                            .animation(.spring(), value: currentStep)
                        
                        if step < 2 {
                            Spacer()
                                .frame(width: 10)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Main content
                TabView(selection: $currentStep) {
                    // Step 1: Account information
                    VStack(spacing: 20) {
                        Text("Create Your Account")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.top, 20)
                        
                        VStack(spacing: 15) {
                            TextField("Email", text: $email)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                            
                            SecureField("Password", text: $password)
                                .textContentType(.newPassword)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                            
                            SecureField("Confirm Password", text: $confirmPassword)
                                .textContentType(.newPassword)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                        
                        Button(action: {
                            if validateStep1() {
                                withAnimation {
                                    currentStep = 1
                                }
                            }
                        }) {
                            Text("Next")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isStep1Valid ? Color.blue : Color.gray)
                                .cornerRadius(10)
                        }
                        .disabled(!isStep1Valid)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .tag(0)
                    
                    // Step 2: Personal information
                    VStack(spacing: 20) {
                        Text("Tell Us About Yourself")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.top, 20)
                        
                        VStack(spacing: 15) {
                            TextField("First Name (Optional)", text: $firstName)
                                .textContentType(.givenName)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                            
                            TextField("Last Name (Optional)", text: $lastName)
                                .textContentType(.familyName)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                        
                        HStack {
                            Button(action: {
                                withAnimation {
                                    currentStep = 0
                                }
                            }) {
                                Text("Back")
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
                            
                            Button(action: {
                                withAnimation {
                                    currentStep = 2
                                }
                            }) {
                                Text("Next")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .tag(1)
                    
                    // Step 3: Budget settings
                    VStack(spacing: 20) {
                        Text("Set Your Budget")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.top, 20)
                        
                        Text("This helps us track your spending and provide personalized recommendations")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 15) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Monthly Budget")
                                    .font(.headline)
                                
                                HStack {
                                    Text("$")
                                        .foregroundColor(.secondary)
                                    
                                    TextField("0.00", value: $monthlyBudget, format: .number)
                                        .keyboardType(.decimalPad)
                                        .onChange(of: monthlyBudget) { newValue in
                                            yearlyBudget = newValue * 12
                                        }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                            }
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Yearly Budget")
                                    .font(.headline)
                                
                                HStack {
                                    Text("$")
                                        .foregroundColor(.secondary)
                                    
                                    TextField("0.00", value: $yearlyBudget, format: .number)
                                        .keyboardType(.decimalPad)
                                        .onChange(of: yearlyBudget) { newValue in
                                            monthlyBudget = newValue / 12
                                        }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                        
                        HStack {
                            Button(action: {
                                withAnimation {
                                    currentStep = 1
                                }
                            }) {
                                Text("Back")
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
                            
                            Button(action: createAccount) {
                                Text("Create Account")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
                .disabled(authService.isLoading)
            }
            .navigationBarItems(
                leading: Button(action: {
                    dismiss()
                }) {
                    Text("Cancel")
                        .foregroundColor(.blue)
                }
            )
        }
        .overlay(
            Group {
                if authService.isLoading {
                    LoadingView()
                }
            }
        )
    }
    
    private var isStep1Valid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        return emailPredicate.evaluate(with: email) &&
               password.count >= 8 &&
               password == confirmPassword
    }
    
    private func validateStep1() -> Bool {
        return isStep1Valid
    }
    
    private func createAccount() {
        authService.signUp(
            email: email,
            password: password,
            firstName: firstName.isEmpty ? nil : firstName,
            lastName: lastName.isEmpty ? nil : lastName,
            monthlyBudget: monthlyBudget,
            yearlyBudget: yearlyBudget
        ) { success in
            if success {
                dismiss()
            }
        }
    }
}