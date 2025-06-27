//
//  WaitingLobbyView.swift
//  Quizify
//
//  Created for QuizRooms feature
//

import SwiftUI

struct WaitingLobbyView: View {
    @EnvironmentObject var quizManager: QuizRoomManager
    @State private var showGameView = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Room info section
            roomInfoSection
            
            // Players list
            playersSection
            
            Spacer()
            
            // Bottom controls
            bottomControlsSection
        }
        .fullScreenCover(isPresented: $showGameView) {
            ActiveQuizView()
                .environmentObject(quizManager)
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        }
        .onChange(of: quizManager.currentRoom?.status) { status in
            if status == .active {
                showGameView = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Refresh room state when app becomes active
            // This helps with real-time sync issues
        }
    }
    
    // MARK: - Component Views
    
    private var roomInfoSection: some View {
        VStack(spacing: 15) {
            // Room name and code
            VStack(spacing: 8) {
                Text(quizManager.currentRoom?.roomName ?? "Quiz Room")
                    .font(.custom("Kiwi Maru Regular", size: 24))
                    .foregroundColor(.black)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                if let roomCode = quizManager.currentRoom?.roomCode {
                    HStack(spacing: 10) {
                        Text("Room Code:")
                            .font(.custom("Kiwi Maru Light", size: 16))
                            .foregroundColor(.gray)
                        
                        Text(roomCode)
                            .font(.custom("Kiwi Maru Medium", size: 20))
                            .foregroundColor(Color(hex: "#C97D60"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(hex: "#C97D60").opacity(0.1))
                            .cornerRadius(10)
                    }
                }
            }
            
            // Game info
            gameInfoCards
            
            // Quiz topic
            if let prompt = quizManager.currentRoom?.prompt {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quiz Topic:")
                        .font(.custom("Kiwi Maru Regular", size: 16))
                        .foregroundColor(.gray)
                    
                    Text(prompt)
                        .font(.custom("Kiwi Maru Light", size: 14))
                        .foregroundColor(.black)
                        .padding(12)
                        .background(Color(hex: "#EFEFEF").opacity(0.5))
                        .cornerRadius(12)
                        .lineLimit(3)
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 20)
    }
    
    private var gameInfoCards: some View {
        HStack(spacing: 15) {
            InfoCard(
                icon: "person.3.fill",
                title: "\(quizManager.players.count)/5",
                subtitle: "Players",
                color: Color(hex: "#6082C9")
            )
            
            InfoCard(
                icon: "questionmark.circle.fill",
                title: "4",
                subtitle: "Questions",
                color: Color(hex: "#C97D60")
            )
            
            InfoCard(
                icon: "clock.fill",
                title: "15s",
                subtitle: "Per Question",
                color: Color(hex: "#60C9A7")
            )
        }
        .padding(.horizontal, 20)
    }
    
    private var playersSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Players")
                    .font(.custom("Kiwi Maru Regular", size: 20))
                    .foregroundColor(.black)
                
                Spacer()
                
                Text("\(quizManager.players.count) joined")
                    .font(.custom("Kiwi Maru Light", size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(quizManager.players) { player in
                        PlayerRow(player: player)
                    }
                    
                    // Empty slots
                    let emptySlots = max(0, 5 - quizManager.players.count)
                    ForEach(0..<emptySlots, id: \.self) { _ in
                        EmptyPlayerSlot()
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 20)
    }
    
    private var bottomControlsSection: some View {
        VStack(spacing: 15) {
            // Connection status
            ConnectionStatusView(status: quizManager.connectionStatus)
            
            // Host controls or waiting message
            if quizManager.isHost() {
                hostControls
            } else {
                waitingMessage
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }
    
    private var hostControls: some View {
        VStack(spacing: 15) {
            // Start game button
            Button(action: {
                startGame()
            }) {
                HStack {
                    Image(systemName: "play.fill")
                        .font(.system(size: 16))
                    
                    Text("Start Quiz")
                        .font(.custom("Kiwi Maru Regular", size: 18))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(quizManager.canStartGame() ? Color(hex: "#C97D60") : Color.gray.opacity(0.5))
                .cornerRadius(20)
                .foregroundColor(.white)
            }
            .disabled(!quizManager.canStartGame())
            
            // Requirements text
            if !quizManager.canStartGame() {
                Text("Need at least 2 players to start")
                    .font(.custom("Kiwi Maru Light", size: 14))
                    .foregroundColor(.gray)
            }
            
            // Share room code button
            Button(action: {
                shareRoomCode()
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                    
                    Text("Share Room Code")
                        .font(.custom("Kiwi Maru Regular", size: 16))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 45)
                .background(Color(hex: "#6082C9").opacity(0.2))
                .cornerRadius(20)
                .foregroundColor(Color(hex: "#6082C9"))
            }
        }
    }
    
    private var waitingMessage: some View {
        VStack(spacing: 10) {
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                
                Text("Waiting for host to start the game...")
                    .font(.custom("Kiwi Maru Light", size: 16))
                    .foregroundColor(.gray)
            }
            
            Text("Share the room code with friends to join!")
                .font(.custom("Kiwi Maru Light", size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Functions
    
    private func startGame() {
        Task {
            do {
                try await quizManager.startGame()
            } catch {
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
    
    private func shareRoomCode() {
        guard let roomCode = quizManager.currentRoom?.roomCode,
              let roomName = quizManager.currentRoom?.roomName else { return }
        
        let shareText = "Join my QuizRooms game! \n\nRoom: \(roomName)\nCode: \(roomCode)\n\nOpen Quizify and enter this code to join the quiz!"
        
        let activityController = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityController, animated: true)
        }
    }
}

// MARK: - Supporting Views

struct InfoCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(title)
                .font(.custom("Kiwi Maru Medium", size: 18))
                .foregroundColor(.black)
            
            Text(subtitle)
                .font(.custom("Kiwi Maru Light", size: 12))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(color.opacity(0.1))
        .cornerRadius(15)
    }
}

struct PlayerRow: View {
    let player: QuizPlayer
    
    var body: some View {
        HStack(spacing: 15) {
            // Player avatar
            ZStack {
                Circle()
                    .fill(Color(hex: "#C97D60").opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Text(String(player.username.prefix(1)).uppercased())
                    .font(.custom("Kiwi Maru Medium", size: 18))
                    .foregroundColor(Color(hex: "#C97D60"))
            }
            
            // Player info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(player.displayName)
                        .font(.custom("Kiwi Maru Regular", size: 16))
                        .foregroundColor(.black)
                    
                    if player.isHost {
                        Image(systemName: "crown.fill")
                            .foregroundColor(Color(hex: "#C97D60"))
                            .font(.system(size: 14))
                    }
                }
                
                Text("@\(player.username)")
                    .font(.custom("Kiwi Maru Light", size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Connection status
            Circle()
                .fill(player.isConnected ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

struct EmptyPlayerSlot: View {
    var body: some View {
        HStack(spacing: 15) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                )
            
            Text("Waiting for player...")
                .font(.custom("Kiwi Maru Light", size: 16))
                .foregroundColor(.gray)
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ConnectionStatusView: View {
    let status: QuizRoomManager.ConnectionStatus
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.custom("Kiwi Maru Light", size: 12))
                .foregroundColor(.gray)
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .connected:
            return .green
        case .disconnected:
            return .red
        case .reconnecting:
            return .orange
        }
    }
    
    private var statusText: String {
        switch status {
        case .connected:
            return "Connected"
        case .disconnected:
            return "Disconnected"
        case .reconnecting:
            return "Reconnecting..."
        }
    }
}

#Preview {
    WaitingLobbyView()
        .environmentObject(QuizRoomManager())
}
