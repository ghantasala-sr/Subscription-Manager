//
//  AddSubscriptionView.swift
//  SubscriptionManager
//
//  Created by Srinivasa Rithik Ghantasala on 4/24/25.
//


import SwiftUI

struct AddSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @EnvironmentObject private var preferencesService: UserPreferencesService
    @EnvironmentObject private var familyMemberService: FamilyMemberService
    
    @State private var name = ""
    @State private var category = Category.entertainment
    @State private var cost = 0.0
    @State private var billingCycle = BillingCycle.monthly
    @State private var nextBillingDate = Date()
    @State private var cardLastFourDigits = ""
    @State private var status = SubscriptionStatus.active
    @State private var notes = ""
    @State private var logoName = "subscription-default"
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    // New state variables
    @State private var selectedFamilyMember: FamilyMember? = nil
    @State private var showCategoryPicker = false
    @State private var selectedTemplate: SubscriptionTemplate? = nil
    
    private let notificationService = NotificationService()
    
    // Expanded list of popular services as templates
    private let subscriptionTemplates: [SubscriptionTemplate] = [
        // Streaming Services
        SubscriptionTemplate(name: "Netflix", logo: "netflix", category: .entertainment, defaultCost: 15.99),
        SubscriptionTemplate(name: "Disney+", logo: "disney", category: .entertainment, defaultCost: 7.99),
        SubscriptionTemplate(name: "Hulu", logo: "hulu", category: .entertainment, defaultCost: 7.99),
        SubscriptionTemplate(name: "Amazon Prime", logo: "amazon", category: .entertainment, defaultCost: 14.99),
        SubscriptionTemplate(name: "HBO Max", logo: "hbo", category: .entertainment, defaultCost: 14.99),
        SubscriptionTemplate(name: "YouTube Premium", logo: "youtube", category: .entertainment, defaultCost: 11.99),
        SubscriptionTemplate(name: "Apple TV+", logo: "apple", category: .entertainment, defaultCost: 6.99),
        SubscriptionTemplate(name: "Paramount+", logo: "paramount", category: .entertainment, defaultCost: 9.99),
        SubscriptionTemplate(name: "Peacock", logo: "peacock", category: .entertainment, defaultCost: 4.99),
        
        // Music Services
        SubscriptionTemplate(name: "Spotify", logo: "spotify", category: .entertainment, defaultCost: 9.99),
        SubscriptionTemplate(name: "Apple Music", logo: "apple", category: .entertainment, defaultCost: 9.99),
        SubscriptionTemplate(name: "YouTube Music", logo: "youtube", category: .entertainment, defaultCost: 9.99),
        SubscriptionTemplate(name: "Amazon Music", logo: "amazon", category: .entertainment, defaultCost: 8.99),
        SubscriptionTemplate(name: "Tidal", logo: "tidal", category: .entertainment, defaultCost: 9.99),
        
        // Software Services
        SubscriptionTemplate(name: "Adobe Creative Cloud", logo: "adobe", category: .software, defaultCost: 52.99),
        SubscriptionTemplate(name: "Microsoft 365", logo: "microsoft", category: .software, defaultCost: 6.99),
        SubscriptionTemplate(name: "iCloud+", logo: "apple", category: .software, defaultCost: 2.99),
        SubscriptionTemplate(name: "Google One", logo: "google", category: .software, defaultCost: 1.99),
        SubscriptionTemplate(name: "Dropbox", logo: "dropbox", category: .software, defaultCost: 11.99),
        SubscriptionTemplate(name: "LastPass", logo: "lastpass", category: .software, defaultCost: 3.00),
        
        // Health & Fitness
        SubscriptionTemplate(name: "Planet Fitness", logo: "fitness", category: .health, defaultCost: 10.00),
        SubscriptionTemplate(name: "LA Fitness", logo: "fitness", category: .health, defaultCost: 29.99),
        SubscriptionTemplate(name: "24 Hour Fitness", logo: "fitness", category: .health, defaultCost: 49.99),
        SubscriptionTemplate(name: "Peloton", logo: "fitness", category: .health, defaultCost: 12.99),
        SubscriptionTemplate(name: "ClassPass", logo: "fitness", category: .health, defaultCost: 49.00),
        SubscriptionTemplate(name: "Apple Fitness+", logo: "apple", category: .health, defaultCost: 9.99),
        
        // Gaming
        SubscriptionTemplate(name: "Xbox Game Pass", logo: "xbox", category: .entertainment, defaultCost: 14.99),
        SubscriptionTemplate(name: "PlayStation Plus", logo: "playstation", category: .entertainment, defaultCost: 9.99),
        SubscriptionTemplate(name: "Nintendo Switch Online", logo: "nintendo", category: .entertainment, defaultCost: 3.99),
        
        // Utilities
        SubscriptionTemplate(name: "Electric Bill", logo: "utility", category: .utilities, defaultCost: 100.00),
        SubscriptionTemplate(name: "Water Bill", logo: "utility", category: .utilities, defaultCost: 50.00),
        SubscriptionTemplate(name: "Gas Bill", logo: "utility", category: .utilities, defaultCost: 75.00),
        SubscriptionTemplate(name: "Internet", logo: "internet", category: .utilities, defaultCost: 59.99),
        SubscriptionTemplate(name: "Cell Phone", logo: "phone", category: .utilities, defaultCost: 79.99),
        
        // Education
        SubscriptionTemplate(name: "Skillshare", logo: "education", category: .education, defaultCost: 32.00),
        SubscriptionTemplate(name: "MasterClass", logo: "education", category: .education, defaultCost: 15.00),
        SubscriptionTemplate(name: "Coursera Plus", logo: "education", category: .education, defaultCost: 59.00),
        SubscriptionTemplate(name: "LinkedIn Learning", logo: "linkedin", category: .education, defaultCost: 29.99),
        SubscriptionTemplate(name: "Duolingo Plus", logo: "duolingo", category: .education, defaultCost: 6.99),
    ]
    
    var body: some View {
        NavigationView {
            Form {
                // Breaking down the form into sections
                categoriesSection
                
                if showCategoryPicker {
                    templatesSection
                }
                
                subscriptionDetailsSection
                familyMemberSection
                optionalDetailsSection
                addButtonSection
            }
            .navigationTitle("Add Subscription")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .overlay(loadingOverlay)
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
    
    // MARK: - Section Components
    
    private var categoriesSection: some View {
        Section(header: Text("Categories")) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(Category.allCases) { categoryOption in
                        Button(action: {
                            category = categoryOption
                            showCategoryPicker.toggle()
                        }) {
                            VStack {
                                ZStack {
                                    Circle()
                                        .fill(Color(categoryOption.color))
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: categoryOption.icon)
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                }
                                .overlay(
                                    Circle()
                                        .stroke(category == categoryOption ? Color.blue : Color.clear, lineWidth: 3)
                                )
                                
                                Text(categoryOption.displayName)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 70)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.vertical, 10)
            }
        }
    }
    
    private var templatesSection: some View {
        Section(header: Text("Popular \(category.displayName) Services")) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    let filteredTemplates = subscriptionTemplates.filter { $0.category == category }
                    
                    ForEach(filteredTemplates) { template in
                        Button(action: {
                            selectTemplate(template)
                        }) {
                            VStack {
                                LogoImageView(logoName: template.logo, size: 60)
                                    .padding(5)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedTemplate?.name == template.name ? Color.blue : Color.clear, lineWidth: 3)
                                    )
                                
                                Text(template.name)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 70)
                                
                                Text("$\(template.defaultCost, specifier: "%.2f")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.vertical, 10)
            }
        }
    }
    
    private var subscriptionDetailsSection: some View {
        Section(header: Text("Subscription Details")) {
            TextField("Name", text: $name)
            
            Picker("Category", selection: $category) {
                ForEach(Category.allCases) {
                    Text($0.displayName).tag($0)
                }
            }
            
            HStack {
                Text("Cost")
                Spacer()
                TextField("0.00", value: $cost, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
            
            Picker("Billing Cycle", selection: $billingCycle) {
                ForEach(BillingCycle.allCases) {
                    Text($0.displayName).tag($0)
                }
            }
            
            DatePicker("Next Billing Date", selection: $nextBillingDate, displayedComponents: .date)
            
            Picker("Status", selection: $status) {
                ForEach(SubscriptionStatus.allCases) { statusOption in
                    HStack {
                        Image(systemName: statusOption.icon)
                            .foregroundColor(Color(statusOption.color))
                        Text(statusOption.displayName).tag(statusOption)
                    }
                }
            }
        }
    }
    
    private var familyMemberSection: some View {
        Section(header: Text("Family Member (Optional)")) {
            if familyMemberService.familyMembers.isEmpty {
                NavigationLink(destination: FamilyMembersListView()) {
                    Text("Add a Family Member")
                        .foregroundColor(.blue)
                }
            } else {
                Picker("For Family Member", selection: $selectedFamilyMember) {
                    Text("None (For Me)").tag(nil as FamilyMember?)
                    
                    ForEach(familyMemberService.familyMembers) { member in
                        Text("\(member.name) (\(member.relationship))").tag(member as FamilyMember?)
                    }
                }
            }
        }
    }
    
    private var optionalDetailsSection: some View {
        Section(header: Text("Optional Details")) {
            TextField("Card last 4 digits", text: $cardLastFourDigits)
                .keyboardType(.numberPad)
                .onChange(of: cardLastFourDigits) { newValue in
                    // Limit to 4 digits
                    if newValue.count > 4 {
                        cardLastFourDigits = String(newValue.prefix(4))
                    }
                }
            
            TextField("Notes", text: $notes, axis: .vertical)
                .lineLimit(3...5)
        }
    }
    
    private var addButtonSection: some View {
        Section {
            Button("Add Subscription") {
                addSubscription()
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .disabled(name.isEmpty || cost <= 0)
        }
    }
    
    private var loadingOverlay: some View {
        Group {
            if isLoading {
                LoadingView()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func selectTemplate(_ template: SubscriptionTemplate) {
        selectedTemplate = template
        name = template.name
        category = template.category
        cost = template.defaultCost
        logoName = template.logo
    }
    
    private func addSubscription() {
        guard let userId = authService.currentUser?.id else {
            errorMessage = "User not found"
            return
        }
        
        isLoading = true
        
        // Determine logo name based on selection or common services
        var actualLogoName = logoName
        if actualLogoName == "subscription-default" {
            actualLogoName = determineLogoName(for: name)
        }
        
        // Schedule notification if enabled
        var notificationKey: String? = nil
        if status == .active {
            if let preferences = preferencesService.userPreferences, preferences.enableNotifications {
                notificationKey = notificationService.scheduleNotification(
                    for: Subscription(
                        userId: userId,
                        name: name,
                        category: category,
                        cost: cost,
                        billingCycle: billingCycle,
                        nextBillingDate: nextBillingDate,
                        cardLastFourDigits: cardLastFourDigits.isEmpty ? nil : cardLastFourDigits,
                        status: status,
                        logoName: actualLogoName,
                        dateAdded: Date()
                    ),
                    daysBefore: preferences.notifyDaysBefore
                )
            }
        }
        
        let subscription = Subscription(
            userId: userId,
            name: name,
            category: category,
            cost: cost,
            billingCycle: billingCycle,
            nextBillingDate: nextBillingDate,
            cardLastFourDigits: cardLastFourDigits.isEmpty ? nil : cardLastFourDigits,
            status: status,
            logoName: actualLogoName,
            notificationKey: notificationKey,
            notes: notes.isEmpty ? nil : notes,
            dateAdded: Date(),
            familyMember: selectedFamilyMember
        )
        
        subscriptionService.addSubscription(subscription) { result in
            isLoading = false
            
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func determineLogoName(for name: String) -> String {
        let lowercasedName = name.lowercased()
        
        // Check against predefined templates
        for template in subscriptionTemplates {
            if lowercasedName.contains(template.name.lowercased()) {
                return template.logo
            }
        }
        
        // Default logo
        return "subscription-default"
    }
}
