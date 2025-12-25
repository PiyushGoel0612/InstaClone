//
//  LoginViewModel.swift
//  InstaClone
//
//  Created by Piyush Goel on 22/12/25.
//

import Foundation
internal import Combine

// ============================================================================
// Login View Models
// ============================================================================

class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoggedIn = false
    @Published var errorMessage: String? = nil
    
    init() {
        checkLoginState()
    }
    
    func checkLoginState() {
        isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
    }
    
    var isValidForm: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    private var validEmail = "user@example.com"
    private var validPassword = "password123"
    
    func login() {
        if (email == validEmail && password == validPassword) {
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            UserDefaults.standard.set(email, forKey: "userEmail")
            isLoggedIn = true
            errorMessage = nil
        }
        else {
            errorMessage = "Invalid Credentials"
        }
    }
    
    func logout() {
        email = ""
        password = ""
        isLoggedIn = false
        errorMessage = nil
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "userEmail")
    }
    
}

