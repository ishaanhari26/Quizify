//
//  TwoFactorSettingsView.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 3/25/25.
//

import SwiftUI
import FirebaseAuth

@MainActor
final class TwoFactorSettingsViewModel: ObservableObject {
    @Published var is2FAEnabled = false
    @Published var phoneNumber: String?
    @Published var isLoading = true
    @Published var errorMessage = ""
    
    func loadSettings() async {
        isLoading = true
        
        // Check if 2FA is enabled
        is2FAEnabled = AuthManager.shared.isPhoneNumberVerified()
        
        // Get the masked phone number if available
        phoneNumber = AuthManager.shared.getVerifiedPhoneNumber()
        
        isLoading = false
    }
    
    func disable2FA() async {
        isLoading = true
        
        do {
            // For simplicity, we'll just sign out the user
            // In a real implementation, you would want to properly unlink the phone auth provider
            try AuthManager.shared.signOut()
            is2FAEnabled = false
            phoneNumber = nil
            
            // Re-authenticate the user with just email/password
            // This is a simplified implementation
            
        } catch {
            errorMessage = "Failed to disable two-factor authentication: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct TwoFactorSettingsView: View {
    @StateObject private var viewModel = TwoFactorSettingsViewModel()
    @State private var showPhoneEntryView = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                ZStack {
                    Color(hex: "#C97D60").ignoresSafeArea(edges: .top)
                    
                    VStack {
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.white)
                                    .font(.system(size: 22))
                            }
                            .padding(.leading, 20)
                            
                            Spacer()
                            
                            Text("Two-Factor Authentication")
                                .font(.custom("Kiwi Maru Medium", size: 20))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Color.clear
                                .frame(width: 22, height: 22)
                                .padding(.trailing, 20)
                        }
                        .padding(.top, 25)
                        .padding(.bottom, 15)
                    }
                }
                .frame(height: 75)
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading settings...")
                        .font(.custom("Kiwi Maru Light", size: 16))
                        .foregroundColor(.gray)
                        .padding()
                    Spacer()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Info section
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Two-Factor Authentication (2FA)")
                                    .font(.custom("Kiwi Maru Regular", size: 20))
                                    .foregroundColor(.black)
                                
                                Text("Adding a second layer of security to your account helps prevent unauthorized access.")
                                    .font(.custom("Kiwi Maru Light", size: 16))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)
                            
                            Divider()
                            
                            // Status section
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Status")
                                    .font(.custom("Kiwi Maru Regular", size: 18))
                                    .foregroundColor(.black)
                                
                                HStack {
                                    Image(systemName: viewModel.is2FAEnabled ? "checkmark.shield.fill" : "shield")
                                        .foregroundColor(viewModel.is2FAEnabled ? Color.green : Color.gray)
                                        .font(.system(size: 24))
                                    
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(viewModel.is2FAEnabled ? "Enabled" : "Disabled")
                                            .font(.custom("Kiwi Maru Regular", size: 16))
                                            .foregroundColor(viewModel.is2FAEnabled ? Color.green : Color.gray)
                                        
                                        if let phoneNumber = viewModel.phoneNumber, viewModel.is2FAEnabled {
                                            Text("Verification number: \(phoneNumber)")
                                                .font(.custom("Kiwi Maru Light", size: 14))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if viewModel.is2FAEnabled {
                                        Button(action: {
                                            Task {
                                                await viewModel.disable2FA()
                                            }
                                        }) {
                                            Text("Disable")
                                                .font(.custom("Kiwi Maru Regular", size: 14))
                                                .foregroundColor(.red)
                                                .padding(.horizontal, 15)
                                                .padding(.vertical, 8)
                                                .background(Color.red.opacity(0.1))
                                                .cornerRadius(15)
                                        }
                                    } else {
                                        Button(action: {
                                            showPhoneEntryView = true
                                        }) {
                                            Text("Enable")
                                                .font(.custom("Kiwi Maru Regular", size: 14))
                                                .foregroundColor(Color(hex: "#C97D60"))
                                                .padding(.horizontal, 15)
                                                .padding(.vertical, 8)
                                                .background(Color(hex: "#C97D60").opacity(0.1))
                                                .cornerRadius(15)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color(hex: "#EFEFEF").opacity(0.5))
                                .cornerRadius(15)
                            }
                            .padding(.horizontal)
                            
                            Divider()
                            
                            // How it works section
                            VStack(alignment: .leading, spacing: 15) {
                                Text("How It Works")
                                    .font(.custom("Kiwi Maru Regular", size: 18))
                                    .foregroundColor(.black)
                                
                                VStack(alignment: .leading, spacing: 15) {
                                    HowItWorksItem(
                                        icon: "1.circle.fill",
                                        title: "Register your phone number",
                                        description: "We'll send a verification code to your phone."
                                    )
                                    
                                    HowItWorksItem(
                                        icon: "2.circle.fill",
                                        title: "Enter the verification code",
                                        description: "Verify your phone by entering the 6-digit code."
                                    )
                                    
                                    HowItWorksItem(
                                        icon: "3.circle.fill",
                                        title: "Login securely",
                                        description: "Next time you log in, you'll verify with a code sent to your phone."
                                    )
                                }
                                .padding()
                                .background(Color(hex: "#EFEFEF").opacity(0.5))
                                .cornerRadius(15)
                            }
                            .padding(.horizontal)
                            
                            if !viewModel.errorMessage.isEmpty {
                                Text(viewModel.errorMessage)
                                    .foregroundColor(.red)
                                    .font(.custom("Kiwi Maru Regular", size: 14))
                                    .padding(.horizontal)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Spacer(minLength: 50)
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadSettings()
            }
        }
        .sheet(isPresented: $showPhoneEntryView) {
            PhoneNumberEntryView()
                .onDisappear {
                    Task {
                        await viewModel.loadSettings()
                    }
                }
        }
    }
}

struct HowItWorksItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "#C97D60"))
                .font(.system(size: 20))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("Kiwi Maru Regular", size: 16))
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.custom("Kiwi Maru Light", size: 14))
                    .foregroundColor(.gray)
            }
        }
    }
}


#Preview {
    TwoFactorSettingsView()
}
