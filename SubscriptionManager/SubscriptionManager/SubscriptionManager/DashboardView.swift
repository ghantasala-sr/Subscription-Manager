//
//  DashboardView.swift
//  SubscriptionManager
//
//  Created by Srinivasa Rithik Ghantasala on 4/24/25.
//


import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @EnvironmentObject private var preferencesService: UserPreferencesService
    
    @State private var showingAIExplanation = false
    @State private var aiExplanation = ""
    
    private var monthlyTotal: Double {
        subscriptionService.subscriptions.reduce(0) { total, subscription in
            total + (subscription.cost * subscription.billingCycle.monthlyFactor)
        }
    }
    
    private var yearlyTotal: Double {
        monthlyTotal * 12
    }
    
    private var monthlyBudget: Double {
        preferencesService.userPreferences?.monthlyBudget ?? 0
    }
    
    private var budgetPercentage: Double {
        guard monthlyBudget > 0 else { return 0 }
        return monthlyTotal / monthlyBudget
    }
    
    private var budgetStatusColor: Color {
        if budgetPercentage <= 0.8 {
            return .green
        } else if budgetPercentage <= 1.0 {
            return .yellow
        } else {
            return .red
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Budget summary card
                    CardView {
                        VStack(spacing: 15) {
                            Text("Monthly Subscription Budget")
                                .font(.headline)
                            
                            HStack(alignment: .bottom) {
                                Text("$\(monthlyTotal, specifier: "%.2f")")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundColor(budgetStatusColor)
                                
                                if monthlyBudget > 0 {
                                    Text("of $\(monthlyBudget, specifier: "%.2f")")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .padding(.bottom, 5)
                                }
                            }
                            
                            // Animated budget bar
                            AnimatedBudgetBar(percentage: budgetPercentage)
                                .padding(.vertical, 8)
                            
                            Text("Yearly Projection: $\(yearlyTotal, specifier: "%.2f")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Upcoming payments card
                    CardView {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Upcoming Payments")
                                .font(.headline)
                            
                            if subscriptionService.subscriptions.isEmpty {
                                HStack {
                                    Spacer()
                                    Text("No upcoming payments")
                                        .foregroundColor(.secondary)
                                        .padding(.vertical, 8)
                                    Spacer()
                                }
                            } else {
                                ForEach(upcomingSubscriptions) { subscription in
                                    NavigationLink(destination: SubscriptionDetailView(subscription: subscription)) {
                                        HStack {
                                            LogoImageView(logoName: subscription.logoName, size: 40)
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(subscription.name)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.primary)
                                                
                                                Text(formatDate(subscription.nextBillingDate))
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                
                                                if let member = subscription.familyMember {
                                                    Text(member.name)
                                                        .font(.caption)
                                                        .padding(.horizontal, 5)
                                                        .padding(.vertical, 2)
                                                        .background(Color.blue.opacity(0.1))
                                                        .foregroundColor(.blue)
                                                        .cornerRadius(4)
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            VStack(alignment: .trailing, spacing: 4) {
                                                Text("$\(subscription.cost, specifier: "%.2f")")
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.primary)
                                                
                                                Text(subscription.billingCycle.displayName)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    if subscription.id != upcomingSubscriptions.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                    
                    // Category breakdown
                    CardView {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Category Breakdown")
                                .font(.headline)
                            
                            if subscriptionService.subscriptions.isEmpty {
                                HStack {
                                    Spacer()
                                    Text("No subscription data")
                                        .foregroundColor(.secondary)
                                        .padding(.vertical, 8)
                                    Spacer()
                                }
                            } else {
                                HStack {
                                    ForEach(Category.allCases) { category in
                                        if categoryTotal(for: category) > 0 {
                                            VStack(spacing: 8) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color(category.color))
                                                        .frame(width: 50, height: 50)
                                                    
                                                    Image(systemName: category.icon)
                                                        .font(.system(size: 20))
                                                        .foregroundColor(.white)
                                                }
                                                
                                                Text(category.displayName)
                                                    .font(.caption)
                                                    .multilineTextAlignment(.center)
                                                    .lineLimit(1)
                                                    .frame(width: 60)
                                                
                                                Text("$\(categoryTotal(for: category), specifier: "%.2f")")
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                            }
                                            .frame(maxWidth: .infinity)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Monthly summary with CoreML
                    CardView {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("This Month's Summary")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button(action: {
                                    generateAIExplanation()
                                }) {
                                    HStack {
                                        Image(systemName: "brain")
                                        Text("ML Analysis")
                                    }
                                    .font(.caption)
                                    .padding(8)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                                }
                            }
                            
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("$\(monthlyTotal, specifier: "%.2f")")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    Text("Total Spend")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if let topCategory = topSpendingCategory {
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(topCategory.displayName)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        
                                        Text("Top Category")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .navigationTitle("Dashboard")
            }
            .overlay(
                Group {
                    if subscriptionService.isLoading {
                        LoadingView()
                    }
                }
            )
            .sheet(isPresented: $showingAIExplanation) {
                AIExplanationView(explanation: $aiExplanation)
            }
        }
    }
    
    private var upcomingSubscriptions: [Subscription] {
        let sortedSubscriptions = subscriptionService.subscriptions
            .filter { $0.status == .active }
            .sorted { $0.nextBillingDate < $1.nextBillingDate }
        
        return Array(sortedSubscriptions.prefix(3))
    }
    
    private var topSpendingCategory: Category? {
        let categoryTotals = Dictionary(grouping: subscriptionService.subscriptions) { $0.category }
            .mapValues { subscriptions in
                subscriptions.reduce(0) { $0 + ($1.cost * $1.billingCycle.monthlyFactor) }
            }
        
        return categoryTotals.max(by: { $0.value < $1.value })?.key
    }
    
    private func categoryTotal(for category: Category) -> Double {
        subscriptionService.subscriptions
            .filter { $0.category == category }
            .reduce(0) { $0 + ($1.cost * $1.billingCycle.monthlyFactor) }
    }
    
    private func generateAIExplanation() {
        // Show loading indicator
        showingAIExplanation = true
        
        // Create spending history for simulation
        let today = Date()
        let calendar = Calendar.current
        var spendingHistory: [Date: Double] = [:]
        
        // Create 6 months of history with slight variations for a realistic look
        let baseAmount = monthlyTotal
        for i in 1...6 {
            if let date = calendar.date(byAdding: .month, value: -i, to: today) {
                let variation = Double.random(in: 0.9...1.1)
                spendingHistory[date] = baseAmount * variation
            }
        }
        
        // Add current month
        spendingHistory[today] = monthlyTotal
        
        // User preferences (budget, etc.)
        let preferences = preferencesService.userPreferences ?? UserPreferences(
            id: nil,
            userId: "current_user",
            monthlyBudget: 100,
            yearlyBudget: 1200,
            enableNotifications: true,
            notificationTime: Date(),
            notifyDaysBefore: 3,
            currencyCode: "USD",
            themePreference: "system",
            createdAt: Date()
        )
        
        // Use CoreML to generate analysis
        let coreMLService = CoreMLService()
        coreMLService.generateMonthlySummary(
            subscriptions: subscriptionService.subscriptions,
            spendingHistory: spendingHistory,
            userPreferences: preferences
        ) { result in
            switch result {
            case .success(let summary):
                self.aiExplanation = summary
                
            case .failure(let error):
                print("Error generating AI explanation: \(error)")
                
                // Fallback to a simple explanation
                let currentTotal = self.monthlyTotal
                let previousMonthTotal = spendingHistory.values.sorted().dropLast().last ?? (currentTotal * 0.9)
                
                var summary = "This month, you're spending $\(String(format: "%.2f", currentTotal)) on subscriptions. "
                
                if currentTotal > previousMonthTotal {
                    let increase = currentTotal - previousMonthTotal
                    summary += "That's $\(String(format: "%.2f", increase)) more than last month. "
                } else if currentTotal < previousMonthTotal {
                    let decrease = previousMonthTotal - currentTotal
                    summary += "That's $\(String(format: "%.2f", decrease)) less than last month. "
                } else {
                    summary += "Your spending is the same as last month. "
                }
                
                if preferences.monthlyBudget > 0 {
                    let percentOfBudget = (currentTotal / preferences.monthlyBudget) * 100
                    
                    if percentOfBudget > 100 {
                        summary += "You're currently \(Int(percentOfBudget - 100))% over your monthly budget. Consider pausing or cancelling less-used subscriptions."
                    } else if percentOfBudget > 90 {
                        summary += "You're approaching your monthly budget at \(Int(percentOfBudget))% utilization. Monitor your spending closely."
                    } else {
                        summary += "You're within your monthly budget at \(Int(percentOfBudget))% utilization. Good job managing your subscriptions!"
                    }
                }
                
                self.aiExplanation = summary
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct AnimatedBudgetBar: View {
    let percentage: Double
    var height: CGFloat = 8
    
    private var budgetColor: Color {
        if percentage <= 0.8 {
            return .green
        } else if percentage <= 1.0 {
            return .yellow
        } else {
            return .red
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: height)
                    .opacity(0.3)
                    .foregroundColor(.gray)
                
                Rectangle()
                    .frame(width: min(CGFloat(percentage) * geometry.size.width, geometry.size.width), height: height)
                    .foregroundColor(budgetColor)
                    .animation(.spring(), value: percentage)
            }
            .cornerRadius(height / 2)
        }
        .frame(height: height)
    }
}
