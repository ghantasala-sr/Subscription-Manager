//
//  User.swift
//  SubscriptionManager
//
//  Created by Srinivasa Rithik Ghantasala on 4/24/25.
//


import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var firstName: String?
    var lastName: String?
    var createdAt: Date
    var isEmailVerified: Bool = false
    
    var dictionaryRepresentation: [String: Any] {
        var dict: [String: Any] = [
            "email": email,
            "createdAt": createdAt
        ]
        
        if let firstName = firstName {
            dict["firstName"] = firstName
        }
        
        if let lastName = lastName {
            dict["lastName"] = lastName
        }
        
        return dict
    }
    
    static func fromDictionary(_ dict: [String: Any], id: String? = nil) -> User? {
        guard 
            let email = dict["email"] as? String,
            let createdAt = dict["createdAt"] as? Timestamp
        else {
            return nil
        }
        
        return User(
            id: id,
            email: email,
            firstName: dict["firstName"] as? String,
            lastName: dict["lastName"] as? String,
            createdAt: createdAt.dateValue()
        )
    }
}
