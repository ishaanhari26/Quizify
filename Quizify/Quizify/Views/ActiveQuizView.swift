//
//  ActiveQuizView.swift
//  Quizify
//
//  Created for QuizRooms feature
//

import SwiftUI

struct ActiveQuizView: View {
    @EnvironmentObject var quizManager: QuizRoomManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedAnswerIndex: Int? = nil
    @State private var hasAnswered = false
    @State private var showResults = false
    @State private var showGameResults = false
    @State private var answerSubmitted = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with game progress
                headerView
                
                if showGameResults {
                    GameResultsView()
                        .environmentObject(quizManager)
                } else if let currentQuestion = quizManager.getCurrentQuestion() {
                    // Game content
                    VStack(spacing: 20) {
                        // Timer and round info
                        gameInfoSection
                        
                        // Question
                        questionSection(question: currentQuestion)
                        
                        // Answers
                        answersSection(question: currentQuestion)
                        
                        // Current standings (compact)
                        standingsSection
                        
                        Spacer()
                    }
                } else {
                    // Loading or waiting for next question
                    loadingView
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: quizManager.currentRoom?.status) { status in
            if status == .ended {
                showGameResults = true
            }
        }
        .onChange(of: quizManager.isQuestionActive) { isActive in
            if !isActive && hasAnswered {
                // Question ended, reset for next question
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    resetForNextQuestion()
                }
            }
        }
    }
    
    // MARK: - Component Views
    
    private var headerView: some View {
        ZStack {
            Color(hex: "#C97D60").ignoresSafeArea(edges: .top)
            
            VStack {
                HStack {
                    Button(action: {
                        // Only host can end game early
                        if quizManager.isHost() {
                            Task {
                                await quizManager.leaveRoom()
                                dismiss()
                            }
                        }
                    }) {
                        Image(systemName: quizManager.isHost() ? "xmark" : "")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    }
                    .opacity(quizManager.isHost() ? 1.0 : 0.0)
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text(quizManager.currentRoom?.roomName ?? "Quiz Room")
                            .font(.custom("Kiwi Maru Medium", size: 20))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        let progress = quizManager.getGameProgress()
                        Text("Round \(progress.current) of \(progress.total)")
                            .font(.custom("Kiwi Maru Light", size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Color.clear
                        .frame(width: 20, height: 20)
                        .padding(.trailing, 20)
                }
                .padding(.top, 25)
                .padding(.bottom, 15)
            }
        }
        .frame(height: 75)
    }
    
    private var gameInfoSection: some View {
        HStack(spacing: 20) {
            // Timer
            VStack(spacing: 5) {
                Text("Time")
                    .font(.custom("Kiwi Maru Light", size: 14))
                    .foregroundColor(.gray)
                
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 6)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(quizManager.timeRemaining) / 15.0)
                        .stroke(timerColor, lineWidth: 6)
                        .rotationEffect(.degrees(-90))
                        .frame(width: 60, height: 60)
                        .animation(.linear(duration: 1), value: quizManager.timeRemaining)
                    
                    Text("\(quizManager.timeRemaining)")
                        .font(.custom("Kiwi Maru Medium", size: 20))
                        .foregroundColor(timerColor)
                }
            }
            
            Spacer()
            
            // Your score
            VStack(spacing: 5) {
                Text("Your Score")
                    .font(.custom("Kiwi Maru Light", size: 14))
                    .foregroundColor(.gray)
                
                Text("\(quizManager.currentPlayer?.score ?? 0)")
                    .font(.custom("Kiwi Maru Medium", size: 24))
                    .foregroundColor(Color(hex: "#C97D60"))
            }
            
            Spacer()
            
            // Your rank
            VStack(spacing: 5) {
                Text("Rank")
                    .font(.custom("Kiwi Maru Light", size: 14))
                    .foregroundColor(.gray)
                
                if let playerID = quizManager.currentPlayer?.id,
                   let rank = quizManager.getPlayerRank(playerID: playerID) {
                    Text("#\(rank)")
                        .font(.custom("Kiwi Maru Medium", size: 24))
                        .foregroundColor(Color(hex: "#6082C9"))
                } else {
                    Text("--")
                        .font(.custom("Kiwi Maru Medium", size: 24))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 15)
    }
    
    private func questionSection(question: QuizQuestion) -> some View {
        VStack(spacing: 15) {
            Text("Question \(question.roundNumber)")
                .font(.custom("Kiwi Maru Light", size: 16))
                .foregroundColor(.gray)
            
            Text(question.question)
                .font(.custom("Kiwi Maru Regular", size: 20))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .lineLimit(4)
        }
        .padding(.vertical, 20)
        .background(Color(hex: "#EFEFEF").opacity(0.5))
        .cornerRadius(15)
        .padding(.horizontal, 20)
    }
    
    private func answersSection(question: QuizQuestion) -> some View {
        VStack(spacing: 12) {
            ForEach(0..<question.answers.count, id: \.self) { index in
                Button(action: {
                    selectAnswer(index: index)
                }) {
                    AnswerButton(
                        text: question.answers[index],
                        index: index,
                        isSelected: selectedAnswerIndex == index,
                        isCorrect: !quizManager.isQuestionActive && index == question.correctAnswerIndex,
                        isIncorrect: !quizManager.isQuestionActive && selectedAnswerIndex == index && index != question.correctAnswerIndex,
                        isDisabled: hasAnswered || !quizManager.isQuestionActive
                    )
                }
                .disabled(hasAnswered || !quizManager.isQuestionActive)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var standingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Current Standings")
                .font(.custom("Kiwi Maru Regular", size: 16))
                .foregroundColor(.gray)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(quizManager.players.enumerated()), id: \.element.id) { index, player in
                        CompactPlayerCard(player: player, rank: index + 1)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 10)
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            
            Text("Get ready for the next question...")
                .font(.custom("Kiwi Maru Light", size: 16))
                .foregroundColor(.gray)
            
            Spacer()
        }
    }
    
    // MARK: - Computed Properties
    
    private var timerColor: Color {
        if quizManager.timeRemaining <= 5 {
            return .red
        } else if quizManager.timeRemaining <= 10 {
            return .orange
        } else {
            return Color(hex: "#6082C9")
        }
    }
    
    // MARK: - Functions
    
    private func selectAnswer(index: Int) {
        guard !hasAnswered && quizManager.isQuestionActive else { return }
        
        selectedAnswerIndex = index
        hasAnswered = true
        answerSubmitted = true
        
        // Submit answer
        Task {
            do {
                try await quizManager.submitAnswer(answerIndex: index)
            } catch {
                // Handle error - maybe show a toast
                print("Error submitting answer: \(error.localizedDescription)")
            }
        }
    }
    
    private func resetForNextQuestion() {
        selectedAnswerIndex = nil
        hasAnswered = false
        answerSubmitted = false
    }
}

