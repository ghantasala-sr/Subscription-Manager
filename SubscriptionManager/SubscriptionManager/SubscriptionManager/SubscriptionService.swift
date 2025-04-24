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
            }
    }
    
    func addSubscription(_ subscription: Subscription, completion: @escaping (Result<Void, Error>) -> Void) {
        let subscriptionData = subscription.dictionaryRepresentation
        
        db.collection("subscriptions").addDocument(data: subscriptionData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
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
