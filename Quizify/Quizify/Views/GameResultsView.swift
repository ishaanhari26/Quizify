//
//  GameResultsView.swift
//  Quizify
//
//  Created for QuizRooms feature
//

import SwiftUI

struct GameResultsView: View {
    @EnvironmentObject var quizManager: QuizRoomManager
    @Environment(\.dismiss) var dismiss
    @State private var showCelebration = false
    @State private var animateResults = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Results content
                ScrollView {
                    VStack(spacing: 25) {
                        // Game completed message
                        gameCompletedSection
                        
                        // Winner announcement
                        if let winner = topPlayer {
                            winnerSection(winner: winner)
                        }
                        
                        // Final leaderboard
                        leaderboardSection
                        
                        // Game stats
                        gameStatsSection
                        
                        // Action buttons
                        actionButtonsSection
                        
                        Spacer(minLength: 50)
                    }
                }
            }
            
            // Celebration overlay
            if showCelebration {
                celebrationOverlay
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Start animations
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    animateResults = true
                }
            }
            
            // Show celebration for winner
            if isCurrentPlayerWinner {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showCelebration = true
                    
                    // Auto-hide celebration
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation {
                            showCelebration = false
                        }
                    }
                }
            }
            
            // Update achievements
            updateAchievements()
        }
    }
    
    // MARK: - Component Views
    
    private var headerView: some View {
        ZStack {
            Color(hex: "#C97D60").ignoresSafeArea(edges: .top)
            
            VStack {
                HStack {
                    Button(action: {
                        Task {
                            await quizManager.leaveRoom()
                            dismiss()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.system(size: 22))
                    }
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    Text("Game Results")
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
    
    private var gameCompletedSection: some View {
        VStack(spacing: 15) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 50))
                .foregroundColor(Color(hex: "#C97D60"))
                .padding(.top, 20)
            
            Text("Quiz Complete!")
                .font(.custom("Kiwi Maru Medium", size: 28))
                .foregroundColor(.black)
            
            if let room = quizManager.currentRoom {
                Text(room.roomName)
                    .font(.custom("Kiwi Maru Light", size: 16))
                    .foregroundColor(.gray)
            }
        }
        .scaleEffect(animateResults ? 1.0 : 0.8)
        .opacity(animateResults ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateResults)
    }
    
    private func winnerSection(winner: QuizPlayer) -> some View {
        VStack(spacing: 15) {
            // Trophy icon
            Image(systemName: "trophy.fill")
                .font(.system(size: 40))
                .foregroundColor(.yellow)
                .padding(.bottom, 10)
            
            // Winner announcement
            Text("🎉 Winner! 🎉")
                .font(.custom("Kiwi Maru Medium", size: 24))
                .foregroundColor(Color(hex: "#C97D60"))
            
            // Winner card
            VStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color(hex: "#C97D60").opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Text(String(winner.username.prefix(1)).uppercased())
                        .font(.custom("Kiwi Maru Medium", size: 32))
                        .foregroundColor(Color(hex: "#C97D60"))
                }
                
                // Name
                Text(winner.displayName)
                    .font(.custom("Kiwi Maru Regular", size: 20))
                    .foregroundColor(.black)
                
                Text("@\(winner.username)")
                    .font(.custom("Kiwi Maru Light", size: 14))
                    .foregroundColor(.gray)
                
                // Final score
                Text("\(winner.score) points")
                    .font(.custom("Kiwi Maru Medium", size: 18))
                    .foregroundColor(Color(hex: "#C97D60"))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#C97D60").opacity(0.1))
                    .cornerRadius(15)
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal, 20)
        .scaleEffect(animateResults ? 1.0 : 0.9)
        .opacity(animateResults ? 1.0 : 0.0)
        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2), value: animateResults)
    }
    
    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Final Leaderboard")
                .font(.custom("Kiwi Maru Regular", size: 20))
                .foregroundColor(.black)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(Array(quizManager.players.enumerated()), id: \.element.id) { index, player in
                    LeaderboardRow(
                        player: player,
                        rank: index + 1,
                        isCurrentPlayer: player.id == quizManager.currentPlayer?.id
                    )
                    .scaleEffect(animateResults ? 1.0 : 0.95)
                    .opacity(animateResults ? 1.0 : 0.0)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.8)
                        .delay(Double(index) * 0.1 + 0.4),
                        value: animateResults
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var gameStatsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Game Stats")
                .font(.custom("Kiwi Maru Regular", size: 18))
                .foregroundColor(.black)
                .padding(.horizontal, 20)
            
            HStack(spacing: 15) {
                StatCard(
                    icon: "person.3.fill",
                    title: "\(quizManager.players.count)",
                    subtitle: "Players",
                    color: Color(hex: "#6082C9")
                )
                
                StatCard(
                    icon: "questionmark.circle.fill",
                    title: "4",
                    subtitle: "Questions",
                    color: Color(hex: "#C97D60")
                )
                
                StatCard(
                    icon: "clock.fill",
                    title: gameDuration,
                    subtitle: "Duration",
                    color: Color(hex: "#60C9A7")
                )
            }
            .padding(.horizontal, 20)
        }
        .scaleEffect(animateResults ? 1.0 : 0.9)
        .opacity(animateResults ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8), value: animateResults)
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 15) {
            // Only show "Play Again" if user is the host
            if quizManager.isHost() {
                Button(action: {
                    // TODO: Implement play again functionality
                    // This would create a new room with the same settings
                }) {
                    Text("Play Again")
                        .font(.custom("Kiwi Maru Regular", size: 18))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: "#C97D60"))
                        .cornerRadius(20)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
            }
            
            // Share results button
            Button(action: {
                shareResults()
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                    
                    Text("Share Results")
                        .font(.custom("Kiwi Maru Regular", size: 16))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 45)
                .background(Color(hex: "#6082C9").opacity(0.2))
                .cornerRadius(20)
                .foregroundColor(Color(hex: "#6082C9"))
            }
            .padding(.horizontal, 20)
            
            // Back to menu button
            Button(action: {
                Task {
                    await quizManager.leaveRoom()
                    dismiss()
                }
            }) {
                Text("Back to Menu")
                    .font(.custom("Kiwi Maru Regular", size: 16))
                    .foregroundColor(.gray)
            }
            .padding(.top, 10)
        }
        .scaleEffect(animateResults ? 1.0 : 0.9)
        .opacity(animateResults ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.0), value: animateResults)
    }
    
    private var celebrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("🏆")
                    .font(.system(size: 80))
                
                Text("Congratulations!")
                    .font(.custom("Kiwi Maru Medium", size: 32))
                    .foregroundColor(.white)
                
                Text("You won the quiz!")
                    .font(.custom("Kiwi Maru Light", size: 18))
                    .foregroundColor(.white.opacity(0.9))
                
                Text("Tap anywhere to continue")
                    .font(.custom("Kiwi Maru Light", size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 30)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "#C97D60").opacity(0.9))
            )
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            .scaleEffect(showCelebration ? 1.0 : 0.8)
            .opacity(showCelebration ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showCelebration)
        }
        .onTapGesture {
            withAnimation {
                showCelebration = false
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var topPlayer: QuizPlayer? {
        return quizManager.players.first
    }
    
    private var isCurrentPlayerWinner: Bool {
        guard let currentPlayer = quizManager.currentPlayer,
              let topPlayer = topPlayer else {
            return false
        }
        return currentPlayer.id == topPlayer.id
    }
    
    private var gameDuration: String {
        guard let room = quizManager.currentRoom,
              let startTime = room.startedAt,
              let endTime = room.endedAt else {
            return "--"
        }
        
        let duration = endTime.timeIntervalSince(startTime)
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Functions
    
    private func shareResults() {
        guard let room = quizManager.currentRoom,
              let currentPlayer = quizManager.currentPlayer else { return }
        
        let rank = quizManager.getPlayerRank(playerID: currentPlayer.id) ?? 0
        let totalPlayers = quizManager.players.count
        
        let shareText = """
        🎉 Just completed a QuizRooms quiz!
        
        Quiz: \(room.roomName)
        My Score: \(currentPlayer.score) points
        Rank: #\(rank) out of \(totalPlayers) players
        
        Play QuizRooms in Quizify!
        """
        
        let activityController = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityController, animated: true)
        }
    }
    
    private func updateAchievements() {
        // Update achievements based on game results
        guard let currentPlayer = quizManager.currentPlayer else { return }
        
        // Check if player won
        if isCurrentPlayerWinner {
            // Update win achievement
            AchievementsManager.shared.incrementAchievement(id: "quiz_champion")
        }
        
        // Update participation achievement
        AchievementsManager.shared.incrementAchievement(id: "social_learner")
        
        // If host, update host achievement
        if currentPlayer.isHost {
            AchievementsManager.shared.incrementAchievement(id: "game_host")
        }
    }
}