// MARK: - Supporting Views

struct AnswerButton: View {
    let text: String
    let index: Int
    let isSelected: Bool
    let isCorrect: Bool
    let isIncorrect: Bool
    let isDisabled: Bool
    
    private let answerLabels = ["A", "B", "C", "D"]
    
    var body: some View {
        HStack(spacing: 15) {
            // Answer label (A, B, C, D)
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 35, height: 35)
                
                Text(answerLabels[index])
                    .font(.custom("Kiwi Maru Medium", size: 16))
                    .foregroundColor(textColor)
            }
            
            // Answer text
            Text(text)
                .font(.custom("Kiwi Maru Regular", size: 16))
                .foregroundColor(textColor)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
            
            Spacer()
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(borderColor, lineWidth: 2)
        )
        .scaleEffect(isSelected && !isDisabled ? 0.98 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
    
    private var backgroundColor: Color {
        if isCorrect {
            return Color.green.opacity(0.2)
        } else if isIncorrect {
            return Color.red.opacity(0.2)
        } else if isSelected {
            return Color(hex: "#C97D60").opacity(0.2)
        } else {
            return Color.white
        }
    }
    
    private var borderColor: Color {
        if isCorrect {
            return Color.green
        } else if isIncorrect {
            return Color.red
        } else if isSelected {
            return Color(hex: "#C97D60")
        } else {
            return Color.gray.opacity(0.3)
        }
    }
    
    private var textColor: Color {
        if isCorrect {
            return Color.green
        } else if isIncorrect {
            return Color.red
        } else if isSelected {
            return Color(hex: "#C97D60")
        } else {
            return Color.black
        }
    }
}

struct CompactPlayerCard: View {
    let player: QuizPlayer
    let rank: Int
    
    var body: some View {
        VStack(spacing: 8) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: 30, height: 30)
                
                Text("\(rank)")
                    .font(.custom("Kiwi Maru Medium", size: 14))
                    .foregroundColor(rankColor)
            }
            
            // Player avatar
            ZStack {
                Circle()
                    .fill(Color(hex: "#C97D60").opacity(0.2))
                    .frame(width: 35, height: 35)
                
                Text(String(player.username.prefix(1)).uppercased())
                    .font(.custom("Kiwi Maru Medium", size: 16))
                    .foregroundColor(Color(hex: "#C97D60"))
            }
            
            // Player name
            Text(player.displayName)
                .font(.custom("Kiwi Maru Light", size: 12))
                .foregroundColor(.black)
                .lineLimit(1)
            
            // Score
            Text("\(player.score)")
                .font(.custom("Kiwi Maru Medium", size: 14))
                .foregroundColor(rankColor)
        }
        .frame(width: 80)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
    
    private var rankColor: Color {
        switch rank {
        case 1:
            return Color(hex: "#C97D60") // Gold-ish
        case 2:
            return Color(hex: "#6082C9") // Silver-ish
        case 3:
            return Color(hex: "#60C9A7") // Bronze-ish
        default:
            return Color.gray
        }
    }
}

#Preview {
    ActiveQuizView()
        .environmentObject(QuizRoomManager())
}
