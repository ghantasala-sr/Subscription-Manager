//
//  SubscriptionService.swift
//  SubscriptionManager
//
//  Created by Srinivasa Rithik Ghantasala on 4/24/25.
//


import Foundation
import FirebaseFirestore
import Combine

class SubscriptionService: ObservableObject {
    @Published var subscriptions: [Subscription] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var forceRefresh = UUID() // Add this to force view updates
    
    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    func setupSubscriptionsListener(for userId: String) {
        isLoading = true
        
        // Remove previous listener if exists
        listenerRegistration?.remove()
        
        // Setup real-time listener
        listenerRegistration = db.collection("subscriptions")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "Failed to fetch subscriptions: \(error.localizedDescription)"
                    self.isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.subscriptions = []
                    self.isLoading = false
                    return
                }
                
                self.subscriptions = documents.compactMap { document in
                    Subscription.fromDictionary(document.data(), id: document.documentID)
                }.sorted { $0.nextBillingDate < $1.nextBillingDate }
                
                self.isLoading = false
                
                // Trigger UI refresh
                DispatchQueue.main.async {
                    self.forceRefresh = UUID()
                }
            }
    }
    
    func addSubscription(_ subscription: Subscription, completion: @escaping (Result<Void, Error>) -> Void) {
        let subscriptionData = subscription.dictionaryRepresentation
        
        db.collection("subscriptions").addDocument(data: subscriptionData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                // Force refresh after adding
                DispatchQueue.main.async {
                    self.forceRefresh = UUID()
                }
                completion(.success(()))
            }
        }
    }
    
    func updateSubscription(_ subscription: Subscription, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let id = subscription.id else {
            completion(.failure(NSError(domain: "SubscriptionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Subscription ID is missing"])))
            return
        }
        
        let subscriptionData = subscription.dictionaryRepresentation
        
        // First, update the local array immediately for UI responsiveness
        if let index = self.subscriptions.firstIndex(where: { $0.id == subscription.id }) {
            // Make a new copy of the subscriptions array
            var updatedSubscriptions = self.subscriptions
            updatedSubscriptions[index] = subscription
            
            // Update the published property to ensure UI refreshes
            DispatchQueue.main.async {
                self.subscriptions = updatedSubscriptions
                self.objectWillChange.send()
                self.forceRefresh = UUID()
            }
        }
        
        // Then update in Firestore
        db.collection("subscriptions").document(id).updateData(subscriptionData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func deleteSubscription(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("subscriptions").document(id).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                // Force refresh after deleting
                DispatchQueue.main.async {
                    self.forceRefresh = UUID()
                }
                completion(.success(()))
            }
        }
    }
    
    func removeListeners() {
        listenerRegistration?.remove()
        listenerRegistration = nil
    }
    
    deinit {
        removeListeners()
    }
}
