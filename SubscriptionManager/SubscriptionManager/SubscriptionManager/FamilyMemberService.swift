//
//  FamilyMemberService.swift
//  SubscriptionManager
//
//  Created by Srinivasa Rithik Ghantasala on 4/24/25.
//


import Foundation
import FirebaseFirestore
import Combine

class FamilyMemberService: ObservableObject {
    @Published var familyMembers: [FamilyMember] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    func setupFamilyMembersListener(for userId: String) {
        isLoading = true
        
        // Remove previous listener if exists
        listenerRegistration?.remove()
        
        // Setup real-time listener
        listenerRegistration = db.collection("familyMembers")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "Failed to fetch family members: \(error.localizedDescription)"
                    self.isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.familyMembers = []
                    self.isLoading = false
                    return
                }
                
                self.familyMembers = documents.compactMap { document in
                    guard 
                        let name = document.data()["name"] as? String,
                        let relationship = document.data()["relationship"] as? String
                    else {
                        return nil
                    }
                    
                    return FamilyMember(
                        id: document.documentID,
                        name: name,
                        relationship: relationship
                    )
                }.sorted { $0.name < $1.name }
                
                self.isLoading = false
            }
    }
    
    func addFamilyMember(_ name: String, relationship: String, userId: String, completion: @escaping (Result<FamilyMember, Error>) -> Void) {
        isLoading = true
        
        let data: [String: Any] = [
            "userId": userId,
            "name": name,
            "relationship": relationship,
            "createdAt": Timestamp(date: Date())
        ]
        
        db.collection("familyMembers").addDocument(data: data) { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                completion(.failure(error))
            } else {
                // Create a FamilyMember object with a temporary ID (will be updated by listener)
                let familyMember = FamilyMember(
                    id: UUID().uuidString,
                    name: name,
                    relationship: relationship
                )
                completion(.success(familyMember))
            }
        }
    }
    
    func updateFamilyMember(_ familyMember: FamilyMember, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        
        let data: [String: Any] = [
            "name": familyMember.name,
            "relationship": familyMember.relationship,
            "updatedAt": Timestamp(date: Date())
        ]
        
        db.collection("familyMembers").document(familyMember.id).updateData(data) { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func deleteFamilyMember(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        
        db.collection("familyMembers").document(id).delete { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false
            
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
