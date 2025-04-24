//
//  NotificationService.swift
//  SubscriptionManager
//
//  Created by Srinivasa Rithik Ghantasala on 4/24/25.
//


import Foundation
import UserNotifications

class NotificationService {
    private let notificationCenter = UNUserNotificationCenter.current()
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error)")
            }
            completion(granted)
        }
    }
    
    func scheduleNotification(for subscription: Subscription, daysBefore: Int) -> String? {
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Subscription Payment"
        content.body = "\(subscription.name) will be billed $\(String(format: "%.2f", subscription.cost)) on \(formattedDate(subscription.nextBillingDate))"
        content.sound = .default
        
        // Calculate trigger date
        let calendar = Calendar.current
        guard let notificationDate = calendar.date(byAdding: .day, value: -daysBefore, to: subscription.nextBillingDate) else {
            return nil
        }
        
        // Create date components for the trigger
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        // Create unique identifier
        let identifier = UUID().uuidString
        
        // Create request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule notification
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
        
        return identifier
    }
    
    func cancelNotification(with identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}