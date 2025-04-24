//
//  SubscriptionsListView.swift
//  SubscriptionManager
//
//  Created by Srinivasa Rithik Ghantasala on 4/24/25.
//


import SwiftUI

struct SubscriptionsListView: View {
    @EnvironmentObject private var subscriptionService: SubscriptionService
    
    @State private var showAddSubscription = false
    @State private var searchText = ""
    @State private var selectedCategory: Category? = nil
    @State private var selectedStatus: SubscriptionStatus? = nil
    @State private var sortOption = SortOption.dateAscending
    
    enum SortOption {
        case dateAscending, dateDescending, costAscending, costDescending, nameAscending, nameDescending
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Extract the filters into separate views
                categoryFilterView
                
                statusFilterView
                
                subscriptionListView
            }
            .navigationTitle("Subscriptions")
            .searchable(text: $searchText, prompt: "Search your subscriptions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    addButton
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    sortMenu
                }
            }
            .overlay(loadingOverlay)
            .sheet(isPresented: $showAddSubscription) {
                AddSubscriptionView()
            }
        }
    }
    
    // MARK: - Extracted Views
    
    private var categoryFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                CategoryFilterButton(title: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                
                ForEach(Category.allCases) { category in
                    CategoryFilterButton(
                        title: category.displayName,
                        isSelected: selectedCategory == category,
                        color: Color(category.color)
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var statusFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                StatusFilterButton(title: "All", isSelected: selectedStatus == nil) {
                    selectedStatus = nil
                }
                
                ForEach(SubscriptionStatus.allCases) { status in
                    StatusFilterButton(
                        title: status.displayName,
                        isSelected: selectedStatus == status,
                        color: Color(status.color)
                    ) {
                        selectedStatus = status
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var subscriptionListView: some View {
        List {
            ForEach(filteredAndSortedSubscriptions) { subscription in
                NavigationLink(destination: SubscriptionDetailView(subscription: subscription)) {
                    SubscriptionRowView(subscription: subscription)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        deleteSubscription(subscription)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading) {
                    Button {
                        toggleSubscriptionStatus(subscription)
                    } label: {
                        Label(
                            subscription.status == .active ? "Pause" : "Activate",
                            systemImage: subscription.status == .active ? "pause.fill" : "play.fill"
                        )
                    }
                    .tint(subscription.status == .active ? .orange : .green)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .animation(.default, value: filteredAndSortedSubscriptions)
        .overlay(emptyStateOverlay)
    }
    
    private var emptyStateOverlay: some View {
        Group {
            if subscriptionService.subscriptions.isEmpty && !subscriptionService.isLoading {
                EmptyStateView(
                    systemImage: "creditcard",
                    title: "No Subscriptions Yet",
                    message: "Add your first subscription to start tracking your expenses",
                    buttonTitle: "Add Subscription",
                    action: { showAddSubscription = true }
                )
            }
        }
    }
    
    private var loadingOverlay: some View {
        Group {
            if subscriptionService.isLoading {
                LoadingView()
            }
        }
    }
    
    private var addButton: some View {
        Button(action: {
            showAddSubscription = true
        }) {
            Image(systemName: "plus")
        }
    }
    
    private var sortMenu: some View {
        Menu {
            Button("Date (Soonest First)") {
                sortOption = .dateAscending
            }
            
            Button("Date (Latest First)") {
                sortOption = .dateDescending
            }
            
            Button("Cost (Lowest First)") {
                sortOption = .costAscending
            }
            
            Button("Cost (Highest First)") {
                sortOption = .costDescending
            }
            
            Button("Name (A-Z)") {
                sortOption = .nameAscending
            }
            
            Button("Name (Z-A)") {
                sortOption = .nameDescending
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }
    
    // MARK: - Helper Properties and Methods
    
    private var filteredAndSortedSubscriptions: [Subscription] {
        // Start with all subscriptions
        var result = subscriptionService.subscriptions
        
        // Apply category filter
        if let selectedCategory = selectedCategory {
            result = result.filter { $0.category == selectedCategory }
        }
        
        // Apply status filter
        if let selectedStatus = selectedStatus {
            result = result.filter { $0.status == selectedStatus }
        }
        
        // Apply search filter (broken down for clarity)
        if !searchText.isEmpty {
            result = result.filter { subscription in
                // Check name match
                let nameMatch = subscription.name.localizedCaseInsensitiveContains(searchText)
                
                // Check notes match
                let notesMatch = subscription.notes?.localizedCaseInsensitiveContains(searchText) ?? false
                
                // Check family member match
                let familyMatch = subscription.familyMember?.name.localizedCaseInsensitiveContains(searchText) ?? false
                
                // Return true if any match
                return nameMatch || notesMatch || familyMatch
            }
        }
        
        // Apply sorting
        switch sortOption {
        case .dateAscending:
            result.sort { $0.nextBillingDate < $1.nextBillingDate }
        case .dateDescending:
            result.sort { $0.nextBillingDate > $1.nextBillingDate }
        case .costAscending:
            result.sort { $0.cost < $1.cost }
        case .costDescending:
            result.sort { $0.cost > $1.cost }
        case .nameAscending:
            result.sort { $0.name < $1.name }
        case .nameDescending:
            result.sort { $0.name > $1.name }
        }
        
        return result
    }
    
    private func deleteSubscription(_ subscription: Subscription) {
        guard let id = subscription.id else { return }
        
        subscriptionService.deleteSubscription(id: id) { _ in
            // Handled by real-time listener
        }
    }
    
    private func toggleSubscriptionStatus(_ subscription: Subscription) {
        guard var updatedSubscription = subscriptionService.subscriptions.first(where: { $0.id == subscription.id }) else { return }
        
        // Cycle through statuses: active -> paused -> active
        updatedSubscription.status = updatedSubscription.status == .active ? .paused : .active
        
        subscriptionService.updateSubscription(updatedSubscription) { _ in
            // Handled by real-time listener
        }
    }
}

struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    var color: Color = .blue
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color.opacity(0.1) : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? color : .primary)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? color : Color.clear, lineWidth: 1)
                )
        }
    }
}

struct StatusFilterButton: View {
    let title: String
    let isSelected: Bool
    var color: Color = .blue
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color.opacity(0.1) : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? color : .primary)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? color : Color.clear, lineWidth: 1)
                )
        }
    }
}

struct SubscriptionRowView: View {
    let subscription: Subscription
    
    var body: some View {
        HStack(spacing: 15) {
            // Logo with status indicator
            ZStack(alignment: .bottomTrailing) {
                LogoImageView(logoName: subscription.logoName, size: 44)
                    .opacity(subscription.status == .active ? 1.0 : 0.6)
                
                // Status indicator
                if subscription.status != .active {
                    Image(systemName: subscription.status.icon)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .padding(3)
                        .background(Color(subscription.status.color))
                        .clipShape(Circle())
                        .offset(x: 3, y: 3)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.headline)
                    .foregroundColor(subscription.status == .active ? .primary : .secondary)
                
                HStack {
                    Text("Next billing: \(formatDate(subscription.nextBillingDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Add family member badge if present
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
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(subscription.cost, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(subscription.status == .active ? .primary : .secondary)
                
                Text(subscription.billingCycle.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
