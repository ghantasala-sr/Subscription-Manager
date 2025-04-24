//
//  UserPreferences.swift
//  SubscriptionManager
//
//  Created by Srinivasa Rithik Ghantasala on 4/24/25.
//


import Foundation
import FirebaseFirestore

struct UserPreferences: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var monthlyBudget: Double
    var yearlyBudget: Double
    var enableNotifications: Bool
    var notificationTime: Date
    var notifyDaysBefore: Int
    var currencyCode: String
    var themePreference: String
    var createdAt: Date
    
    var dictionaryRepresentation: [String: Any] {
        return [
            "userId": userId,
            "monthlyBudget": monthlyBudget,
            "yearlyBudget": yearlyBudget,
            "enableNotifications": enableNotifications,
            "notificationTime": notificationTime,
            "notifyDaysBefore": notifyDaysBefore,
            "currencyCode": currencyCode,
            "themePreference": themePreference,
            "createdAt": createdAt
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any], id: String? = nil) -> UserPreferences? {
        guard 
            let userId = dict["userId"] as? String,
            let monthlyBudget = dict["monthlyBudget"] as? Double,
            let yearlyBudget = dict["yearlyBudget"] as? Double,
            let enableNotifications = dict["enableNotifications"] as? Bool,
            let notificationTime = dict["notificationTime"] as? Timestamp,
            let notifyDaysBefore = dict["notifyDaysBefore"] as? Int,
            let currencyCode = dict["currencyCode"] as? String,
            let themePreference = dict["themePreference"] as? String,
            let createdAt = dict["createdAt"] as? Timestamp
        else {
            return nil
        }
        
        return UserPreferences(
            id: id,
            userId: userId,
            monthlyBudget: monthlyBudget,
            yearlyBudget: yearlyBudget,
            enableNotifications: enableNotifications,
            notificationTime: notificationTime.dateValue(),
            notifyDaysBefore: notifyDaysBefore,
            currencyCode: currencyCode,
            themePreference: themePreference,
            createdAt: createdAt.dateValue()
        )
    }
}
