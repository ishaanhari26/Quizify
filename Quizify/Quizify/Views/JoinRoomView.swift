//
//  JoinRoomView.swift
//  Quizify
//
//  Created for QuizRooms feature
//

import SwiftUI

struct JoinRoomView: View {
    @EnvironmentObject var quizManager: QuizRoomManager
    @Environment(\.dismiss) var dismiss
    @State private var roomCode: String = ""
    @State private var showWaitingLobby = false
    @State private var isJoiningRoom = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @FocusState private var isRoomCodeFocused: Bool
    
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
                    joinRoomContent
                }
            }
            
            // Loading overlay
            if isJoiningRoom {
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
            Color(hex: "#6082C9").ignoresSafeArea(edges: .top)
            
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
                    
                    Text(showWaitingLobby ? "Quiz Lobby" : "Join Game")
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
    
    private var joinRoomContent: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Title section
            VStack(spacing: 20) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "#6082C9"))
                
                Text("Join Quiz Room")
                    .font(.custom("Kiwi Maru Regular", size: 28))
                    .foregroundColor(.black)
                
                Text("Enter the 6-digit room code to join the quiz")
                    .font(.custom("Kiwi Maru Light", size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            
            // Room code input
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Room Code")
                        .font(.custom("Kiwi Maru Regular", size: 16))
                        .foregroundColor(.black)
                        .padding(.leading, 10)
                    
                    TextField("ABC123", text: $roomCode)
                        .font(.custom("Kiwi Maru Medium", size: 24))
                        .multilineTextAlignment(.center)
                        .textCase(.uppercase)
                        .autocorrectionDisabled()
                        .frame(height: 60)
                        .background(Color(hex: "#CECECE").opacity(0.2))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    isRoomCodeFocused ? Color(hex: "#6082C9") : Color(hex: "#6082C9").opacity(0.5),
                                    lineWidth: isRoomCodeFocused ? 3 : 2
                                )
                                .animation(.easeInOut(duration: 0.2), value: isRoomCodeFocused)
                        )
                        .focused($isRoomCodeFocused)
                        .onChange(of: roomCode) { newValue in
                            // Limit to 6 characters and make uppercase
                            let filtered = newValue.uppercased().filter { $0.isLetter || $0.isNumber }
                            if filtered != newValue {
                                roomCode = String(filtered.prefix(6))
                            } else if filtered.count > 6 {
                                roomCode = String(filtered.prefix(6))
                            }
                        }
                        .onSubmit {
                            if canJoinRoom {
                                joinRoom()
                            }
                        }
                }
                .padding(.horizontal, 40)
                
                // Join button
                Button(action: {
                    joinRoom()
                }) {
                    Text("Join Quiz Room")
                        .font(.custom("Kiwi Maru Regular", size: 18))
                        .frame(width: 250, height: 50)
                        .background(canJoinRoom ? Color(hex: "#6082C9") : Color.gray.opacity(0.5))
                        .cornerRadius(20)
                        .foregroundColor(.white)
                }
                .disabled(!canJoinRoom || isJoiningRoom)
                .padding(.top, 10)
            }
            
            Spacer()
            
            // Instructions
            instructionsSection
            
            Spacer()
        }
        .onAppear {
            // Auto-focus the text field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isRoomCodeFocused = true
            }
        }
    }
    
    private var instructionsSection: some View {
        VStack(spacing: 15) {
            Text("How to Join")
                .font(.custom("Kiwi Maru Regular", size: 18))
                .foregroundColor(.black)
            
            VStack(alignment: .leading, spacing: 12) {
                InstructionStep(
                    number: 1,
                    text: "Get the 6-digit room code from the host"
                )
                
                InstructionStep(
                    number: 2,
                    text: "Enter the code above"
                )
                
                InstructionStep(
                    number: 3,
                    text: "Wait for the host to start the game"
                )
                
                InstructionStep(
                    number: 4,
                    text: "Compete and have fun!"
                )
            }
        }
        .padding(.horizontal, 30)
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            VStack {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Joining quiz room...")
                    .font(.custom("Kiwi Maru Light", size: 16))
                    .foregroundColor(.white)
                    .padding(.top, 10)
            }
            .padding(30)
            .background(Color(hex: "#6082C9").opacity(0.8))
            .cornerRadius(15)
        }
    }
    
    // MARK: - Computed Properties
    
    private var canJoinRoom: Bool {
        return roomCode.count == 6
    }
    
    // MARK: - Functions
    
    private func joinRoom() {
        guard canJoinRoom else { return }
        
        isJoiningRoom = true
        
        Task {
            do {
                try await quizManager.joinRoom(roomCode: roomCode)
                
                isJoiningRoom = false
                
                // Navigate to waiting lobby
                withAnimation {
                    showWaitingLobby = true
                }
                
            } catch {
                isJoiningRoom = false
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
}

// MARK: - Supporting Views

struct InstructionStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#6082C9"))
                    .frame(width: 24, height: 24)
                
                Text("\(number)")
                    .font(.custom("Kiwi Maru Medium", size: 14))
                    .foregroundColor(.white)
            }
            
            Text(text)
                .font(.custom("Kiwi Maru Light", size: 14))
                .foregroundColor(.gray)
                .lineLimit(2)
            
            Spacer()
        }
    }
}

#Preview {
    JoinRoomView()
        .environmentObject(QuizRoomManager())
}
