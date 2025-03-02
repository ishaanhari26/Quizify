//
//  SignupView.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 11/14/24.
//

import SwiftUI


@MainActor
final class SignInEmailViewModel : ObservableObject {
    
    @Published var email = ""
    @Published var password = ""
    @Published var isAuthenticated = false
    @Published var errorMessage = ""
    
    init() {
        
    }
    
    func signIn() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password cannot be empty"
            return
        }
        
        Task {
            do {
                let returnedUserData = try await AuthManager.shared.createUser(email: email, password: password)
                isAuthenticated = true
                print("Success")
                print(returnedUserData)
            } catch {
                isAuthenticated = false
                errorMessage = error.localizedDescription
                print("Error: \(error)")
            }
        }
    }
}

struct SignupView: View {
    
    @StateObject private var viewModel = SignInEmailViewModel()
    
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @FocusState private var isNameFocused: Bool
    @FocusState private var isEmailFocused: Bool
    @FocusState private var isPasswordFocused: Bool
    @Binding var goToHome: Bool
    
    var body: some View {
        ZStack {
            Image("Flipped Background")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .offset(y: 35)
                .clipped()
            
            VStack(alignment: .center) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.up")
                        .foregroundColor(.gray)
                        .font(.system(size: 30))
                }
                .padding(.top, 80)
                
                // Title and Logo
                Spacer().frame(height: 40)
                
                Image(.quzifyLogo)
                    .resizable()
                    .frame(width: 125, height: 120)
                
                Spacer().frame(height: 20)
                
                Text("Sign Up")
                    .font(.custom("Kiwi Maru Regular", size: 30))
                
                VStack(spacing: 30){
                    TextField("Email", text: $viewModel.email)
                        .textInputAutocapitalization(.never)
                        .font(.custom("Kiwi Maru Regular", size: 18))
                        .frame(width: 297, height: 52)
                        .padding(.horizontal)
                        .background(Color(hex: "#CECECE").opacity(0.2))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(hex: "#C97D60"),
                                        lineWidth: isEmailFocused ? 7 : 3)
                                .animation(.easeInOut(duration: 0.2), value: isEmailFocused)
                        )
                        .focused($isEmailFocused)
                    
                    SecureField("Password", text: $viewModel.password)
                        .font(.custom("Kiwi Maru Regular", size: 18))
                        .frame(width: 297, height: 52)
                        .padding(.horizontal)
                        .background(Color(hex: "#CECECE").opacity(0.2))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(hex: "#C97D60"),
                                        lineWidth: isPasswordFocused ? 7 : 3)
                                .animation(.easeInOut(duration: 0.2), value: isPasswordFocused)
                        )
                        .focused($isPasswordFocused)
                }
                
                Button {
                    Task {
                        viewModel.signIn()
                        // Wait a bit for the sign-in process to complete
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        if viewModel.isAuthenticated {
                            goToHome = true
                            dismiss()
                        }
                    }
                } label: {
                    Text("Create Account")
                        .font(.custom("Kiwi Maru Regular", size: 18))
                        .frame(width: 233, height: 43)
                        .background(Color(hex: "#C97D60"))
                        .cornerRadius(20)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 35)
                
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .font(.custom("Kiwi Maru Regular", size: 14))
                        .padding(.top, 10)
                }
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .ignoresSafeArea(.keyboard)
        .frame(maxHeight: 650)
    }
}

// Add an initializer with a default value for goToHome
extension SignupView {
    init(goToHome: Binding<Bool> = .constant(false)) {
        self._goToHome = goToHome
    }
}

#Preview {
    SignupView()
}
