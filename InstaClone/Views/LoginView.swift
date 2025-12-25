//
//  LoginView.swift
//  InstaClone
//
//  Created by Piyush Goel on 11/12/25.
//

import SwiftUI
internal import Combine

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    
    var body: some View {
        
        NavigationStack {
            
            ZStack {
                Color.black.ignoresSafeArea()
                    .opacity(0.9)
                
                VStack(spacing: 20) {
                    Spacer()
                    
                    Text("Instagram")
                        .font(.system(size: 50, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .padding(.bottom, 20)
                    
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
                    
                    SecureField("Password", text: $viewModel.password)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Button(action: {viewModel.login()}) {
                        Text("Login")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .cornerRadius(5)
                            .background( viewModel.isValidForm ? .blue : .blue.opacity(0.5) )
                    }
                    .disabled(!viewModel.isValidForm)
                    
                    Spacer()
                }
                .padding(.horizontal, 30)
            }
            .navigationBarBackButtonHidden(true)
            .navigationDestination(isPresented: $viewModel.isLoggedIn) {
                FeedView(viewModel: viewModel)
            }
        }
    }
}

#Preview {
    LoginView()
}
