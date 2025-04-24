//
//  CategoryPieChartView.swift
//  SubscriptionManager
//
//  Created by Srinivasa Rithik Ghantasala on 4/24/25.
//


import SwiftUI

struct CategoryPieChartView: View {
    let subscriptions: [Subscription]
    @State private var selectedCategory: Category? = nil
    
    // Calculate category data
    private var categoryData: [(category: Category, amount: Double, percentage: Double)] {
        let activeSubscriptions = subscriptions.filter { $0.status == .active }
        let totalSpend = activeSubscriptions.reduce(0) { $0 + ($1.cost * $1.billingCycle.monthlyFactor) }
        
        let grouped = Dictionary(grouping: activeSubscriptions) { $0.category }
        let amounts = grouped.mapValues { subscriptions in
            subscriptions.reduce(0) { $0 + ($1.cost * $1.billingCycle.monthlyFactor) }
        }
        
        return Category.allCases.compactMap { category in
            guard let amount = amounts[category], amount > 0 else { return nil }
            let percentage = totalSpend > 0 ? amount / totalSpend : 0
            return (category: category, amount: amount, percentage: percentage)
        }.sorted { $0.amount > $1.amount }
    }
    
    var body: some View {
        VStack {
            // Pie chart
            ZStack {
                ForEach(0..<categoryData.count, id: \.self) { index in
                    let data = categoryData[index]
                    PieSlice(
                        startAngle: startAngle(for: index),
                        endAngle: endAngle(for: index),
                        category: data.category,
                        isSelected: selectedCategory == data.category
                    )
                    .onTapGesture {
                        withAnimation {
                            selectedCategory = selectedCategory == data.category ? nil : data.category
                        }
                    }
                }
                
                // Center text
                VStack {
                    if let selected = selectedCategory, let data = categoryData.first(where: { $0.category == selected }) {
                        Text(selected.displayName)
                            .font(.headline)
                        
                        Text("$\(data.amount, specifier: "%.2f")")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text("\(Int(data.percentage * 100))%")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Total")
                            .font(.headline)
                        
                        let total = categoryData.reduce(0) { $0 + $1.amount }
                        Text("$\(total, specifier: "%.2f")")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text("Monthly")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Legend
            HStack {
                ForEach(categoryData.prefix(4), id: \.category) { data in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(data.category.color))
                            .frame(width: 8, height: 8)
                        
                        Text(data.category.displayName)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(.top, 10)
        }
    }
    
    // Calculate start and end angles for each slice
    private func startAngle(for index: Int) -> Double {
        if index == 0 { return 0 }
        
        var sum = 0.0
        for i in 0..<index {
            sum += categoryData[i].percentage
        }
        
        return sum * 360
    }
    
    private func endAngle(for index: Int) -> Double {
        var sum = 0.0
        for i in 0...index {
            sum += categoryData[i].percentage
        }
        
        return sum * 360
    }
}

struct PieSlice: View {
    let startAngle: Double
    let endAngle: Double
    let category: Category
    let isSelected: Bool
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2 * (isSelected ? 1.05 : 0.95)
                
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(startAngle - 90),
                    endAngle: .degrees(endAngle - 90),
                    clockwise: false
                )
                path.closeSubpath()
            }
            .fill(Color(category.color))
            .shadow(color: isSelected ? Color.black.opacity(0.2) : Color.clear, radius: 5, x: 0, y: 2)
            .animation(.spring(), value: isSelected)
        }
    }
}