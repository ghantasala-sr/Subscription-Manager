//
//  AuthenticationService.swift
//  SubscriptionManager
//
//  Created by Srinivasa Rithik Ghantasala on 4/24/25.
//


import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class AuthenticationService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        auth.addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            
            if let user = user {
                self.isLoading = true
                self.fetchUserData(uid: user.uid)
            } else {
                self.currentUser = nil
                self.isAuthenticated = false
                self.isLoading = false
            }
        }
    }
    
    private func fetchUserData(uid: String) {
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = "Failed to fetch user data: \(error.localizedDescription)"
                self.isLoading = false
                return
            }
            
            if let data = snapshot?.data(),
               let user = User.fromDictionary(data, id: uid) {
                self.currentUser = user
                self.isAuthenticated = true
            } else {
                self.errorMessage = "User data not found"
            }
            
            self.isLoading = false
        }
    }
    
    func signUp(email: String, password: String, firstName: String?, lastName: String?, monthlyBudget: Double, yearlyBudget: Double, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                completion(false)
                return
            }
            
            guard let uid = result?.user.uid else {
                self.errorMessage = "Failed to create user"
                self.isLoading = false
                completion(false)
                return
            }
            
            // Create user profile
            let userData = User(
                id: uid,
                email: email,
                firstName: firstName,
                lastName: lastName,
                createdAt: Date()
            )
            
            // Create user preferences
            let userPreferences = UserPreferences(
                userId: uid,
                monthlyBudget: monthlyBudget,
                yearlyBudget: yearlyBudget,
                enableNotifications: true,
                notificationTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date(),
                notifyDaysBefore: 3,
                currencyCode: "USD",
                themePreference: "system",
                createdAt: Date()
            )
            
            // Save user data to Firestore
            self.db.collection("users").document(uid).setData(userData.dictionaryRepresentation) { error in
                if let error = error {
                    self.errorMessage = "Failed to save user data: \(error.localizedDescription)"
                    self.isLoading = false
                    completion(false)
                    return
                }
                
                // Save user preferences
                self.db.collection("userPreferences").document(uid).setData(userPreferences.dictionaryRepresentation) { error in
                    if let error = error {
                        self.errorMessage = "Failed to save user preferences: \(error.localizedDescription)"
                        self.isLoading = false
                        completion(false)
                        return
                    }
                    
                    // Add sample subscriptions
                    self.addSampleSubscriptions(for: uid) {
                        self.isLoading = false
                        completion(true)
                    }
                }
            }
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        auth.signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                completion(false)
                return
            }
            
            // AuthStateDidChangeListener will handle fetching user data
            completion(true)
        }
    }
    
    func signOut() {
        do {
            try auth.signOut()
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }
    
    func resetPassword(email: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        auth.sendPasswordReset(withEmail: email) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                completion(false)
                return
            }
            
            self.isLoading = false
            completion(true)
        }
    }
    
    private func addSampleSubscriptions(for userId: String, completion: @escaping () -> Void) {
        let subscriptionsRef = db.collection("subscriptions")
        
        let batch = db.batch()
        
        // Netflix
        let netflix = Subscription(
            userId: userId,
            name: "Netflix",
            category: .entertainment,
            cost: 15.99,
            billingCycle: .monthly,
            nextBillingDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            cardLastFourDigits: "4387",
            status: .active,
            logoName: "netflix",
            dateAdded: Date()
        )
        
        // Spotify
        let spotify = Subscription(
            userId: userId,
            name: "Spotify",
            category: .entertainment,
            cost: 9.99,
            billingCycle: .monthly,
            nextBillingDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date(),
            cardLastFourDigits: "4387",
            status: .active,
            logoName: "spotify",
            dateAdded: Date()
        )
        
        // Hulu
        let hulu = Subscription(
            userId: userId,
            name: "Hulu",
            category: .entertainment,
            cost: 7.99,
            billingCycle: .monthly,
            nextBillingDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
            status: .active,
            logoName: "hulu",
            dateAdded: Date()
        )
        
        // Adobe CC
        let adobeCC = Subscription(
            userId: userId,
            name: "Adobe Creative Cloud",
            category: .software,
            cost: 52.99,
            billingCycle: .monthly,
            nextBillingDate: Calendar.current.date(byAdding: .day, value: 21, to: Date()) ?? Date(),
            cardLastFourDigits: "8921",
            status: .active,
            logoName: "adobe",
            dateAdded: Date()
        )
        
        // Gym
        let gym = Subscription(
            userId: userId,
            name: "Planet Fitness",
            category: .health,
            cost: 24.99,
            billingCycle: .monthly,
            nextBillingDate: Calendar.current.date(byAdding: .day, value: 10, to: Date()) ?? Date(),
            status: .active,
            logoName: "fitness",
            dateAdded: Date()
        )
        
        // Add documents to batch
        let netflixDoc = subscriptionsRef.document()
        batch.setData(netflix.dictionaryRepresentation, forDocument: netflixDoc)
        
        let spotifyDoc = subscriptionsRef.document()
        batch.setData(spotify.dictionaryRepresentation, forDocument: spotifyDoc)
        
        let huluDoc = subscriptionsRef.document()
        batch.setData(hulu.dictionaryRepresentation, forDocument: huluDoc)
        
        let adobeDoc = subscriptionsRef.document()
        batch.setData(adobeCC.dictionaryRepresentation, forDocument: adobeDoc)
        
        let gymDoc = subscriptionsRef.document()
        batch.setData(gym.dictionaryRepresentation, forDocument: gymDoc)
        
        // Commit the batch
        batch.commit { error in
            if let error = error {
                print("Error adding sample subscriptions: \(error)")
            }
            completion()
        }
    }
}