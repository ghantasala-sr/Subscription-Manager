//
//  UserPreferencesService.swift
//  SubscriptionManager
//
//  Created by Srinivasa Rithik Ghantasala on 4/24/25.
//


import Foundation
import FirebaseFirestore
import Combine

class UserPreferencesService: ObservableObject {
    @Published var userPreferences: UserPreferences?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    func setupPreferencesListener(for userId: String) {
        isLoading = true
        
        // Remove previous listener if exists
        listenerRegistration?.remove()
        
        // Setup real-time listener
        listenerRegistration = db.collection("userPreferences")
            .document(userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "Failed to fetch preferences: \(error.localizedDescription)"
                    self.isLoading = false
                    return
                }
                
                guard let data = snapshot?.data() else {
                    self.userPreferences = nil
                    self.isLoading = false
                    return
                }
                
                self.userPreferences = UserPreferences.fromDictionary(data, id: snapshot?.documentID)
                self.isLoading = false
            }
    }
    
    func updatePreferences(_ preferences: UserPreferences, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let id = preferences.id else {
            completion(.failure(NSError(domain: "UserPreferencesService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Preferences ID is missing"])))
            return
        }
        
        let preferencesData = preferences.dictionaryRepresentation
        
        db.collection("userPreferences").document(id).updateData(preferencesData) { error in
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
