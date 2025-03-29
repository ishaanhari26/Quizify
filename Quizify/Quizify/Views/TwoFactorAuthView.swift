//
//  TwoFactorAuthView.swift
//  Quizify
//
//  Created on 3/25/25.
//

import SwiftUI
import FirebaseAuth

@MainActor
final class TwoFactorAuthViewModel: ObservableObject {
    @Published var verificationCode: String = ""
    @Published var isVerifying: Bool = false
    @Published var errorMessage: String = ""
    @Published var isVerified: Bool = false
    
    // Store verification ID received from Firebase
    var verificationID: String
    
    init(verificationID: String) {
        self.verificationID = verificationID
    }
    
    func verifyCode() async {
        guard !verificationCode.isEmpty else {
            errorMessage = "Please enter the verification code"
            return
        }
        
        guard verificationCode.count == 6, Int(verificationCode) != nil else {
            errorMessage = "Please enter a valid 6-digit code"
            return
        }
        
        isVerifying = true
        
        do {
            let credential = PhoneAuthProvider.provider().credential(
                withVerificationID: verificationID,
                verificationCode: verificationCode
            )
            
            // Link the credential to the current user
            if let currentUser = Auth.auth().currentUser {
                do {
                    try await currentUser.link(with: credential)
                    isVerified = true
                    print("Successfully verified and linked phone number")
                } catch {
                    print("Detailed linking error: \(error)")
                    errorMessage = "Failed to link phone: \(error.localizedDescription)"
                }
            } else {
                // If there's no current user, sign in with the credential
                do {
                    try await Auth.auth().signIn(with: credential)
                    isVerified = true
                    print("Successfully signed in with phone credential")
                } catch {
                    print("Detailed sign-in error: \(error)")
                    errorMessage = "Failed to sign in: \(error.localizedDescription)"
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            print("2FA Error: \(error)")
        }
        
        isVerifying = false
    }
}

struct TwoFactorAuthView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: TwoFactorAuthViewModel
    @Binding var goToHome: Bool
    @Binding var showOnboarding: Bool
    
    init(verificationID: String, goToHome: Binding<Bool> = .constant(false), showOnboarding: Binding<Bool> = .constant(false)) {
        _viewModel = StateObject(wrappedValue: TwoFactorAuthViewModel(verificationID: verificationID))
        _goToHome = goToHome
        _showOnboarding = showOnboarding
    }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(alignment: .center, spacing: 20) {
                // Logo and Title
                Image(.quzifyLogo)
                    .resizable()
                    .frame(width: 100, height: 100)
                    .padding(.top, 50)
                
                Text("Two-Factor Authentication")
                    .font(.custom("Kiwi Maru Regular", size: 24))
                    .foregroundColor(Color(.black))
                    .multilineTextAlignment(.center)
                
                Text("Enter the 6-digit verification code sent to your phone")
                    .font(.custom("Kiwi Maru Light", size: 16))
                    .foregroundColor(Color(.gray))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                // Verification code input
                TextField("000000", text: $viewModel.verificationCode)
                    .font(.custom("Kiwi Maru Regular", size: 24))
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .frame(width: 200, height: 52)
                    .padding(.horizontal)
                    .background(Color(hex: "#CECECE").opacity(0.2))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(hex: "#C97D60"), lineWidth: 3)
                    )
                    .padding(.top, 20)
                
                // Verify button
                Button(action: {
                    Task {
                        await viewModel.verifyCode()
                        
                        if viewModel.isVerified {
                            // Check if profile exists before routing
                            Task {
                                if await AuthManager.shared.userHasCompletedProfile() {
                                    // If user has profile, go to home
                                    goToHome = true
                                    dismiss()
                                } else {
                                    // Otherwise, go to onboarding
                                    showOnboarding = true
                                    dismiss()
                                }
                            }
                        }
                    }
                }) {
                    Text("Verify")
                        .font(.custom("Kiwi Maru Regular", size: 18))
                        .frame(width: 233, height: 43)
                        .background(Color(hex: "#C97D60"))
                        .cornerRadius(20)
                        .foregroundColor(.white)
                }
                .disabled(viewModel.isVerifying)
                .opacity(viewModel.isVerifying ? 0.7 : 1.0)
                .padding(.top, 20)
                
                if viewModel.isVerifying {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                }
                
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .font(.custom("Kiwi Maru Regular", size: 14))
                        .padding(.horizontal, 30)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Resend code option
                Button(action: {
                    // This would trigger resending the code
                    // We'll implement this in the AuthManager
                }) {
                    Text("Didn't receive a code? Resend")
                        .font(.custom("Kiwi Maru Light", size: 16))
                        .foregroundColor(Color(hex: "#C97D60"))
                        .underline()
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal)
        }
    }
}



struct TwoFactorAuthView_Previews: PreviewProvider {
    static var previews: some View {
        TwoFactorAuthView(verificationID: "preview-verification-id",
                          goToHome: .constant(false),
                          showOnboarding: .constant(false))
    }
}
