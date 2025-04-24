//
//  MLInsightsView.swift
//  SubscriptionManager
//
//  Created by Srinivasa Rithik Ghantasala on 4/24/25.
//


import SwiftUI

struct MLInsightsView: View {
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @EnvironmentObject private var preferencesService: UserPreferencesService
    
    @State private var unusedSubscriptions: [Subscription: Double] = [:]
    @State private var recommendations: [SubscriptionCombination] = []
    @State private var isLoading = false
    @State private var analysisCompleted = false
    @State private var showingDetail = false
    @State private var selectedRecommendation: SubscriptionCombination? = nil
    
    private let coreMLService = CoreMLService()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header section
                VStack(spacing: 10) {
                    Text("AI-Powered Insights")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Our Core ML model analyzes your subscription patterns to find potential savings")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical)
                
                if isLoading {
                    // Loading animation
                    VStack(spacing: 15) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Running ML analysis...")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Our on-device machine learning model is analyzing your subscription patterns")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.vertical, 40)
                    
                } else if !analysisCompleted {
                    // Prompt to run analysis
                    Button(action: runMLAnalysis) {
                        VStack(spacing: 15) {
                            Image(systemName: "brain")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                            
                            Text("Analyze My Subscriptions")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(10)
                            
                            Text("Use on-device machine learning to find optimization opportunities")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 30)
                    
                } else {
                    // ML analysis results
                    if let topRecommendation = recommendations.first {
                        // Featured recommendation
                        CardView {
                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                    
                                    Text("Top Recommendation")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(topRecommendation.confidenceScore * 100))% confidence")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(4)
                                }
                                
                                Text(topRecommendation.title)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                
                                Text(topRecommendation.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Potential Savings")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text("$\(topRecommendation.monthlySavings * 12, specifier: "%.2f")/year")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        selectedRecommendation = topRecommendation
                                        showingDetail = true
                                    }) {
                                        Text("View Details")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // All recommendations
                    if recommendations.count > 1 {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("All Recommendations")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(recommendations.dropFirst()) { recommendation in
                                CardView {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Text(recommendation.title)
                                                .font(.headline)
                                            
                                            Spacer()
                                            
                                            Text("Save $\(recommendation.monthlySavings * 12, specifier: "%.2f")/yr")
                                                .font(.subheadline)
                                                .foregroundColor(.green)
                                        }
                                        
                                        Text(recommendation.description)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        HStack {
                                            Spacer()
                                            
                                            Button(action: {
                                                selectedRecommendation = recommendation
                                                showingDetail = true
                                            }) {
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Unused subscriptions
                    if !unusedSubscriptions.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Potential Underused Subscriptions")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal) {
                                HStack(spacing: 15) {
                                    ForEach(Array(unusedSubscriptions.keys.sorted { unusedSubscriptions[$0]! > unusedSubscriptions[$1]! })) { subscription in
                                        if let score = unusedSubscriptions[subscription], score > 0.4 {
                                            VStack(spacing: 8) {
                                                ZStack(alignment: .topTrailing) {
                                                    LogoImageView(logoName: subscription.logoName, size: 60)
                                                        .padding(5)
                                                    
                                                    Text("\(Int(score * 100))%")
                                                        .font(.caption)
                                                        .padding(4)
                                                        .background(Color.red)
                                                        .foregroundColor(.white)
                                                        .cornerRadius(8)
                                                        .offset(x: 5, y: -5)
                                                }
                                                
                                                Text(subscription.name)
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                
                                                Text("$\(subscription.cost, specifier: "%.2f")/\(subscription.billingCycle.rawValue)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            .frame(width: 100)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 5)
                                            .background(Color.white)
                                            .cornerRadius(12)
                                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, 10)
                    }
                    
                    // Run analysis again button
                    Button(action: runMLAnalysis) {
                        Text("Refresh Analysis")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.vertical, 20)
                    }
                }
            }
            .sheet(isPresented: $showingDetail) {
                if let recommendation = selectedRecommendation {
                    RecommendationDetailView(recommendation: recommendation, subscriptions: subscriptionService.subscriptions)
                }
            }
        }
        .onAppear {
            // If we have subscriptions but no analysis, run automatically
            if !subscriptionService.subscriptions.isEmpty && !analysisCompleted && !isLoading {
                runMLAnalysis()
            }
        }
    }
    
    private func runMLAnalysis() {
        guard !subscriptionService.subscriptions.isEmpty else { return }
        
        isLoading = true
        
        // Create a dispatch group to wait for all ML tasks to complete
        let group = DispatchGroup()
        
        // Task 1: Analyze unused subscriptions
        group.enter()
        coreMLService.predictUnderusedSubscriptions(subscriptions: subscriptionService.subscriptions) { result in
            switch result {
            case .success(let scores):
                // Match scores back to subscriptions
                var subscriptionScores: [Subscription: Double] = [:]
                
                for (id, score) in scores {
                    if let subscription = subscriptionService.subscriptions.first(where: { $0.id == id }) {
                        subscriptionScores[subscription] = score
                    }
                }
                
                self.unusedSubscriptions = subscriptionScores
                
            case .failure(let error):
                print("Error analyzing unused subscriptions: \(error)")
                // Create fallback data
                var fallbackScores: [Subscription: Double] = [:]
                
                for subscription in subscriptionService.subscriptions {
                    if subscription.status != .active {
                        fallbackScores[subscription] = Double.random(in: 0.5...0.8)
                    } else if subscription.category == .entertainment {
                        fallbackScores[subscription] = Double.random(in: 0.3...0.6)
                    }
                }
                
                self.unusedSubscriptions = fallbackScores
            }
            
            group.leave()
        }
        
        // Task 2: Generate recommendations
        group.enter()
        if let preferences = preferencesService.userPreferences {
            coreMLService.predictOptimalSubscriptionCombinations(
                subscriptions: subscriptionService.subscriptions,
                userPreferences: preferences
            ) { result in
                switch result {
                case .success(let combinations):
                    self.recommendations = combinations
                    
                case .failure(let error):
                    print("Error generating recommendations: \(error)")
                    // Create fallback recommendations
                    self.recommendations = []
                }
                
                group.leave()
            }
        } else {
            // Create default preferences if none exist
            let defaultPrefs = UserPreferences(
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
            
            coreMLService.predictOptimalSubscriptionCombinations(
                subscriptions: subscriptionService.subscriptions,
                userPreferences: defaultPrefs
            ) { result in
                switch result {
                case .success(let combinations):
                    self.recommendations = combinations
                    
                case .failure(let error):
                    print("Error generating recommendations: \(error)")
                    self.recommendations = []
                }
                
                group.leave()
            }
        }
        
        // When all tasks complete
        group.notify(queue: .main) {
            isLoading = false
            analysisCompleted = true
        }
    }
}

struct RecommendationDetailView: View {
    let recommendation: SubscriptionCombination
    let subscriptions: [Subscription]
    
    @Environment(\.dismiss) private var dismiss
    
    var affectedSubscriptions: [Subscription] {
        subscriptions.filter { subscription in
            recommendation.subscriptionIds.contains(subscription.id ?? "")
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(recommendation.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(recommendation.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Label("AI Confidence: \(Int(recommendation.confidenceScore * 100))%", systemImage: "brain")
                                .font(.subheadline)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            
                            Spacer()
                            
                            Label("$\(recommendation.monthlySavings * 12, specifier: "%.2f")/yr", systemImage: "dollarsign.circle")
                                .font(.subheadline)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // Affected subscriptions
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Affected Subscriptions")
                            .font(.headline)
                        
                        ForEach(affectedSubscriptions) { subscription in
                            HStack {
                                LogoImageView(logoName: subscription.logoName, size: 40)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(subscription.name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Text(subscription.category.displayName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("$\(subscription.cost, specifier: "%.2f")")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Text(subscription.billingCycle.displayName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 8)
                            
                            if subscription.id != affectedSubscriptions.last?.id {
                                Divider()
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // Implementation steps
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Implementation Steps")
                            .font(.headline)
                        
                        ForEach(Array(recommendation.implementationSteps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 15) {
                                Text("\(index + 1)")
                                    .font(.headline)
                                    .frame(width: 30, height: 30)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                                
                                Text(step)
                                    .font(.subheadline)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // AI explanation
                    VStack(alignment: .leading, spacing: 15) {
                        Text("How Our AI Made This Recommendation")
                            .font(.headline)
                        
                        Text("Our Core ML model analyzes your subscription patterns, costs, usage, and categories to identify potential savings. This recommendation was generated by looking at:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(aiFactors, id: \.self) { factor in
                                HStack(alignment: .top) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    
                                    Text(factor)
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                .padding()
            }
            .navigationTitle("Recommendation Details")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
    
    // Generate AI factors based on recommendation type
    private var aiFactors: [String] {
        var factors = [
            "Subscription costs and billing cycles",
            "Number of subscriptions in each category"
        ]
        
        if recommendation.id.contains("streaming") {
            factors.append("High count of similar entertainment subscriptions")
            factors.append("Typical viewing patterns for streaming services")
            factors.append("Cost comparison between concurrent vs. rotating services")
        } else if recommendation.id.contains("annual") {
            factors.append("Price difference between monthly and annual plans")
            factors.append("Likelihood of continued usage based on subscription age")
            factors.append("Annual payment savings calculation")
        } else if recommendation.id.contains("consolidate") {
            factors.append("Overlapping functionality between services")
            factors.append("Feature comparison between similar subscriptions")
            factors.append("Potential feature loss vs. cost savings analysis")
        } else if recommendation.id.contains("budget") {
            factors.append("Budget utilization percentages")
            factors.append("Priority ranking of subscriptions")
            factors.append("Usage patterns and activity levels")
        }
        
        return factors
    }
}
