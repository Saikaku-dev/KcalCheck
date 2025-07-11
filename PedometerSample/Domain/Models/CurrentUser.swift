//
//  CurrentUser.swift
//  PedometerSample
//
//  Created by cmStudent on 2025/07/07.
//

import Foundation

class CurrentUser: ObservableObject {
    static let shared = CurrentUser()
    
    @Published var user: User?
    
    private init() {}
}
