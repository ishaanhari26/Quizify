//
//  PhoneNumberEntryView.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 3/25/25.

import SwiftUI

@MainActor
final class PhoneNumberViewModel: ObservableObject {
    @Published var phoneNumber: String = ""
    @Published var isSendingCode: Bool = false
    @Published var errorMessage: String = ""
    @Published var verificationID: String = ""
    @Published var sentVerificationCode: Bool = false
    
    func sendVerificationCode() async {
        guard !phoneNumber.isEmpty else {
            errorMessage = "Please enter your phone number"
            return
        }
        
        // Basic validation - should be improved for production
        let cleanedNumber = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanedNumber.count >= 10 else {
            errorMessage = "Please enter a valid phone number"
            return
        }
        
        isSendingCode = true
        
        do {
            // Format phone number with international code if not already included
            let formattedNumber = phoneNumber.hasPrefix("+") ? phoneNumber : "+1\(phoneNumber)"
            
            // Send verification code
            verificationID = try await AuthManager.shared.startTwoFactorAuthentication(phoneNumber: formattedNumber)
            sentVerificationCode = true
        } catch {
            errorMessage = error.localizedDescription
            print("Error sending verification code: \(error)")
        }
        
        isSendingCode = false
    }
}

struct PhoneNumberEntryView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = PhoneNumberViewModel()
    @State private var showVerificationView = false
    @Binding var goToHome: Bool
    @Binding var showOnboarding: Bool
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(alignment: .center, spacing: 20) {
                // Logo and Title
                Image(.quzifyLogo)
                    .resizable()
                    .frame(width: 100, height: 100)
                    .padding(.top, 50)
                
                Text("Enable Two-Factor Authentication")
                    .font(.custom("Kiwi Maru Regular", size: 24))
                    .foregroundColor(Color(.black))
                    .multilineTextAlignment(.center)
                
                Text("Enter your phone number to receive a verification code")
                    .font(.custom("Kiwi Maru Light", size: 16))
                    .foregroundColor(Color(.gray))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                // Phone number input
                HStack {
                    Text("+1")
                        .font(.custom("Kiwi Maru Regular", size: 18))
                        .foregroundColor(.black)
                        .padding(.leading, 20)
                    
                    TextField("(123) 456-7890", text: $viewModel.phoneNumber)
                        .font(.custom("Kiwi Maru Regular", size: 18))
                        .keyboardType(.phonePad)
                        .frame(height: 52)
                        .padding(.horizontal)
                }
                .background(Color(hex: "#CECECE").opacity(0.2))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(hex: "#C97D60"), lineWidth: 3)
                )
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Send code button
                Button(action: {
                    Task {
                        await viewModel.sendVerificationCode()
                    }
                }) {
                    Text("Send Verification Code")
                        .font(.custom("Kiwi Maru Regular", size: 18))
                        .frame(width: 250, height: 43)
                        .background(Color(hex: "#C97D60"))
                        .cornerRadius(20)
                        .foregroundColor(.white)
                }
                .disabled(viewModel.isSendingCode)
                .opacity(viewModel.isSendingCode ? 0.7 : 1.0)
                .padding(.top, 20)
                
                if viewModel.isSendingCode {
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
                
                // Skip button (make optional for your app)
                Button(action: {
                    // Skip 2FA for now and go to onboarding
                    showOnboarding = true
                    dismiss()
                }) {
                    Text("Skip for now")
                        .font(.custom("Kiwi Maru Light", size: 16))
                        .foregroundColor(Color(hex: "#C97D60"))
                        .underline()
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Safety note
                Text("Your phone number will only be used for verification purposes.")
                    .font(.custom("Kiwi Maru Light", size: 12))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
            }
            .padding(.horizontal)
        }
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(isPresented: $viewModel.sentVerificationCode) {
            TwoFactorAuthView(verificationID: viewModel.verificationID, goToHome: $goToHome, showOnboarding: $showOnboarding)
        }
    }
}

// Add an initializer with a default value for goToHome and showOnboarding
extension PhoneNumberEntryView {
    init(goToHome: Binding<Bool> = .constant(false), showOnboarding: Binding<Bool> = .constant(false)) {
        self._goToHome = goToHome
        self._showOnboarding = showOnboarding
    }
}

struct PhoneNumberEntryView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneNumberEntryView()
    }
}
