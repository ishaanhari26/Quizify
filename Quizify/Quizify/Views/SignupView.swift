//
//  SignupView.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 11/14/24.
//

import SwiftUI
import FirebaseFirestore

import GoogleSignIn
import GoogleSignInSwift

@MainActor
final class SignInEmailViewModel : ObservableObject {
    
    @Published var email = ""
    @Published var password = ""
    @Published var isAuthenticated = false
    @Published var errorMessage = ""
    @Published var shouldShowTwoFactor = false
    @Published var isTwoFactorEnabled = false
    @Published var shouldShowOnboarding = false
    
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
    
    // Add this method to your SignupEmailViewModel class
    func googleAuth() async throws {
        guard let topVC = Utilities.shared.topViewController() else {
            throw URLError(.cannotFindHost)
        }
        
        let gidResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)
        
        guard let idToken = gidResult.user.idToken?.tokenString else {
            throw URLError(.badServerResponse)
        }
        
        let accessToken = gidResult.user.accessToken.tokenString
        let tokens = GoogleSignInResultModel(idToken: idToken, accessToken: accessToken)
        
        do {
            try await AuthManager.shared.signInWithGoogle(tokens: tokens)
            
            // Check if 2FA is enabled for this user
            if AuthManager.shared.isPhoneNumberVerified() {
                // User has already verified their phone number
                isAuthenticated = true
                isTwoFactorEnabled = true
                print("Google signup successful with 2FA")
            } else {
                // User doesn't have 2FA set up yet - prompt them to set it up
                isAuthenticated = true
                shouldShowTwoFactor = true
                print("Google signup successful but needs 2FA setup")
            }
        } catch {
            isAuthenticated = false
            errorMessage = error.localizedDescription
            print("Error: \(error)")
        }
    }

}

struct SignupView: View {
    
    @StateObject private var viewModel = SignInEmailViewModel()
    
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @FocusState private var isEmailFocused: Bool
    @FocusState private var isPasswordFocused: Bool
    @Binding var goToHome: Bool
    @State private var showTwoFactorSetup = false
    @State private var showOnboarding = false
    @State private var shouldDismissView = false
    
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
                            // Don't go to home yet, proceed to onboarding after 2FA
                            viewModel.shouldShowOnboarding = true
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
                
                // Add this after your signup button and before any existing Spacer()
                Spacer().frame(height: 25)

                HStack{
                    Rectangle()
                        .frame(width: 135, height: 1)
                        .foregroundColor(.black)
                    
                    Text("or")
                        .font(.custom("Kiwi Maru Regular", size: 20))
                    
                    Rectangle()
                        .frame(width: 135, height: 1)
                        .foregroundColor(.black)
                }

                Button(action: {
                    Task {
                        try await viewModel.googleAuth()
                        
                        if viewModel.isAuthenticated {
                            if viewModel.shouldShowOnboarding {
                                showOnboarding = true
                            } else if viewModel.shouldShowTwoFactor {
                                showTwoFactorSetup = true
                            } else if viewModel.isTwoFactorEnabled {
                                goToHome = true
                                dismiss()
                            } else {
                                goToHome = true
                                dismiss()
                            }
                        }
                    }
                }) {
                    Image(.googleSymbol)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .background(Color(hex: "#D9D9D9"))
                        .modifier(CircularImageModifier())
                }
                
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
            PhoneNumberEntryView(goToHome: .constant(false), showOnboarding: $showOnboarding)
                .onDisappear {
                    if showOnboarding {
                        // Check if user profile exists before showing onboarding
                        Task {
                            if let userID = AuthManager.shared.getUserID() {
                                let db = Firestore.firestore()
                                do {
                                    let document = try await db.collection("Users").document(userID).getDocument()
                                    if let data = document.data(),
                                       let username = data["username"] as? String,
                                       !username.isEmpty,
                                       let displayName = data["displayName"] as? String,
                                       !displayName.isEmpty {
                                        
                                        // User has profile, skip onboarding
                                        viewModel.shouldShowOnboarding = false
                                        goToHome = true
                                    } else {
                                        // User needs onboarding
                                        viewModel.shouldShowOnboarding = true
                                    }
                                } catch {
                                    // On error, show onboarding
                                    viewModel.shouldShowOnboarding = true
                                }
                            } else {
                                viewModel.shouldShowOnboarding = true
                            }
                        }
                    }
                }
        }
        .sheet(isPresented: $viewModel.shouldShowTwoFactor) {
            PhoneNumberEntryView(goToHome: .constant(false), showOnboarding: $showOnboarding)
                .onDisappear {
                    // Check if we need to dismiss this view (i.e., if goToHome is true)
                    if goToHome {
                        dismiss()
                    }
                    
                    if showOnboarding {
                        // Check if user profile exists before showing onboarding
                        Task {
                            if let userID = AuthManager.shared.getUserID() {
                                let db = Firestore.firestore()
                                do {
                                    let document = try await db.collection("Users").document(userID).getDocument()
                                    if let data = document.data(),
                                       let username = data["username"] as? String,
                                       !username.isEmpty,
                                       let displayName = data["displayName"] as? String,
                                       !displayName.isEmpty {
                                        
                                        // User has profile, skip onboarding
                                        viewModel.shouldShowOnboarding = false
                                        goToHome = true
                                        // Dismiss this view also
                                        dismiss()
                                    } else {
                                        // User needs onboarding
                                        viewModel.shouldShowOnboarding = true
                                    }
                                } catch {
                                    // On error, show onboarding
                                    viewModel.shouldShowOnboarding = true
                                }
                            } else {
                                viewModel.shouldShowOnboarding = true
                            }
                        }
                    }
                }
        }
        
        // And add this to watch for changes to shouldDismissView:
        .onChange(of: shouldDismissView) { newValue in
            if newValue {
                // Dismiss this view
                dismiss()
            }
        }// Add these @State variables to your SignupView

        // Add these fullScreenCover modifiers at the end of your SignupView body
        .fullScreenCover(isPresented: $showTwoFactorSetup) {
            PhoneNumberEntryView(goToHome: $goToHome, showOnboarding: $showOnboarding)
                .onDisappear {
                    if goToHome {
                        dismiss()
                    }
                }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(goToHome: $goToHome)
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
