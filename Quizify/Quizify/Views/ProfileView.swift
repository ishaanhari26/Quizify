//
//  ProfileView.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 3/20/25.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @State private var userEmail: String = ""
    @State private var is2FAEnabled: Bool = false
    @State private var showTwoFactorSettings = false
    @State private var isLoading = true
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
                            
                            Text("Profile")
                                .font(.custom("Kiwi Maru Medium", size: 25))
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
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading profile...")
                        .font(.custom("Kiwi Maru Light", size: 16))
                        .foregroundColor(.gray)
                        .padding()
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Profile picture
                            Circle()
                                .fill(Color(hex: "#C97D60").opacity(0.2))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(Color(hex: "#C97D60"))
                                )
                                .padding(.top, 30)
                            
                            // User info
                            VStack(spacing: 5) {
                                Text(userEmail)
                                    .font(.custom("Kiwi Maru Regular", size: 18))
                                    .foregroundColor(.black)
                                
                                HStack {
                                    Image(systemName: is2FAEnabled ? "checkmark.shield.fill" : "shield")
                                        .foregroundColor(is2FAEnabled ? .green : .gray)
                                        .font(.system(size: 16))
                                    
                                    Text(is2FAEnabled ? "2FA Enabled" : "2FA Disabled")
                                        .font(.custom("Kiwi Maru Light", size: 14))
                                        .foregroundColor(is2FAEnabled ? .green : .gray)
                                }
                                .padding(.top, 5)
                            }
                            
                            // Divider
                            Rectangle()
                                .fill(Color(hex: "#EEEEEE"))
                                .frame(height: 8)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 30)
                            
                            // Settings options
                            VStack(spacing: 0) {
                                SettingsOptionView(
                                    icon: "lock.fill",
                                    title: "Security",
                                    action: {
                                        showTwoFactorSettings = true
                                    }
                                )
                                
                                Divider().padding(.leading, 50)
                                
                                SettingsOptionView(
                                    icon: "bell.fill",
                                    title: "Notifications",
                                    action: {
                                        // Handle notifications settings
                                    }
                                )
                                
                                Divider().padding(.leading, 50)
                                
                                SettingsOptionView(
                                    icon: "person.fill",
                                    title: "Account",
                                    action: {
                                        // Handle account settings
                                    }
                                )
                                
                                Divider().padding(.leading, 50)
                                
                                SettingsOptionView(
                                    icon: "questionmark.circle.fill",
                                    title: "Help & Support",
                                    action: {
                                        // Handle help and support
                                    }
                                )
                                
                                Divider().padding(.leading, 50)
                                
                                SettingsOptionView(
                                    icon: "arrow.right.square.fill",
                                    title: "Sign Out",
                                    action: {
                                        Task {
                                            do {
                                                try AuthManager.shared.signOut()
                                                // Handle navigation to login screen
                                            } catch {
                                                print(error)
                                            }
                                        }
                                    }
                                )
                            }
                            .background(Color.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                            
                            Spacer(minLength: 50)
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            isLoading = true
            
            // Get user info
            if let user = Auth.auth().currentUser {
                userEmail = user.email ?? "No email"
                is2FAEnabled = user.phoneNumber != nil
            }
            
            isLoading = false
        }
        .navigationDestination(isPresented: $showTwoFactorSettings) {
            TwoFactorSettingsView()
        }
    }
}

struct SettingsOptionView: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color(hex: "#C97D60"))
                    .font(.system(size: 18))
                    .frame(width: 30)
                
                Text(title)
                    .font(.custom("Kiwi Maru Regular", size: 16))
                    .foregroundColor(.black)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(hex: "#C97D60"))
                    .font(.system(size: 14))
            }
            .padding(.vertical, 15)
            .padding(.horizontal)
        }
    }
}


#Preview {
    ProfileView()
}
