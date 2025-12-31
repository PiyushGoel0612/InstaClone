//
//  LoginViewModel.swift
//  InstaClone
//
//  Created by Piyush Goel on 22/12/25.
//

import Foundation
internal import Combine

// ============================================================================
// Login View Model
// ============================================================================

// ViewModel responsible for handling login state and validation logic
class LoginViewModel: ObservableObject {

    // User input fields
    @Published var email: String = ""
    @Published var password: String = ""

    // Authentication state
    @Published var isLoggedIn = false

    // Error message shown on invalid login
    @Published var errorMessage: String? = nil

    // Initialize ViewModel and restore login state if present
    init() {
        checkLoginState()
    }

    // Checks persisted login status from UserDefaults
    func checkLoginState() {
        isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
    }

    // Validates whether the login form can be submitted
    var isValidForm: Bool {
        !email.isEmpty && !password.isEmpty
    }

    // Hardcoded credentials (used for demo / prototype purposes)
    private var validEmail = "user@example.com"
    private var validPassword = "password123"

    // Attempts login by validating credentials
    func login() {

        // Check entered credentials against valid ones
        if email == validEmail && password == validPassword {

            // Persist login state
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            UserDefaults.standard.set(email, forKey: "userEmail")

            // Update UI state
            isLoggedIn = true
            errorMessage = nil

        } else {
            // Show error message on failure
            errorMessage = "Invalid Credentials"
        }
    }

    // Logs out the user and clears persisted data
    func logout() {

        // Reset local state
        email = ""
        password = ""
        isLoggedIn = false
        errorMessage = nil

        // Clear persisted login data
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "userEmail")
    }
}
