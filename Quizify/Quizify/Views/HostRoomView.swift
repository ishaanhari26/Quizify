//
//  HostRoomView.swift
//  Quizify
//
//  Created for QuizRooms feature
//

import SwiftUI

struct HostRoomView: View {
    @EnvironmentObject var quizManager: QuizRoomManager
    @Environment(\.dismiss) var dismiss
    @State private var roomName: String = ""
    @State private var prompt: String = ""
    @State private var showWaitingLobby = false
    @State private var generatedRoomCode = ""
    @State private var isCreatingRoom = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // Topic suggestions for prompts
    let topicSuggestions = [
        "World History", "Science Facts", "Pop Culture", "Geography",
        "Literature", "Movies & TV", "Sports", "Technology"
    ]
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                if showWaitingLobby {
                    WaitingLobbyView()
                        .environmentObject(quizManager)
                } else {
                    roomCreationContent
                }
            }
            
            // Loading overlay
            if isCreatingRoom {
                loadingOverlay
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        }
    }
    
    // MARK: - Component Views
    
    private var headerView: some View {
        ZStack {
            Color(hex: "#C97D60").ignoresSafeArea(edges: .top)
            
            VStack {
                HStack {
                    Button(action: {
                        if showWaitingLobby {
                            // Leave room if in lobby
                            Task {
                                await quizManager.leaveRoom()
                                dismiss()
                            }
                        } else {
                            dismiss()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.system(size: 22))
                    }
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    Text(showWaitingLobby ? "Quiz Lobby" : "Host Game")
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
    
    private var roomCreationContent: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Title section
                VStack(spacing: 15) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color(hex: "#C97D60"))
                        .padding(.top, 30)
                    
                    Text("Create Your Quiz Room")
                        .font(.custom("Kiwi Maru Regular", size: 24))
                        .foregroundColor(.black)
                    
                    Text("Set up a room for up to 5 players with 4 quiz rounds")
                        .font(.custom("Kiwi Maru Light", size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                
                // Room setup form
                VStack(spacing: 20) {
                    // Room name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Room Name")
                            .font(.custom("Kiwi Maru Regular", size: 16))
                            .foregroundColor(.black)
                            .padding(.leading, 10)
                        
                        TextField("Enter room name", text: $roomName)
                            .font(.custom("Kiwi Maru Regular", size: 18))
                            .frame(height: 52)
                            .padding(.horizontal)
                            .background(Color(hex: "#CECECE").opacity(0.2))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color(hex: "#C97D60"), lineWidth: 2)
                            )
                    }
                    
                    // Quiz topic prompt
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quiz Topic")
                            .font(.custom("Kiwi Maru Regular", size: 16))
                            .foregroundColor(.black)
                            .padding(.leading, 10)
                        
                        TextEditor(text: $prompt)
                            .font(.custom("Kiwi Maru Regular", size: 16))
                            .padding()
                            .frame(minHeight: 100)
                            .background(Color(hex: "#CECECE").opacity(0.2))
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color(hex: "#C97D60"), lineWidth: 2)
                            )
                        
                        Text("Describe what you'd like the quiz questions to be about")
                            .font(.custom("Kiwi Maru Light", size: 14))
                            .foregroundColor(.gray)
                            .padding(.leading, 10)
                    }
                    
                    // Topic suggestions
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Quick Topics:")
                            .font(.custom("Kiwi Maru Regular", size: 16))
                            .foregroundColor(.black)
                            .padding(.leading, 10)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(topicSuggestions, id: \.self) { topic in
                                    Button(action: {
                                        if prompt.isEmpty {
                                            prompt = "Generate quiz questions about \(topic)"
                                        }
                                        if roomName.isEmpty {
                                            roomName = "\(topic) Quiz"
                                        }
                                    }) {
                                        Text(topic)
                                            .font(.custom("Kiwi Maru Light", size: 14))
                                            .padding(.horizontal, 15)
                                            .padding(.vertical, 8)
                                            .background(Color(hex: "#C97D60").opacity(0.2))
                                            .foregroundColor(Color(hex: "#C97D60"))
                                            .cornerRadius(20)
                                    }
                                }
                            }
                            .padding(.horizontal, 10)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Game rules info
                gameRulesSection
                
                // Create room button
                Button(action: {
                    createRoom()
                }) {
                    Text("Create Quiz Room")
                        .font(.custom("Kiwi Maru Regular", size: 18))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(canCreateRoom ? Color(hex: "#C97D60") : Color.gray.opacity(0.5))
                        .cornerRadius(20)
                        .foregroundColor(.white)
                }
                .disabled(!canCreateRoom || isCreatingRoom)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer(minLength: 50)
            }
        }
    }
    
    private var gameRulesSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Game Rules")
                .font(.custom("Kiwi Maru Regular", size: 18))
                .foregroundColor(.black)
                .padding(.horizontal, 30)
            
            VStack(spacing: 12) {
                GameRuleItem(
                    icon: "person.3.fill",
                    title: "2-5 Players",
                    description: "Need at least 2 players to start"
                )
                
                GameRuleItem(
                    icon: "clock.fill",
                    title: "4 Rounds",
                    description: "Each question has 15 seconds to answer"
                )
                
                GameRuleItem(
                    icon: "star.fill",
                    title: "Speed Scoring",
                    description: "Faster correct answers earn more points"
                )
                
                GameRuleItem(
                    icon: "trophy.fill",
                    title: "Winner Takes All",
                    description: "Highest total score wins the game"
                )
            }
            .padding(.horizontal, 30)
        }
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            VStack {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Creating quiz room...")
                    .font(.custom("Kiwi Maru Light", size: 16))
                    .foregroundColor(.white)
                    .padding(.top, 10)
                
                Text("Generating questions with AI")
                    .font(.custom("Kiwi Maru Light", size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, 5)
            }
            .padding(30)
            .background(Color(hex: "#C97D60").opacity(0.8))
            .cornerRadius(15)
        }
    }
    
    // MARK: - Computed Properties
    
    private var canCreateRoom: Bool {
        return !roomName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Functions
    
    private func createRoom() {
        guard canCreateRoom else { return }
        
        isCreatingRoom = true
        
        Task {
            do {
                let roomCode = try await quizManager.createRoom(
                    roomName: roomName.trimmingCharacters(in: .whitespacesAndNewlines),
                    prompt: prompt.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                
                generatedRoomCode = roomCode
                isCreatingRoom = false
                
                // Navigate to waiting lobby
                withAnimation {
                    showWaitingLobby = true
                }
                
            } catch {
                isCreatingRoom = false
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
}

// MARK: - Supporting Views

struct GameRuleItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "#C97D60"))
                .font(.system(size: 18))
                .frame(width: 25)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Kiwi Maru Regular", size: 16))
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.custom("Kiwi Maru Light", size: 14))
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    HostRoomView()
        .environmentObject(QuizRoomManager())
}
