//
//  QuizRoomsMenuView.swift
//  Quizify
//
//  Created for QuizRooms feature
//

import SwiftUI

struct QuizRoomsMenuView: View {
    @StateObject private var quizManager = QuizRoomManager()
    @Environment(\.dismiss) var dismiss
    @State private var showHostView = false
    @State private var showJoinView = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                ScrollView {
                    VStack(spacing: 30) {
                        // Logo and title
                        VStack(spacing: 20) {
                            Image(.quzifyLogo)
                                .resizable()
                                .frame(width: 100, height: 100)
                                .padding(.top, 30)
                            
                            Text("QuizRooms")
                                .font(.custom("Kiwi Maru Medium", size: 32))
                                .foregroundColor(Color(hex: "#C97D60"))
                            
                            Text("Compete with friends in real-time quiz battles!")
                                .font(.custom("Kiwi Maru Light", size: 16))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        
                        // Main action buttons
                        VStack(spacing: 20) {
                            // Host Game Button
                            Button(action: {
                                showHostView = true
                            }) {
                                QuizActionCard(
                                    title: "Host Game",
                                    icon: "crown.fill",
                                    description: "Create a quiz room and invite friends",
                                    color: Color(hex: "#C97D60"),
                                    isLarge: true
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Join Game Button
                            Button(action: {
                                showJoinView = true
                            }) {
                                QuizActionCard(
                                    title: "Join Game",
                                    icon: "person.3.fill",
                                    description: "Enter a room code to join a quiz",
                                    color: Color(hex: "#6082C9"),
                                    isLarge: true
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 20)
                        
                        // How it works section
                        howItWorksSection
                        
                        // Recent rooms (if any)
                        // This would be implemented later with user history
                        
                        Spacer(minLength: 50)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(isPresented: $showHostView) {
            HostRoomView()
                .environmentObject(quizManager)
        }
        .fullScreenCover(isPresented: $showJoinView) {
            JoinRoomView()
                .environmentObject(quizManager)
        }
    }
    
    // MARK: - Component Views
    
    private var headerView: some View {
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
                    
                    Text("QuizRooms")
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
    }
    
    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("How It Works")
                .font(.custom("Kiwi Maru Regular", size: 22))
                .foregroundColor(.black)
                .padding(.horizontal, 30)
            
            VStack(spacing: 15) {
                HowItWorksStep(
                    stepNumber: 1,
                    title: "Create or Join",
                    description: "Host a room with your topic or join with a room code"
                )
                
                HowItWorksStep(
                    stepNumber: 2,
                    title: "Wait for Players",
                    description: "Up to 5 players can join each quiz room"
                )
                
                HowItWorksStep(
                    stepNumber: 3,
                    title: "Answer Questions",
                    description: "4 rounds of questions, 15 seconds each"
                )
                
                HowItWorksStep(
                    stepNumber: 4,
                    title: "Compete for Points",
                    description: "Faster correct answers earn more points!"
                )
            }
            .padding(.horizontal, 30)
        }
    }
}

// MARK: - Supporting Views

struct QuizActionCard: View {
    let title: String
    let icon: String
    let description: String
    let color: Color
    let isLarge: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: isLarge ? 70 : 50, height: isLarge ? 70 : 50)
                
                Image(systemName: icon)
                    .font(.system(size: isLarge ? 30 : 20))
                    .foregroundColor(color)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.custom("Kiwi Maru Regular", size: isLarge ? 20 : 16))
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.custom("Kiwi Maru Light", size: isLarge ? 14 : 12))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Arrow indicator
            Image(systemName: "chevron.right")
                .foregroundColor(color)
                .font(.system(size: 18))
        }
        .padding(.vertical, isLarge ? 25 : 15)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: color.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct HowItWorksStep: View {
    let stepNumber: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            // Step number
            ZStack {
                Circle()
                    .fill(Color(hex: "#C97D60"))
                    .frame(width: 30, height: 30)
                
                Text("\(stepNumber)")
                    .font(.custom("Kiwi Maru Medium", size: 16))
                    .foregroundColor(.white)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.custom("Kiwi Maru Regular", size: 16))
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.custom("Kiwi Maru Light", size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.vertical, 5)
    }
}

#Preview {
    QuizRoomsMenuView()
}