// MARK: - Supporting Views

struct LeaderboardRow: View {
    let player: QuizPlayer
    let rank: Int
    let isCurrentPlayer: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: 35, height: 35)
                
                if rank <= 3 {
                    Text(rankEmoji)
                        .font(.system(size: 18))
                } else {
                    Text("\(rank)")
                        .font(.custom("Kiwi Maru Medium", size: 16))
                        .foregroundColor(rankColor)
                }
            }
            
            // Player avatar
            ZStack {
                Circle()
                    .fill(Color(hex: "#C97D60").opacity(0.2))
                    .frame(width: 45, height: 45)
                
                Text(String(player.username.prefix(1)).uppercased())
                    .font(.custom("Kiwi Maru Medium", size: 20))
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
                            .font(.system(size: 12))
                    }
                    
                    if isCurrentPlayer {
                        Text("(You)")
                            .font(.custom("Kiwi Maru Light", size: 12))
                            .foregroundColor(Color(hex: "#C97D60"))
                    }
                }
                
                Text("@\(player.username)")
                    .font(.custom("Kiwi Maru Light", size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Score
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(player.score)")
                    .font(.custom("Kiwi Maru Medium", size: 18))
                    .foregroundColor(rankColor)
                
                Text("points")
                    .font(.custom("Kiwi Maru Light", size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(isCurrentPlayer ? Color(hex: "#C97D60").opacity(0.1) : Color.white)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(isCurrentPlayer ? Color(hex: "#C97D60") : Color.clear, lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var rankColor: Color {
        switch rank {
        case 1:
            return Color(hex: "#C97D60") // Gold
        case 2:
            return Color(hex: "#6082C9") // Silver
        case 3:
            return Color(hex: "#60C9A7") // Bronze
        default:
            return Color.gray
        }
    }
    
    private var rankEmoji: String {
        switch rank {
        case 1:
            return "🥇"
        case 2:
            return "🥈"
        case 3:
            return "🥉"
        default:
            return "\(rank)"
        }
    }
}

struct StatCard: View {
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

#Preview {
    GameResultsView()
        .environmentObject(QuizRoomManager())
}
