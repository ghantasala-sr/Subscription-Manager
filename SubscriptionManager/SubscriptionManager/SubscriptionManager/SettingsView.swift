//
//  SettingsView.swift
//  SubscriptionManager
//
//  Created by Srinivasa Rithik Ghantasala on 4/24/25.
//


import SwiftUI
import UserNotifications

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    // This method allows notifications to be shown even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Always show alerts and play sounds for foreground notifications
        completionHandler([.alert, .sound, .banner])
    }
}

struct SettingsView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var preferencesService: UserPreferencesService
    
    @State private var monthlyBudget: String = ""
    @State private var yearlyBudget: String = ""
    @State private var enableNotifications = true
    @State private var notificationTime = Date()
    @State private var notifyDaysBefore = 3
    @State private var currencyCode = "USD"
    @State private var themePreference = "system"
    
    @State private var showingConfirmLogout = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showingNotificationAlert = false
    @State private var notificationStatus = "Unknown"
    
    private let notificationService = NotificationService()
    private let notificationDelegate = NotificationDelegate()
    
    private let currencies = [
        ("USD", "US Dollar"),
        ("EUR", "Euro"),
        ("GBP", "British Pound"),
        ("JPY", "Japanese Yen"),
        ("CAD", "Canadian Dollar"),
        ("AUD", "Australian Dollar"),
        ("CNY", "Chinese Yuan")
    ]
    
    private let themeOptions = [
        ("system", "System Default"),
        ("light", "Light Mode"),
        ("dark", "Dark Mode")
    ]
    
    var body: some View {
        NavigationView {
            Form {
                // Budget settings
                Section(header: Text("Budget Settings")) {
                    HStack {
                        Text("Monthly Budget")
                        Spacer()
                        TextField("0.00", text: $monthlyBudget)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: monthlyBudget) { newValue in
                                if let monthly = Double(newValue) {
                                    yearlyBudget = String(format: "%.2f", monthly * 12)
                                }
                            }
                    }
                    
                    HStack {
                        Text("Yearly Budget")
                        Spacer()
                        TextField("0.00", text: $yearlyBudget)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: yearlyBudget) { newValue in
                                if let yearly = Double(newValue) {
                                    monthlyBudget = String(format: "%.2f", yearly / 12)
                                }
                            }
                    }
                }
                
                // Notification settings
                Section(header: Text("Notifications")) {
                    Toggle("Enable Notifications", isOn: $enableNotifications)
                    
                    if enableNotifications {
                        DatePicker("Notification Time", selection: $notificationTime, displayedComponents: .hourAndMinute)
                        
                        Stepper("Notify \(notifyDaysBefore) days before", value: $notifyDaysBefore, in: 1...10)
                        
                        // Test Notification Button
                        Button(action: sendTestNotification) {
                            HStack {
                                Image(systemName: "bell.badge.fill")
                                    .foregroundColor(.blue)
                                Text("Send Test Notification")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                // Family Members section
                Section(header: Text("Family Members")) {
                    NavigationLink(destination: FamilyMembersListView()) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.blue)
                            Text("Manage Family Members")
                        }
                    }
                }
                
                // Appearance settings
                Section(header: Text("Appearance")) {
                    Picker("Currency", selection: $currencyCode) {
                        ForEach(currencies, id: \.0) { code, name in
                            Text("\(code) - \(name)").tag(code)
                        }
                    }
                    
                    Picker("Theme", selection: $themePreference) {
                        ForEach(themeOptions, id: \.0) { value, name in
                            Text(name).tag(value)
                        }
                    }
                }
                
                // Account settings
                Section(header: Text("Account")) {
                    if let user = authService.currentUser {
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(user.email)
                                .foregroundColor(.secondary)
                        }
                        
                        NavigationLink(destination: Text("Change Password View")) {
                            Text("Change Password")
                        }
                    }
                    
                    Button(action: {
                        showingConfirmLogout = true
                    }) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }
                }
                
                // About
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        // Open privacy policy
                    }) {
                        Text("Privacy Policy")
                    }
                    
                    Button(action: {
                        // Open terms of service
                    }) {
                        Text("Terms of Service")
                    }
                }
                
                // CoreML section
                Section(header: Text("AI Features")) {
                    HStack {
                        Text("On-Device ML")
                        Spacer()
                        Text("Enabled")
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink(destination: Text("The app uses on-device machine learning to provide subscription insights and recommendations without sending your data to external servers.").padding()) {
                        Text("About CoreML Features")
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear(perform: loadUserPreferences)
            .onReceive(preferencesService.$userPreferences) { _ in
                loadUserPreferences()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                    }
                    .disabled(!hasChanges)
                }
            }
            .overlay(
                Group {
                    if isLoading {
                        LoadingView()
                    }
                }
            )
            .alert("Sign Out", isPresented: $showingConfirmLogout) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authService.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .alert("Test Notification", isPresented: $showingNotificationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("A test notification has been scheduled and will appear in a few seconds.")
            }
        }
    }
    
    private func sendTestNotification() {
        // Request notification permission if needed
        notificationService.requestAuthorization { granted in
            if granted {
                // Create and schedule a test notification
                let center = UNUserNotificationCenter.current()
                
                let content = UNMutableNotificationContent()
                content.title = "Test Notification"
                content.body = "Your notifications are working correctly! 👍"
                content.sound = .default
                
                // Trigger after 3 seconds for immediate feedback
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 6, repeats: false)
                
                // Create the request
                let uuidString = UUID().uuidString
                let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
                
                // Schedule the notification
                center.add(request) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self.errorMessage = "Could not schedule notification: \(error.localizedDescription)"
                            self.showingErrorAlert = true
                        } else {
                            self.showingNotificationAlert = true
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Notification permission denied. Please enable notifications in Settings."
                    self.showingErrorAlert = true
                }
            }
        }
    }
    
    private var hasChanges: Bool {
        guard let preferences = preferencesService.userPreferences else { return false }
        
        let currentMonthlyBudget = preferences.monthlyBudget
        let currentYearlyBudget = preferences.yearlyBudget
        let newMonthlyBudget = Double(monthlyBudget) ?? 0
        let newYearlyBudget = Double(yearlyBudget) ?? 0
        
        return currentMonthlyBudget != newMonthlyBudget ||
               currentYearlyBudget != newYearlyBudget ||
               preferences.enableNotifications != enableNotifications ||
               preferences.notificationTime != notificationTime ||
               preferences.notifyDaysBefore != notifyDaysBefore ||
               preferences.currencyCode != currencyCode ||
               preferences.themePreference != themePreference
    }
    
    private func loadUserPreferences() {
        guard let preferences = preferencesService.userPreferences else { return }
        
        monthlyBudget = String(format: "%.2f", preferences.monthlyBudget)
        yearlyBudget = String(format: "%.2f", preferences.yearlyBudget)
        enableNotifications = preferences.enableNotifications
        notificationTime = preferences.notificationTime
        notifyDaysBefore = preferences.notifyDaysBefore
        currencyCode = preferences.currencyCode
        themePreference = preferences.themePreference
    }
    
    private func saveSettings() {
        guard var preferences = preferencesService.userPreferences else { return }
        
        isLoading = true
        
        // Update preferences
        preferences.monthlyBudget = Double(monthlyBudget) ?? 0
        preferences.yearlyBudget = Double(yearlyBudget) ?? 0
        preferences.enableNotifications = enableNotifications
        preferences.notificationTime = notificationTime
        preferences.notifyDaysBefore = notifyDaysBefore
        preferences.currencyCode = currencyCode
        preferences.themePreference = themePreference
        
        // Save to Firestore
        preferencesService.updatePreferences(preferences) { result in
            isLoading = false
            
            switch result {
            case .success:
                // If notification settings changed, request permission if needed
                if enableNotifications {
                    notificationService.requestAuthorization { _ in
                        // No action needed, will be handled when adding/updating subscriptions
                    }
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
                showingErrorAlert = true
            }
        }
    }
}
