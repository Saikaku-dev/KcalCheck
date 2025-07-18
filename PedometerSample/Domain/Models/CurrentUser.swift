//
//  CurrentUser.swift
//  PedometerSample
//
//  Created by cmStudent on 2025/07/07.
//

import Foundation

class CurrentUser: ObservableObject {
    static let shared = CurrentUser()
    
    @Published var user: User? {
        didSet {
            saveUserToUserDefaults()
        }
    }
    
    private init() {
        loadUserFromUserDefaults()
    }
    
    private func saveUserToUserDefaults() {
        if let user = user {
            let userData: [String: Any] = [
                "nickName": user.nickName,
                "userWeight": user.userWeight
            ]
            UserDefaults.standard.set(userData, forKey: "currentUser")
        } else {
            UserDefaults.standard.removeObject(forKey: "currentUser")
        }
    }
    
    private func loadUserFromUserDefaults() {
        if let userData = UserDefaults.standard.dictionary(forKey: "currentUser"),
           let nickName = userData["nickName"] as? String,
           let userWeight = userData["userWeight"] as? Double {
            user = User(nickName: nickName, userWeight: userWeight)
        }
    }
}
