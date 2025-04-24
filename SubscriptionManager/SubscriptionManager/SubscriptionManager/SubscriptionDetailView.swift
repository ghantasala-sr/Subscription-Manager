//
//  SubscriptionDetailView.swift
//  SubscriptionManager
//
//  Created by Srinivasa Rithik Ghantasala on 4/24/25.
//

import SwiftUI

struct SubscriptionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @EnvironmentObject private var preferencesService: UserPreferencesService
    @EnvironmentObject private var familyMemberService: FamilyMemberService

    let subscription: Subscription

    @State private var name: String
    @State private var category: Category
    @State private var cost: Double
    @State private var billingCycle: BillingCycle
    @State private var nextBillingDate: Date
    @State private var cardLastFourDigits: String
    @State private var status: SubscriptionStatus
    @State private var notes: String
    @State private var logoName: String
    @State private var selectedFamilyMember: FamilyMember?

    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var showingErrorAlert = false
    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    @State private var activeSheet: ActiveSheet? = nil

    enum ActiveSheet: Identifiable {
        case paymentHistory
        case addPayment
        var id: Int { self == .paymentHistory ? 0 : 1 }
    }

    private let notificationService = NotificationService()

    init(subscription: Subscription) {
        self.subscription = subscription
        _name = State(initialValue: subscription.name)
        _category = State(initialValue: subscription.category)
        _cost = State(initialValue: subscription.cost)
        _billingCycle = State(initialValue: subscription.billingCycle)
        _nextBillingDate = State(initialValue: subscription.nextBillingDate)
        _cardLastFourDigits = State(initialValue: subscription.cardLastFourDigits ?? "")
        _status = State(initialValue: subscription.status)
        _notes = State(initialValue: subscription.notes ?? "")
        _logoName = State(initialValue: subscription.logoName)
        _selectedFamilyMember = State(initialValue: subscription.familyMember)
    }

    var body: some View {
        Form {
            if isEditing { editModeContent }
            else { viewModeContent }
        }
        .listStyle(.insetGrouped)
        .padding(.top)
        .navigationTitle(isEditing ? "Edit Subscription" : subscription.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    isEditing ? saveChanges() : (isEditing = true)
                }
            }
            if isEditing {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        resetFields()
                        isEditing = false
                    }
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .paymentHistory: PaymentHistoryView(subscription: subscription)
            case .addPayment:     AddPaymentView(subscription: subscription)
            }
        }
        .alert(
            "Delete Subscription?",
            isPresented: $showingDeleteAlert,
            actions: {
                Button("Delete", role: .destructive) { deleteSubscription() }
                Button("Cancel", role: .cancel) { }
            },
            message: { Text("This action cannot be undone.") }
        )
        .alert(
            "Error",
            isPresented: $showingErrorAlert,
            actions: { Button("OK", role: .cancel) { errorMessage = nil } },
            message: { Text(errorMessage ?? "An unknown error occurred") }
        )
        .overlay(
            Group { if isLoading { LoadingView().frame(maxWidth: .infinity, maxHeight: .infinity) } }
        )
    }

    // MARK: - Edit Mode Content
    private var editModeContent: some View {
        Group {
            Section(header: Text("Subscription Details").font(.headline)) {
                TextField("Name", text: $name)
                    .padding(.vertical, 8)
                Picker("Category", selection: $category) {
                    ForEach(Category.allCases) { c in Text(c.displayName).tag(c) }
                }
                .padding(.vertical, 8)
                HStack {
                    Text("Cost")
                    Spacer()
                    TextField("0.00", value: $cost, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                .padding(.vertical, 8)
                Picker("Billing Cycle", selection: $billingCycle) {
                    ForEach(BillingCycle.allCases) { b in Text(b.displayName).tag(b) }
                }
                .padding(.vertical, 8)
                DatePicker("Next Billing Date", selection: $nextBillingDate, displayedComponents: .date)
                    .padding(.vertical, 8)
                Picker("Status", selection: $status) {
                    ForEach(SubscriptionStatus.allCases) { s in
                        Label(s.displayName, systemImage: s.icon).tag(s)
                    }
                }
                .padding(.vertical, 8)
            }

            Section(header: Text("Family Member").font(.headline)) {
                if familyMemberService.familyMembers.isEmpty {
                    NavigationLink("Add a Family Member", destination: FamilyMembersListView())
                } else {
                    Picker("For Family Member", selection: $selectedFamilyMember) {
                        Text("None (For Me)").tag(nil as FamilyMember?)
                        ForEach(familyMemberService.familyMembers) { m in
                            Text("\(m.name) (\(m.relationship))").tag(m as FamilyMember?)
                        }
                    }
                }
            }

            Section(header: Text("Optional Details").font(.headline)) {
                TextField("Card last 4 digits", text: $cardLastFourDigits)
                    .keyboardType(.numberPad)
                    .onChange(of: cardLastFourDigits) { v in
                        if v.count > 4 { cardLastFourDigits = String(v.prefix(4)) }
                    }
                    .padding(.vertical, 8)
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3...5)
                    .padding(.vertical, 8)
            }

            Section {
                Button(role: .destructive) { showingDeleteAlert = true } label: {
                    Text("Delete Subscription")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - View Mode Content
    private var viewModeContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                detailsSection
                notesSection
                paymentTrackingSection
                statusActionsSection
            }
            .padding(.vertical)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            LogoImageView(logoName: subscription.logoName, size: 100)
                .opacity(subscription.status == .active ? 1 : 0.6)
            HStack {
                Text("Status:")
                Spacer()
                Label(subscription.status.displayName, systemImage: subscription.status.icon)
                    .foregroundColor(Color(subscription.status.color))
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details").font(.headline)
            detailRow("Category", subscription.category.displayName)
            detailRow("Cost", String(format: "$%.2f", subscription.cost))
            detailRow("Billing Cycle", subscription.billingCycle.displayName)
            detailRow("Next Billing Date", formatDate(subscription.nextBillingDate))
            if let digits = subscription.cardLastFourDigits {
                detailRow("Payment Card", "•••• \(digits)")
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var notesSection: some View {
        Group {
            if let notes = subscription.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Notes").font(.headline)
                    Text(notes)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }

    private var paymentTrackingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Tracking").font(.headline)
            HStack {
                Image(systemName: "creditcard.fill")
                Text("Payment History")
                Spacer()
                Image(systemName: "chevron.right")
            }
            .contentShape(Rectangle())
            .onTapGesture { activeSheet = .paymentHistory }

            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Mark as Paid")
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture { activeSheet = .addPayment }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var statusActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status Actions").font(.headline)
            switch subscription.status {
            case .active:
                HStack {
                    Label("Pause Subscription", systemImage: "pause.circle.fill")
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture { changeStatus(.paused) }

                HStack {
                    Label("Cancel Subscription", systemImage: "xmark.circle.fill")
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture { changeStatus(.cancelled) }

            case .paused:
                HStack {
                    Label("Activate Subscription", systemImage: "checkmark.circle.fill")
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture { changeStatus(.active) }

                HStack {
                    Label("Cancel Subscription", systemImage: "xmark.circle.fill")
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture { changeStatus(.cancelled) }

            case .cancelled:
                HStack {
                    Label("Reactivate Subscription", systemImage: "checkmark.circle.fill")
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture { changeStatus(.active) }

                HStack {
                    Label("Archive Subscription", systemImage: "archivebox.fill")
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture { changeStatus(.archived) }

            case .archived:
                HStack {
                    Label("Restore Subscription", systemImage: "checkmark.circle.fill")
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture { changeStatus(.active) }
            }

            HStack {
                Label("Delete Subscription", systemImage: "trash")
                    .foregroundColor(.red)
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture { showingDeleteAlert = true }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var loadingOverlay: some View {
        Group {
            if isLoading { LoadingView() }
        }
    }

    // MARK: - Helpers
    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).foregroundColor(.secondary)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func resetFields() {
        name = subscription.name
        category = subscription.category
        cost = subscription.cost
        billingCycle = subscription.billingCycle
        nextBillingDate = subscription.nextBillingDate
        cardLastFourDigits = subscription.cardLastFourDigits ?? ""
        status = subscription.status
        notes = subscription.notes ?? ""
        logoName = subscription.logoName
        selectedFamilyMember = subscription.familyMember
    }

    private func saveChanges() {
        guard let id = subscription.id else {
            errorMessage = "Missing subscription data"
            showingErrorAlert = true
            return
        }
        isLoading = true

        var key = subscription.notificationKey
        if let old = key {
            notificationService.cancelNotification(with: old)
            key = nil
        }
        if status == .active,
           let prefs = preferencesService.userPreferences,
           prefs.enableNotifications {
            key = notificationService.scheduleNotification(
                for: Subscription(
                    id: id,
                    userId: subscription.userId,
                    name: name,
                    category: category,
                    cost: cost,
                    billingCycle: billingCycle,
                    nextBillingDate: nextBillingDate,
                    cardLastFourDigits: cardLastFourDigits.isEmpty ? nil : cardLastFourDigits,
                    status: status,
                    logoName: logoName,
                    dateAdded: subscription.dateAdded
                ),
                daysBefore: prefs.notifyDaysBefore
            )
        }

        let updated = Subscription(
            id: id,
            userId: subscription.userId,
            name: name,
            category: category,
            cost: cost,
            billingCycle: billingCycle,
            nextBillingDate: nextBillingDate,
            cardLastFourDigits: cardLastFourDigits.isEmpty ? nil : cardLastFourDigits,
            status: status,
            logoName: logoName,
            notificationKey: key,
            notes: notes.isEmpty ? nil : notes,
            dateAdded: subscription.dateAdded,
            familyMember: selectedFamilyMember,
            lastPaymentDate: subscription.lastPaymentDate,
            paymentHistory: subscription.paymentHistory
        )

        subscriptionService.updateSubscription(updated) { result in
            isLoading = false
            switch result {
            case .success: isEditing = false
            case .failure(let error):
                errorMessage = error.localizedDescription
                showingErrorAlert = true
            }
        }
    }

    private func changeStatus(_ newStatus: SubscriptionStatus) {
        guard let id = subscription.id else {
            errorMessage = "Missing subscription data"
            showingErrorAlert = true
            return
        }
        isLoading = true

        var key = subscription.notificationKey
        if let old = key {
            notificationService.cancelNotification(with: old)
            key = nil
        }
        if newStatus == .active,
           let prefs = preferencesService.userPreferences,
           prefs.enableNotifications {
            key = notificationService.scheduleNotification(
                for: subscription,
                daysBefore: prefs.notifyDaysBefore
            )
        }

        var updated = subscription
        updated.status = newStatus
        updated.notificationKey = key

        subscriptionService.updateSubscription(updated) { result in
            isLoading = false
            switch result {
            case .success: status = newStatus
            case .failure(let error):
                errorMessage = error.localizedDescription
                showingErrorAlert = true
            }
        }
    }

    private func deleteSubscription() {
        guard let id = subscription.id else {
            errorMessage = "Missing subscription ID"
            showingErrorAlert = true
            return
        }
        isLoading = true

        if let key = subscription.notificationKey {
            notificationService.cancelNotification(with: key)
        }

        subscriptionService.deleteSubscription(id: id) { result in
            isLoading = false
            switch result {
            case .success: dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
                showingErrorAlert = true
            }
        }
    }
}
