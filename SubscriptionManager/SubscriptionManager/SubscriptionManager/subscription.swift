//
//  subscription.swift
//  SubscriptionManager
//
//  Created by Srinivasa Rithik Ghantasala on 4/24/25.
//

import Foundation
import FirebaseFirestore
import SwiftUICore

enum Category: String, Codable, CaseIterable, Identifiable {
    case entertainment, utilities, software, health, education, other
    
    var id: String { self.rawValue }
    
    var displayName: String {
        self.rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .entertainment: return "tv.fill"              // TV icon for entertainment
        case .utilities: return "bolt.fill"                // Lightning bolt for utilities
        case .software: return "app.fill"                  // App icon for software
        case .health: return "heart.circle.fill"           // Heart for health
        case .education: return "book.fill"                // Book for education
        case .other: return "square.grid.2x2.fill"         // Grid for other/miscellaneous
        }
    }
    
    var color: Color {
        switch self {
        case .entertainment: return .purple
        case .utilities:    return .blue
        case .software:     return .orange
        case .health:       return .green
        case .education:    return .red
        case .other:        return .gray
        }
    }

}

enum BillingCycle: String, Codable, CaseIterable, Identifiable {
    case monthly, quarterly, semiAnnual, annual, custom
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .semiAnnual: return "Semi-Annual"
        case .annual: return "Annual"
        case .custom: return "Custom"
        }
    }
    
    var monthlyFactor: Double {
        switch self {
        case .monthly: return 1.0
        case .quarterly: return 1.0/3.0
        case .semiAnnual: return 1.0/6.0
        case .annual: return 1.0/12.0
        case .custom: return 1.0
        }
    }
}

enum SubscriptionStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    case active, paused, cancelled, archived
    
    var id: String { self.rawValue }
    
    var displayName: String {
        self.rawValue.capitalized
    }
    
    var color: Color {
        switch self {
        case .active: return .green
        case .paused: return .orange
        case .cancelled: return .red
        case .archived: return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .active: return "checkmark.circle.fill"
        case .paused: return "pause.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        case .archived: return "archivebox.fill"
        }
    }
}

struct FamilyMember: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var relationship: String
    
    var dictionaryRepresentation: [String: Any] {
        return [
            "id": id,
            "name": name,
            "relationship": relationship
        ]
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: FamilyMember, rhs: FamilyMember) -> Bool {
        return lhs.id == rhs.id
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> FamilyMember? {
        guard
            let id = dict["id"] as? String,
            let name = dict["name"] as? String,
            let relationship = dict["relationship"] as? String
        else {
            return nil
        }
        
        return FamilyMember(
            id: id,
            name: name,
            relationship: relationship
        )
    }
}

struct PaymentRecord: Identifiable, Codable {
    var id: String
    var date: Date
    var amount: Double
    var note: String?
    
    var dictionaryRepresentation: [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "date": date,
            "amount": amount
        ]
        
        if let note = note {
            dict["note"] = note
        }
        
        return dict
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> PaymentRecord? {
        guard
            let id = dict["id"] as? String,
            let date = dict["date"] as? Timestamp,
            let amount = dict["amount"] as? Double
        else {
            return nil
        }
        
        return PaymentRecord(
            id: id,
            date: date.dateValue(),
            amount: amount,
            note: dict["note"] as? String
        )
    }
}

struct Subscription: Identifiable, Codable, Hashable {
    static func == (lhs: Subscription, rhs: Subscription) -> Bool {
        return lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
            // Using id as the unique identifier for hashing
            hasher.combine(id)
        }
    
    @DocumentID var id: String?
    var userId: String
    var name: String
    var category: Category
    var cost: Double
    var billingCycle: BillingCycle
    var nextBillingDate: Date
    var cardLastFourDigits: String?
    var status: SubscriptionStatus
    var logoName: String
    var notificationKey: String?
    var notes: String?
    var dateAdded: Date
    
