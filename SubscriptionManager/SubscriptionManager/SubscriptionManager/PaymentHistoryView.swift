//
//  PaymentHistoryView.swift
//  SubscriptionManager
//
//  Created by Srinivasa Rithik Ghantasala on 4/24/25.
//


import SwiftUI

struct PaymentHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionService: SubscriptionService
    
    var subscription: Subscription
    
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showingAddPayment = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Spacer()
                        LogoImageView(logoName: subscription.logoName, size: 60)
                            .padding(.vertical, 10)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                    
                    HStack {
                        Text("Subscription")
                        Spacer()
                        Text(subscription.name)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Amount")
                        Spacer()
                        Text("$\(subscription.cost, specifier: "%.2f")")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Billing Cycle")
                        Spacer()
                        Text(subscription.billingCycle.displayName)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Next Billing Date")
                        Spacer()
                        Text(formatDate(subscription.nextBillingDate))
                            .foregroundColor(.secondary)
                    }
                    
                    if let lastPayment = subscription.lastPaymentDate {
                        HStack {
                            Text("Last Payment")
                            Spacer()
                            Text(formatDate(lastPayment))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Payment History")) {
                    if let payments = subscription.paymentHistory, !payments.isEmpty {
                        ForEach(payments.sorted(by: { $0.date > $1.date })) { payment in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(formatDate(payment.date))
                                        .font(.subheadline)
                                    
                                    if let note = payment.note {
                                        Text(note)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Text("$\(payment.amount, specifier: "%.2f")")
                                    .font(.headline)
                            }
                        }
                    } else {
                        Text("No payment history")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 10)
                    }
                }
                
                Section {
                    Button(action: {
                        showingAddPayment = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                            Text("Record Payment")
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Payment History")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .sheet(isPresented: $showingAddPayment) {
                AddPaymentView(subscription: subscription)
            }
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
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct AddPaymentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionService: SubscriptionService
    
    var subscription: Subscription
    
    @State private var paymentDate = Date()
    @State private var amount: Double
    @State private var note = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    // Initialize with subscription cost as default amount
    init(subscription: Subscription) {
        self.subscription = subscription
        _amount = State(initialValue: subscription.cost)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Payment Details")) {
                    DatePicker("Payment Date", selection: $paymentDate, displayedComponents: .date)
                    
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0.00", value: $amount, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    TextField("Note (Optional)", text: $note)
                }
                
                Section {
                    Button(action: recordPayment) {
                        Text("Record Payment")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .disabled(amount <= 0)
                }
            }
            .navigationTitle("Record Payment")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
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
        }
    }
    
    private func recordPayment() {
        guard let id = subscription.id else {
            errorMessage = "Missing subscription ID"
            return
        }
        
        isLoading = true
        
        // Create payment record
        let paymentRecord = PaymentRecord(
            id: UUID().uuidString,
            date: paymentDate,
            amount: amount,
            note: note.isEmpty ? nil : note
        )
        
        // Update subscription with new payment
        var updatedSubscription = subscription
        updatedSubscription.lastPaymentDate = paymentDate
        
        // Add to payment history
        if var history = updatedSubscription.paymentHistory {
            history.append(paymentRecord)
            updatedSubscription.paymentHistory = history
        } else {
            updatedSubscription.paymentHistory = [paymentRecord]
        }
        
        // Calculate next billing date based on billing cycle
        let calendar = Calendar.current
        var nextBillingComponent: DateComponents
        
        switch subscription.billingCycle {
        case .monthly:
            nextBillingComponent = DateComponents(month: 1)
        case .quarterly:
            nextBillingComponent = DateComponents(month: 3)
        case .semiAnnual:
            nextBillingComponent = DateComponents(month: 6)
        case .annual:
            nextBillingComponent = DateComponents(year: 1)
        case .custom:
            // Keep existing date for custom
            nextBillingComponent = DateComponents()
        }
        
        // Only update the next billing date if it's not a custom cycle
        if subscription.billingCycle != .custom {
            updatedSubscription.nextBillingDate = calendar.date(byAdding: nextBillingComponent, to: paymentDate) ?? subscription.nextBillingDate
        }
        
        // Save to Firebase
        subscriptionService.updateSubscription(updatedSubscription) { result in
            isLoading = false
            
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}