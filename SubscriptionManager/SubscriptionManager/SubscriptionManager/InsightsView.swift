//
//  InsightsView.swift
//  SubscriptionManager
//
//  Created by Srinivasa Rithik Ghantasala on 4/24/25.
//


import SwiftUI
import Charts

struct InsightsView: View {
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @EnvironmentObject private var preferencesService: UserPreferencesService
    
    @State private var selectedTab = 0
    @State private var monthlySpendingData: [MonthData] = []
    @State private var showingAIExplanation = false
    @State private var aiExplanation = ""
    
    struct MonthData: Identifiable {
        let id = UUID()
        let month: String
        let amount: Double
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom tab selector
                HStack(spacing: 0) {
                    TabButton(title: "Overview", isSelected: selectedTab == 0) {
                        withAnimation {
                            selectedTab = 0
                        }
                    }
                    
                    TabButton(title: "Categories", isSelected: selectedTab == 1) {
                        withAnimation {
                            selectedTab = 1
                        }
                    }
                    
                    TabButton(title: "ML Insights", isSelected: selectedTab == 2) {
                        withAnimation {
                            selectedTab = 2
                        }
                    }
                    
                }
                .padding(.top, 10)
                
                // Tab content
                TabView(selection: $selectedTab) {
                    // Overview tab
                    ScrollView {
                        VStack(spacing: 20) {
                            // Monthly spending chart
                            CardView {
                                VStack(alignment: .leading, spacing: 15) {
                                    Text("Monthly Spending Trend")
                                        .font(.headline)
                                    
                                    if monthlySpendingData.isEmpty {
                                        Text("Not enough data to display trends")
                                            .foregroundColor(.secondary)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .padding(.vertical, 40)
                                    } else {
                                        Chart {
                                            ForEach(monthlySpendingData) { item in
                                                LineMark(
                                                    x: .value("Month", item.month),
                                                    y: .value("Amount", item.amount)
                                                )
                                                .foregroundStyle(Color.blue)
                                                .symbol(Circle().strokeBorder(lineWidth: 2))
                                                
                                                AreaMark(
                                                    x: .value("Month", item.month),
                                                    y: .value("Amount", item.amount)
                                                )
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        colors: [.blue.opacity(0.3), .blue.opacity(0.1)],
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    )
                                                )
                                            }
                                            
                                            if let budget = preferencesService.userPreferences?.monthlyBudget, budget > 0 {
                                                RuleMark(y: .value("Budget", budget))
                                                    .foregroundStyle(.red)
                                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                                                    .annotation(position: .top, alignment: .trailing) {
                                                        Text("Budget: $\(budget, specifier: "%.2f")")
                                                            .font(.caption)
                                                            .foregroundColor(.red)
                                                    }
                                            }
                                        }
                                        .frame(height: 250)
                                        .padding(.top, 10)
                                    }
                                    
                                    Button(action: {
                                        generateAIExplanation()
                                        showingAIExplanation = true
                                    }) {
                                        HStack {
                                            Image(systemName: "brain")
                                            Text("Analyze Spending")
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                        }
                                        .font(.subheadline)
                                        .padding(10)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(8)
                                    }
                                }
                            }
                            
                            // Spending breakdown
                            CardView {
                                VStack(alignment: .leading, spacing: 15) {
                                    Text("Spending Breakdown")
                                        .font(.headline)
                                    
                                    if subscriptionService.subscriptions.isEmpty {
                                        Text("No subscriptions added yet")
                                            .foregroundColor(.secondary)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .padding(.vertical, 20)
                                    } else {
                                        HStack(alignment: .top) {
                                            VStack(alignment: .leading, spacing: 20) {
                                                spendingMetricView(
                                                    title: "Monthly",
                                                    amount: totalMonthlySpend,
                                                    caption: "vs Budget: \(monthlyBudgetPercentage)%"
                                                )
                                                
                                                spendingMetricView(
                                                    title: "Annual",
                                                    amount: totalMonthlySpend * 12,
                                                    caption: "Projected"
                                                )
                                            }
                                            
                                            Spacer()
                                            
                                            VStack(alignment: .trailing, spacing: 20) {
                                                spendingMetricView(
                                                    title: "Avg per Sub",
                                                    amount: averageSubscriptionCost,
                                                    caption: "\(subscriptionService.subscriptions.count) Active",
                                                    alignment: .trailing
                                                )
                                                
                                                if let topCategory = topSpendingCategory {
                                                    spendingMetricView(
                                                        title: "Top Category",
                                                        amount: categoryTotal(for: topCategory),
                                                        caption: topCategory.displayName,
                                                        alignment: .trailing
                                                    )
                                                }
                                            }
                                        }
                                        .padding(.vertical, 10)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                    .tag(0)
                    
                    // Categories tab
                    ScrollView {
                        VStack(spacing: 20) {
                            // Pie chart
                            CardView {
                                VStack(alignment: .leading, spacing: 15) {
                                    Text("Category Distribution")
                                        .font(.headline)
                                    
                                    if subscriptionService.subscriptions.isEmpty {
                                        Text("No subscriptions added yet")
                                            .foregroundColor(.secondary)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .padding(.vertical, 40)
                                    } else {
                                        CategoryPieChartView(
                                            subscriptions: subscriptionService.subscriptions
                                        )
                                        .frame(height: 250)
                                    }
                                }
                            }
                            
                            // Category breakdown
                            CardView {
                                VStack(alignment: .leading, spacing: 15) {
                                    Text("Spending by Category")
                                        .font(.headline)
                                    
                                    if subscriptionService.subscriptions.isEmpty {
                                        Text("No subscriptions added yet")
                                            .foregroundColor(.secondary)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .padding(.vertical, 20)
                                    } else {
                                        ForEach(Category.allCases) { category in
                                            if categoryTotal(for: category) > 0 {
                                                VStack(spacing: 5) {
                                                    HStack {
                                                        Circle()
                                                            .fill(Color(category.color))
                                                            .frame(width: 12, height: 12)
                                                        
                                                        Text(category.displayName)
                                                            .font(.subheadline)
                                                        
                                                        Spacer()
                                                        
                                                        Text("$\(categoryTotal(for: category), specifier: "%.2f")/mo")
                                                            .font(.subheadline)
                                                            .fontWeight(.semibold)
                                                    }
                                                    
                                                    // Progress bar
                                                    GeometryReader { geometry in
                                                        ZStack(alignment: .leading) {
                                                            Rectangle()
                                                                .fill(Color.gray.opacity(0.2))
                                                                .frame(height: 8)
                                                                .cornerRadius(4)
                                                            
                                                            Rectangle()
                                                                .fill(Color(category.color))
                                                                .frame(width: categoryPercentage(for: category) * geometry.size.width, height: 8)
                                                                .cornerRadius(4)
                                                        }
                                                    }
                                                    .frame(height: 8)
                                                    
                                                    Text("\(Int(categoryPercentage(for: category) * 100))% of total")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                                }
                                                .padding(.vertical, 5)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                    .tag(1)
                    
                    // ML Insights tab (new)
                    MLInsightsView()
                        .tag(2)
                    
                    // Optimize tab
                    ScrollView {
                        VStack(spacing: 20) {
                            // Your optimize tab content here
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                    .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: selectedTab)
            }
            .navigationTitle("Insights")
            .onAppear {
                generateMockMonthlyData()
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
    
    private var totalMonthlySpend: Double {
        subscriptionService.subscriptions
            .filter { $0.status == .active }
            .reduce(0) { $0 + ($1.cost * $1.billingCycle.monthlyFactor) }
    }
    
    private var monthlyBudgetPercentage: Int {
        guard let budget = preferencesService.userPreferences?.monthlyBudget, budget > 0 else {
            return 0
        }
        
        return Int((totalMonthlySpend / budget) * 100)
    }
    
    private var averageSubscriptionCost: Double {
        let activeSubscriptions = subscriptionService.subscriptions.filter { $0.status == .active }
        guard !activeSubscriptions.isEmpty else { return 0 }
        
        return totalMonthlySpend / Double(activeSubscriptions.count)
    }
    
    private var topSpendingCategory: Category? {
        let categoryTotals = Dictionary(grouping: subscriptionService.subscriptions.filter { $0.status == .active }) { $0.category }
            .mapValues { subscriptions in
                subscriptions.reduce(0) { $0 + ($1.cost * $1.billingCycle.monthlyFactor) }
            }
        
        return categoryTotals.max(by: { $0.value < $1.value })?.key
    }
    
    private func categoryTotal(for category: Category) -> Double {
        subscriptionService.subscriptions
            .filter { $0.category == category && $0.status == .active }
            .reduce(0) { $0 + ($1.cost * $1.billingCycle.monthlyFactor) }
    }
    
    private func categoryPercentage(for category: Category) -> Double {
        guard totalMonthlySpend > 0 else { return 0 }
        
        return categoryTotal(for: category) / totalMonthlySpend
    }
    
    private func spendingMetricView(title: String, amount: Double, caption: String, alignment: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("$\(amount, specifier: "%.2f")")
                .font(.title3)
                .fontWeight(.bold)
            
            Text(caption)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func generateMockMonthlyData() {
        let months = ["Nov", "Dec", "Jan", "Feb", "Mar", "Apr"]
        
        // Create realistic variation
        let baseAmount = totalMonthlySpend
        var previousAmount = baseAmount * 0.8 // Start at 80% of current
        
        monthlySpendingData = months.map { month in
            // Create realistic variation
            let variation = Double.random(in: -0.1...0.15)
            let amount = max(0, previousAmount * (1.0 + variation))
            previousAmount = amount
            
            return MonthData(month: month, amount: amount)
        }
    }
    
    private func generateAIExplanation() {
        // Create spending history for simulation
        let today = Date()
        let calendar = Calendar.current
        var spendingHistory: [Date: Double] = [:]
        
        // Create 6 months of history with slight variations for a realistic look
        let baseAmount = totalMonthlySpend
        for i in 1...6 {
            if let date = calendar.date(byAdding: .month, value: -i, to: today) {
                let variation = Double.random(in: 0.9...1.1)
                spendingHistory[date] = baseAmount * variation
            }
        }
        
        // Add current month
        spendingHistory[today] = totalMonthlySpend
        
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
                self.showingAIExplanation = true
            case .failure(let error):
                print("Error generating AI explanation: \(error)")
                // Use fallback explanation
                self.aiExplanation = "Failed to generate AI explanation"
                self.showingAIExplanation = true
            }
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .blue : .secondary)
                
                Rectangle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(PlainButtonStyle())
    }
}