    // Family member and payment tracking
    var familyMember: FamilyMember?
    var lastPaymentDate: Date?
    var paymentHistory: [PaymentRecord]?
    
    var monthlyCost: Double {
        return cost * billingCycle.monthlyFactor
    }
    
    var dictionaryRepresentation: [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "name": name,
            "category": category.rawValue,
            "cost": cost,
            "billingCycle": billingCycle.rawValue,
            "nextBillingDate": nextBillingDate,
            "status": status.rawValue,
            "logoName": logoName,
            "dateAdded": dateAdded
        ]
        
        // Add optional fields
        if let cardLastFourDigits = cardLastFourDigits {
            dict["cardLastFourDigits"] = cardLastFourDigits
        }
        
        if let notificationKey = notificationKey {
            dict["notificationKey"] = notificationKey
        }
        
        if let notes = notes {
            dict["notes"] = notes
        }
        
        if let familyMember = familyMember {
            dict["familyMember"] = familyMember.dictionaryRepresentation
        }
        
        if let lastPaymentDate = lastPaymentDate {
            dict["lastPaymentDate"] = lastPaymentDate
        }
        
        if let paymentHistory = paymentHistory {
            dict["paymentHistory"] = paymentHistory.map { $0.dictionaryRepresentation }
        }
        
        
        return dict
    }
    
    static func fromDictionary(_ dict: [String: Any], id: String? = nil) -> Subscription? {
        guard
            let userId = dict["userId"] as? String,
            let name = dict["name"] as? String,
            let categoryString = dict["category"] as? String,
            let category = Category(rawValue: categoryString),
            let cost = dict["cost"] as? Double,
            let billingCycleString = dict["billingCycle"] as? String,
            let billingCycle = BillingCycle(rawValue: billingCycleString),
            let nextBillingDate = dict["nextBillingDate"] as? Timestamp,
            let statusString = dict["status"] as? String,
            let status = SubscriptionStatus(rawValue: statusString),
            let logoName = dict["logoName"] as? String,
            let dateAdded = dict["dateAdded"] as? Timestamp
        else {
            return nil
        }
        
        // Parse optional fields
        var familyMember: FamilyMember? = nil
        if let familyMemberDict = dict["familyMember"] as? [String: Any] {
            familyMember = FamilyMember.fromDictionary(familyMemberDict)
        }
        
        var lastPaymentDate: Date? = nil
        if let lastPaymentTimestamp = dict["lastPaymentDate"] as? Timestamp {
            lastPaymentDate = lastPaymentTimestamp.dateValue()
        }
        
        var paymentHistory: [PaymentRecord]? = nil
        if let paymentHistoryArray = dict["paymentHistory"] as? [[String: Any]] {
            paymentHistory = paymentHistoryArray.compactMap { PaymentRecord.fromDictionary($0) }
        }
        
        
            
        
        return Subscription(
            id: id,
            userId: userId,
            name: name,
            category: category,
            cost: cost,
            billingCycle: billingCycle,
            nextBillingDate: nextBillingDate.dateValue(),
            cardLastFourDigits: dict["cardLastFourDigits"] as? String,
            status: status,
            logoName: logoName,
            notificationKey: dict["notificationKey"] as? String,
            notes: dict["notes"] as? String,
            dateAdded: dateAdded.dateValue(),
            familyMember: familyMember,
            lastPaymentDate: lastPaymentDate,
            paymentHistory: paymentHistory
        )
    }
}

struct SubscriptionTemplate: Identifiable {
    let id = UUID()
    let name: String
    let logo: String
    let category: Category
    let defaultCost: Double
}

struct SubscriptionCombination: Identifiable {
    let id: String
    let title: String
    let description: String
    let subscriptionIds: [String]
    let monthlySavings: Double
    let confidenceScore: Double  // 0.0-1.0 representing the model's confidence
    let implementationSteps: [String]
}



