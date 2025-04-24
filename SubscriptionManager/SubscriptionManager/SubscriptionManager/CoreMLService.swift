//
//  CoreMLService.swift
//  SubscriptionManager
//
//  Created by Srinivasa Rithik Ghantasala on 4/24/25.
//


import Foundation
import CoreML
import Vision

class CoreMLService {
    // MARK: - Properties
    private var subscriptionAnalyzerModel: MLModel?
    private var isModelLoaded = false
    
    // MARK: - Initialization
    init() {
        loadModels()
    }
    
    // MARK: - Model Loading
    private func loadModels() {
        do {
            // In a real app, you would load the actual Core ML model file
            // Since we don't have the physical model file, we'll simulate the model loading
            isModelLoaded = true
            print("Successfully simulated Core ML model loading")
            
            // When you have an actual .mlmodel file, you'd load it like this:
            // let config = MLModelConfiguration()
            // config.computeUnits = .all
            // self.subscriptionAnalyzerModel = try SubscriptionAnalyzer(configuration: config)
        } catch {
            print("Failed to load Core ML model: \(error)")
        }
    }
    
    // MARK: - Prediction Methods
    
    // Predict which subscriptions might be unused or underused
    func predictUnderusedSubscriptions(subscriptions: [Subscription], completion: @escaping (Result<[String: Double], Error>) -> Void) {
        guard isModelLoaded else {
            completion(.failure(MLError.modelNotLoaded))
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Simulate ML analysis process
            var cancellationScores: [String: Double] = [:]
            
            for subscription in subscriptions {
                // Calculate a "cancellation score" based on various factors
                var score = 0.0
                
                // Inactive subscriptions are likely not being used
                if subscription.status != .active {
                    score += 0.4
                }
                
                // Higher cost items have higher potential for review
                if subscription.cost > 30 {
                    score += 0.2
                } else if subscription.cost > 15 {
                    score += 0.1
                }
                
                // Entertainment subscriptions often have usage patterns
                if subscription.category == .entertainment {
                    score += 0.15
                }
                
                // Calculate days since last payment
                if let lastPayment = subscription.lastPaymentDate {
                    let daysSincePayment = Calendar.current.dateComponents([.day], from: lastPayment, to: Date()).day ?? 0
                    if daysSincePayment > 60 {
                        score += 0.25
                    } else if daysSincePayment > 30 {
                        score += 0.15
                    }
                } else {
                    // No payment record increases the score
                    score += 0.2
                }
                
                // Add some randomness to simulate ML variance
                score += Double.random(in: -0.1...0.1)
                
                // Cap the score between 0 and 1
                score = min(max(score, 0.0), 0.95)
                
                // Store the score
                if let id = subscription.id {
                    cancellationScores[id] = score
                }
            }
            
            // Delay a bit to simulate processing time
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                completion(.success(cancellationScores))
            }
        }
    }
    
    // Predict optimal subscription combinations for cost savings
    func predictOptimalSubscriptionCombinations(
        subscriptions: [Subscription],
        userPreferences: UserPreferences,
        completion: @escaping (Result<[SubscriptionCombination], Error>) -> Void
    ) {
        guard isModelLoaded else {
            completion(.failure(MLError.modelNotLoaded))
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            var combinations: [SubscriptionCombination] = []
            
            // 1. Identify streaming service rotation opportunities
            let streamingServices = subscriptions.filter { subscription in
                subscription.category == .entertainment &&
                ["netflix", "hulu", "disney", "hbo", "amazon", "youtube"].contains { serviceName in
                    subscription.name.lowercased().contains(serviceName) ||
                    subscription.logoName.lowercased().contains(serviceName)
                }
            }
            
            if streamingServices.count > 2 {
                let potentialSavings = streamingServices.sorted { $0.cost < $1.cost }
                    .prefix(streamingServices.count - 2)
                    .reduce(0) { $0 + $1.monthlyCost }
                
                if potentialSavings > 0 {
                    combinations.append(SubscriptionCombination(
                        id: "streaming_rotation",
                        title: "Streaming Service Rotation",
                        description: "Keep only 1-2 streaming services active at once and rotate monthly based on what you want to watch.",
                        subscriptionIds: streamingServices.compactMap { $0.id },
                        monthlySavings: potentialSavings,
                        confidenceScore: 0.85 + Double.random(in: -0.05...0.05),
                        implementationSteps: [
                            "Identify which services you use most frequently",
                            "Keep those services active year-round",
                            "Subscribe to other services only when they have content you want to watch",
                            "Cancel after watching the desired content"
                        ]
                    ))
                }
            }
            
            // 2. Identify monthly to annual conversion opportunities
            let monthlySubscriptions = subscriptions.filter { 
                $0.billingCycle == .monthly && $0.cost >= 10 && $0.status == .active
            }
            
            if !monthlySubscriptions.isEmpty {
                // Typically, annual plans save about 15-20%
                let annualSavings = monthlySubscriptions.reduce(0) { $0 + ($1.cost * 0.15) }
                
                if annualSavings > 0 {
                    combinations.append(SubscriptionCombination(
                        id: "annual_conversion",
                        title: "Switch to Annual Billing",
                        description: "Save by converting these monthly subscriptions to annual plans.",
                        subscriptionIds: monthlySubscriptions.compactMap { $0.id },
                        monthlySavings: annualSavings,
                        confidenceScore: 0.90 + Double.random(in: -0.05...0.05),
                        implementationSteps: [
                            "Identify subscriptions you've had for more than 3 months",
                            "Check if annual plans are available",
                            "Calculate the potential savings",
                            "Switch billing cycle to annual for consistent services"
                        ]
                    ))
                }
            }
            
            // 3. Identify duplicate/overlapping services
            let streamingMusic = subscriptions.filter { subscription in
                subscription.category == .entertainment &&
                ["spotify", "apple music", "youtube music", "tidal", "amazon music"].contains { serviceName in
                    subscription.name.lowercased().contains(serviceName)
                }
            }
            
            if streamingMusic.count > 1 {
                let mostExpensive = streamingMusic.max { $0.cost < $1.cost }
                let potentialSavings = streamingMusic.filter { $0.id != mostExpensive?.id }
                    .reduce(0) { $0 + $1.monthlyCost }
                
                if potentialSavings > 0 {
                    combinations.append(SubscriptionCombination(
                        id: "consolidate_music",
                        title: "Consolidate Music Services",
                        description: "You have multiple music streaming services. Consider keeping only one.",
                        subscriptionIds: streamingMusic.compactMap { $0.id },
                        monthlySavings: potentialSavings,
                        confidenceScore: 0.80 + Double.random(in: -0.05...0.05),
                        implementationSteps: [
                            "Identify which music service you prefer",
                            "Check if you can transfer playlists",
                            "Cancel redundant subscriptions"
                        ]
                    ))
                }
            }
            
            // 4. Check for cloud storage consolidation
            let cloudStorage = subscriptions.filter { subscription in
                subscription.category == .software &&
                ["dropbox", "icloud", "google drive", "onedrive"].contains { serviceName in
                    subscription.name.lowercased().contains(serviceName)
                }
            }
            
            if cloudStorage.count > 1 {
                let mostExpensive = cloudStorage.max { $0.cost < $1.cost }
                let potentialSavings = cloudStorage.filter { $0.id != mostExpensive?.id }
                    .reduce(0) { $0 + $1.monthlyCost }
                
                if potentialSavings > 0 {
                    combinations.append(SubscriptionCombination(
                        id: "consolidate_storage",
                        title: "Consolidate Cloud Storage",
                        description: "You have multiple cloud storage services. Consider consolidating to save money.",
                        subscriptionIds: cloudStorage.compactMap { $0.id },
                        monthlySavings: potentialSavings,
                        confidenceScore: 0.75 + Double.random(in: -0.05...0.05),
                        implementationSteps: [
                            "Choose your preferred storage service",
                            "Transfer files from other services",
                            "Cancel redundant subscriptions"
                        ]
                    ))
                }
            }
            
            // 5. Budget-specific recommendations
            if userPreferences.monthlyBudget > 0 {
                let currentTotal = subscriptions.reduce(0) { $0 + $1.monthlyCost }
                
                if currentTotal > userPreferences.monthlyBudget * 1.1 {
                    // Find lowest-value subscriptions to suggest cancelling
                    let overBudgetAmount = currentTotal - userPreferences.monthlyBudget
                    let inactiveOrLowUsage = subscriptions.filter { $0.status != .active }
                        .sorted { $0.cost > $1.cost }
                    
                    if !inactiveOrLowUsage.isEmpty && inactiveOrLowUsage.reduce(0) { $0 + $1.monthlyCost } >= overBudgetAmount {
                        combinations.append(SubscriptionCombination(
                            id: "budget_adjustment",
                            title: "Budget Reduction Plan",
                            description: "You're currently over budget. Consider cancelling these subscriptions to get back on track.",
                            subscriptionIds: inactiveOrLowUsage.compactMap { $0.id },
                            monthlySavings: inactiveOrLowUsage.reduce(0) { $0 + $1.monthlyCost },
                            confidenceScore: 0.70 + Double.random(in: -0.05...0.05),
                            implementationSteps: [
                                "Cancel paused or inactive subscriptions first",
                                "Evaluate low-usage subscriptions",
                                "Consider family sharing options for some services"
                            ]
                        ))
                    }
                }
            }
            
            // Sort combinations by savings and introduce slight delay to simulate ML processing
            let sortedCombinations = combinations.sorted { $0.monthlySavings > $1.monthlySavings }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                completion(.success(sortedCombinations))
            }
        }
    }
    
    // Generate personalized monthly summary using NLP simulation
    func generateMonthlySummary(
        subscriptions: [Subscription],
        spendingHistory: [Date: Double],
        userPreferences: UserPreferences,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard isModelLoaded else {
            completion(.failure(MLError.modelNotLoaded))
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Calculate current monthly spending
            let currentMonthSpend = subscriptions.reduce(0) { $0 + $1.monthlyCost }
            
            // Calculate month-over-month change if data is available
            let sortedMonths = spendingHistory.keys.sorted()
            var monthOverMonthChange = ""
            
            if sortedMonths.count >= 2 {
                let previousMonthSpend = spendingHistory[sortedMonths[sortedMonths.count - 2]] ?? 0
                let changeAmount = currentMonthSpend - previousMonthSpend
                let changePercent = previousMonthSpend > 0 ? (changeAmount / previousMonthSpend) * 100 : 0
                
                if abs(changePercent) < 1 {
                    monthOverMonthChange = "Your spending is about the same as last month. "
                } else if changeAmount > 0 {
                    monthOverMonthChange = "Your spending increased by \(String(format: "%.1f", abs(changePercent)))% from last month. "
                } else {
                    monthOverMonthChange = "Your spending decreased by \(String(format: "%.1f", abs(changePercent)))% from last month. "
                }
            }
            
            // Budget analysis
            var budgetAnalysis = ""
            if userPreferences.monthlyBudget > 0 {
                let budgetPercent = (currentMonthSpend / userPreferences.monthlyBudget) * 100
                
                if budgetPercent > 100 {
                    budgetAnalysis = "You're currently \(String(format: "%.0f", budgetPercent - 100))% over your monthly budget. Consider pausing or canceling less-used subscriptions. "
                } else if budgetPercent > 90 {
                    budgetAnalysis = "You're at \(String(format: "%.0f", budgetPercent))% of your monthly budget. You're close to your limit. "
                } else if budgetPercent > 75 {
                    budgetAnalysis = "You're at \(String(format: "%.0f", budgetPercent))% of your monthly budget. You're in good shape. "
                } else {
                    budgetAnalysis = "You're only using \(String(format: "%.0f", budgetPercent))% of your monthly budget. Great job! "
                }
            }
            
            // Category insights
            var categoryInsight = ""
            let categorySpending = Dictionary(grouping: subscriptions) { $0.category }
                .mapValues { subs in
                    subs.reduce(0) { $0 + $1.monthlyCost }
                }
            
            if let topCategory = categorySpending.max(by: { $0.value < $1.value }) {
                let topCategoryPercent = currentMonthSpend > 0 ? (topCategory.value / currentMonthSpend) * 100 : 0
                categoryInsight = "Your biggest spending category is \(topCategory.key.rawValue.capitalized) at $\(String(format: "%.2f", topCategory.value))/month (\(String(format: "%.0f", topCategoryPercent))% of total). "
                
                // Add category-specific insights
                switch topCategory.key {
                case .entertainment:
                    if topCategoryPercent > 50 {
                        categoryInsight += "Consider if you're fully utilizing all your entertainment subscriptions. "
                    }
                case .software:
                    if topCategoryPercent > 40 {
                        categoryInsight += "Look for bundled software options that might save you money. "
                    }
                default:
                    break
                }
            }
            
            // Subscription-specific insights
            var subscriptionInsight = ""
            if let mostExpensive = subscriptions.max(by: { $0.monthlyCost < $1.monthlyCost }) {
                if mostExpensive.monthlyCost > currentMonthSpend * 0.3 {
                    subscriptionInsight = "\(mostExpensive.name) is your most expensive subscription at $\(String(format: "%.2f", mostExpensive.monthlyCost))/month. Make sure you're getting value from it. "
                }
            }
            
            // Combine all insights
            let summary = """
            You're currently spending $\(String(format: "%.2f", currentMonthSpend)) per month on \(subscriptions.count) subscriptions. \(monthOverMonthChange)
            
            \(budgetAnalysis)
            
            \(categoryInsight)
            
            \(subscriptionInsight)
            """
            
            // Simulate ML processing time
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                completion(.success(summary.trimmingCharacters(in: .whitespacesAndNewlines)))
            }
        }
    }
    
    // MARK: - Error Types
    enum MLError: Error {
        case modelNotLoaded
        case predictionFailed
        case featureExtractionFailed
    }
}
