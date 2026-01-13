//
//  LoginView.swift
//  InstaClone
//
//  Created by Piyush Goel on 11/12/25.
//

import SwiftUI
internal import Combine

// ============================================================================
// Login View
// ============================================================================

struct LoginView: View {

    // ViewModel for login functionality
    @StateObject private var viewModel = LoginViewModel()

    var body: some View {

        NavigationStack {
            
            ZStack {
                Color.black
                    .ignoresSafeArea()
                    .opacity(0.9)

                VStack(spacing: 20) {
                    Spacer()

                    // ------------------------------------------------------------
                    // App Title
                    // ------------------------------------------------------------
                    Text("Instagram")
                        .font(.system(size: 50, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .padding(.bottom, 20)

                    // ------------------------------------------------------------
                    // Email Input
                    // ------------------------------------------------------------
                    TextField("Email", text: $viewModel.email)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    // ------------------------------------------------------------
                    // Password Input
                    // ------------------------------------------------------------
                    SecureField("Password", text: $viewModel.password)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )

                    // ------------------------------------------------------------
                    // Error Message
                    // ------------------------------------------------------------
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // ------------------------------------------------------------
                    // Login Button
                    // ------------------------------------------------------------
                    Button(action: { viewModel.login() }) {
                        Text("Login")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .cornerRadius(5)
                            .background(
                                viewModel.isValidForm
                                ? Color.blue
                                : Color.blue.opacity(0.5)
                            )
                    }
                    // Disable button if form is invalid
                    .disabled(!viewModel.isValidForm)

                    Spacer()
                }
                .padding(.horizontal, 30)
            }
            .navigationBarBackButtonHidden(true)

            // Navigate to FeedView after login 
            .navigationDestination(isPresented: $viewModel.isLoggedIn) {
                FeedView(viewModel: viewModel)
            }
        }
    }
}

#Preview {
    LoginView()
}
