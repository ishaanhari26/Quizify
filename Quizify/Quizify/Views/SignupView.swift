//
//  SignupView.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 11/14/24.
//

import SwiftUI
import FirebaseFirestore

@MainActor
final class SignInEmailViewModel : ObservableObject {
    
    @Published var email = ""
    @Published var password = ""
    @Published var username = ""
    @Published var isAuthenticated = false
    @Published var errorMessage = ""
    @Published var shouldShowTwoFactor = false
    
    init() {
        
    }
    
    func signIn() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password cannot be empty"
            return
        }
        
        guard !username.isEmpty else {
            errorMessage = "Please enter a username"
            return
        }
        
        // Check if username contains only letters, numbers, and underscores
        let usernameRegex = "^[a-zA-Z0-9_]+$"
        if let regex = try? NSRegularExpression(pattern: usernameRegex) {
            let range = NSRange(location: 0, length: username.utf16.count)
            if regex.firstMatch(in: username, options: [], range: range) == nil {
                errorMessage = "Username can only contain letters, numbers, and underscores"
                return
            }
        }
        
        Task {
            do {
                // First, check if the username is already taken
                if try await isUsernameTaken(username: username) {
                    errorMessage = "This username is already taken"
                    return
                }
                
                let returnedUserData = try await AuthManager.shared.createUser(email: email, password: password)
                
                // Save the username to Firestore
                try await saveUserProfile(userId: returnedUserData.uid)
                
                // After successful signup, prompt for 2FA setup
                isAuthenticated = true
                shouldShowTwoFactor = true  // Set this to true to trigger 2FA setup
                
                print("Success")
                print(returnedUserData)
            } catch {
                isAuthenticated = false
                errorMessage = error.localizedDescription
                print("Error: \(error)")
            }
        }
    }
    
    private func isUsernameTaken(username: String) async throws -> Bool {
        let db = Firestore.firestore()
        
        let snapshot = try await db.collection("Users")
            .whereField("username", isEqualTo: username.lowercased())
            .getDocuments()
        
        return !snapshot.documents.isEmpty
    }
    
    private func saveUserProfile(userId: String) async throws {
        let db = Firestore.firestore()
        let userRef = db.collection("Users").document(userId)
        
        let userData: [String: Any] = [
            "username": username.lowercased(),
            "displayName": username,
            "email": email,
            "setCount": 0,
            "currentStreak": 0,
            "maxStreak": 0,
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await userRef.setData(userData)
    }
}

struct SignupView: View {
    
    @StateObject private var viewModel = SignInEmailViewModel()
    
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @FocusState private var isUsernameFocused: Bool
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
                Spacer().frame(height: 25)
                
                Image(.quzifyLogo)
                    .resizable()
                    .frame(width: 125, height: 120)
                
                Spacer().frame(height: 10)
                
                Text("Sign Up")
                    .font(.custom("Kiwi Maru Regular", size: 30))
                
                VStack(spacing: 20){
                    // Username field (New)
                    TextField("Username", text: $viewModel.username)
                        .textInputAutocapitalization(.never)
                        .font(.custom("Kiwi Maru Regular", size: 18))
                        .frame(width: 297, height: 52)
                        .padding(.horizontal)
                        .background(Color(hex: "#CECECE").opacity(0.2))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(hex: "#C97D60"),
                                        lineWidth: isUsernameFocused ? 7 : 3)
                                .animation(.easeInOut(duration: 0.2), value: isUsernameFocused)
                        )
                        .focused($isUsernameFocused)
                    
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
                .padding(.top, 25)
                
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .font(.custom("Kiwi Maru Regular", size: 14))
                        .padding(.top, 10)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .ignoresSafeArea(.keyboard)
        .frame(maxHeight: 650)
        .sheet(isPresented: $viewModel.shouldShowTwoFactor) {
            PhoneNumberEntryView(goToHome: $goToHome)
        }
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
