//
//  MatchingGameView.swift
//  Quizify
//
//  Created on 3/27/25.
//

import SwiftUI

struct MatchingGameView: View {
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var viewModel: MatchingGameViewModel
    @Environment(\.dismiss) var dismiss
    
    init(setID: String, setTitle: String) {
        _viewModel = StateObject(wrappedValue: MatchingGameViewModel(setID: setID, setTitle: setTitle))
    }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.gameOver {
                    gameOverView
                } else {
                    gameView
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.loadCards(dataManager: dataManager)
        }
        .alert(viewModel.alertMessage, isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) {}
        }
        .alert("Time's Up!", isPresented: $viewModel.timeExpired) {
            Button("Try Again", role: .cancel) {
                viewModel.resetGame()
            }
            Button("End Game", role: .destructive) {
                viewModel.endGame()
            }
        } message: {
            Text("You matched \(viewModel.matchedPairs) out of \(viewModel.totalPairs) pairs.")
        }
    }
    
    // MARK: - Component Views
    
    private var headerView: some View {
        ZStack {
            Color(hex: "#C97D60").ignoresSafeArea(edges: .top)
            
            VStack {
                HStack {
                    Button(action: {
                        if viewModel.timer != nil {
                            viewModel.timer?.invalidate()
                            viewModel.timer = nil
                        }
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.system(size: 22))
                    }
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    Text("Matching Game")
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
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            Text("Loading cards...")
                .font(.custom("Kiwi Maru Light", size: 16))
                .foregroundColor(.gray)
                .padding()
            Spacer()
        }
    }
    
    private var gameView: some View {
        VStack(spacing: 20) {
            // Game info bar
            HStack {
                // score
                VStack(alignment: .leading, spacing: 5) {
                    Text("Set: \(viewModel.setTitle)")
                        .font(.custom("Kiwi Maru Regular", size: 14))
                        .foregroundColor(.gray)
                    
                    Text("Matches: \(viewModel.matchedPairs)/\(viewModel.totalPairs)")
                        .font(.custom("Kiwi Maru Medium", size: 18))
                        .foregroundColor(Color(hex: "#C97D60"))
                }
                
                Spacer()
                
                // timer
                VStack(alignment: .trailing, spacing: 5) {
                    Text("Time Remaining")
                        .font(.custom("Kiwi Maru Regular", size: 14))
                        .foregroundColor(.gray)
                    
                    Text(viewModel.timeRemaining)
                        .font(.custom("Kiwi Maru Medium", size: 18))
                        .foregroundColor(viewModel.secondsRemaining <= 10 ? .red : Color(hex: "#C97D60"))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 15)
            
            // Cards grid
            if !viewModel.gameStarted {
                startGameButton
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(viewModel.gameCards) { card in
                            MatchingCardView(
                                card: card,
                                onTap: {
                                    viewModel.selectCard(card)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 10)
                }
            }
        }
    }
    
    private var startGameButton: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 15) {
                Image(systemName: "clock")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "#C97D60"))
                
                Text("Match all cards before time runs out!")
                    .font(.custom("Kiwi Maru Regular", size: 18))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                Text("You'll have \(viewModel.gameDuration) seconds.")
                    .font(.custom("Kiwi Maru Light", size: 16))
                    .foregroundColor(.gray)
                    .padding(.top, 5)
            }
            
            Button(action: {
                viewModel.startGame()
            }) {
                Text("Start Game")
                    .font(.custom("Kiwi Maru Regular", size: 18))
                    .frame(width: 200, height: 50)
                    .background(Color(hex: "#C97D60"))
                    .cornerRadius(20)
                    .foregroundColor(.white)
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    private var gameOverView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: viewModel.gameWon ? "trophy.fill" : "clock.badge.exclamationmark")
                .font(.system(size: 80))
                .foregroundColor(viewModel.gameWon ? Color.yellow : Color.red)
                .padding(.bottom, 10)
            
            Text(viewModel.gameWon ? "Congratulations!" : "Time's Up!")
                .font(.custom("Kiwi Maru Medium", size: 28))
                .foregroundColor(viewModel.gameWon ? Color(hex: "#C97D60") : Color.gray)
            
            VStack(spacing: 15) {
                Text("You matched \(viewModel.matchedPairs) out of \(viewModel.totalPairs) pairs.")
                    .font(.custom("Kiwi Maru Regular", size: 18))
                    .foregroundColor(.gray)
                
                if viewModel.gameWon {
                    Text("Time used: \(viewModel.formatTime(from: viewModel.timeUsed))")
                        .font(.custom("Kiwi Maru Regular", size: 18))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 20)
            
            HStack(spacing: 20) {
                Button(action: {
                    viewModel.resetGame()
                }) {
                    Text("Play Again")
                        .font(.custom("Kiwi Maru Regular", size: 18))
                        .frame(width: 150, height: 50)
                        .background(Color(hex: "#C97D60"))
                        .cornerRadius(20)
                        .foregroundColor(.white)
                }
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Exit")
                        .font(.custom("Kiwi Maru Regular", size: 18))
                        .frame(width: 150, height: 50)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(20)
                        .foregroundColor(.black)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

struct MatchingCardView: View {
    let card: MatchingCard
    let onTap: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(cardBorderColor(), lineWidth: 2)
                )
                .overlay(
                    VStack {
                        if card.isMatched {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 20))
                                .padding(.bottom, 5)
                        }
                        
                        Text(card.content)
                            .font(.custom("Kiwi Maru Regular", size: 14))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                    }
                )
        }
        .frame(height: 120)
        .padding(5)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardBackgroundColor())
        )
        .onTapGesture {
            if !card.isMatched {
                onTap()
            }
        }
        .animation(.spring(), value: card.isMatched)
        .disabled(card.isMatched)
    }
    
    // color based on card state
    private func cardBorderColor() -> Color {
        if card.isMatched {
            return Color.green
        } else if card.isIncorrect {
            return Color.red
        } else if card.isFlipped && !card.isMatched {
            return Color.blue
        } else {
            return Color(hex: "#C97D60")
        }
    }
    
    private func cardBackgroundColor() -> Color {
        if card.isMatched {
            return Color.green.opacity(0.2)
        } else if card.isIncorrect {
            return Color.red.opacity(0.2)
        } else if card.isFlipped && !card.isMatched {
            return Color.blue.opacity(0.1)
        } else {
            return Color.clear
        }
    }
}

#Preview {
    MatchingGameView(setID: "preview-id", setTitle: "Preview Set")
        .environmentObject(DataManager())
}
