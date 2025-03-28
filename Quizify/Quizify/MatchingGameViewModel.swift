//
//  MatchingGameViewModel.swift
//  Quizify
//
//  Created on 3/27/25.
//

import Foundation
import SwiftUI

// A card in the matching game
struct MatchingCard: Identifiable {
    let id = UUID()
    let content: String
    let pairID: Int
    let isTermCard: Bool  // true if term, false if definition
    var isFlipped = true  // Start with cards flipped (showing content)
    var isMatched = false
    var isIncorrect = false  // track incorrect selections
}

@MainActor
class MatchingGameViewModel: ObservableObject {
    // Game state
    @Published var gameCards: [MatchingCard] = []
    @Published var isLoading = true
    @Published var gameStarted = false
    @Published var gameOver = false
    @Published var gameWon = false
    @Published var matchedPairs = 0
    @Published var totalPairs = 0
    @Published var secondsRemaining = 0
    @Published var timeExpired = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var timeUsed: TimeInterval = 0
    
    // Game configuration
    let setID: String
    let setTitle: String
    
    // Selected cards
    private var firstSelectedCard: MatchingCard?
    private var secondSelectedCard: MatchingCard?
    private var cardSelectionLocked = false
    
    // Timer
    var timer: Timer?
    private var startTime: Date?
    
    // Computed property for formatted time
    var timeRemaining: String {
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // Give more time for the simpler game
    var gameDuration: Int {
        return 60  // 1 minute is enough since cards start revealed
    }
    
    init(setID: String, setTitle: String) {
        self.setID = setID
        self.setTitle = setTitle
    }
    
    // Load cards from the set
    func loadCards(dataManager: DataManager) {
        isLoading = true
        
        dataManager.fetchCardsForSet(setID: setID) { [weak self] fetchedCards in
            guard let self = self else { return }
            
            // Limit to 10 pairs maximum to prevent the game from being too cluttered
            let maxPairs = min(10, fetchedCards.count)
            
            // Prepare cards for the game
            self.prepareGameCards(from: Array(fetchedCards.prefix(maxPairs)))
            self.isLoading = false
        }
    }
    
    // Create matching cards from the fetched flashcards
    private func prepareGameCards(from flashcards: [Card]) {
        var cards: [MatchingCard] = []
        
        // Limit to 6 flashcards maximum for a more manageable game
        let limitedCards = flashcards.prefix(6)
        
        for (index, flashcard) in limitedCards.enumerated() {
            // Create a term card - start with cards flipped (showing content)
            let termCard = MatchingCard(
                content: flashcard.term,
                pairID: index,
                isTermCard: true,
                isFlipped: true
            )
            
            // Create a definition card - start with cards flipped (showing content)
            let defCard = MatchingCard(
                content: flashcard.def,
                pairID: index,
                isTermCard: false,
                isFlipped: true
            )
            
            cards.append(termCard)
            cards.append(defCard)
        }
        
        // Shuffle the cards
        gameCards = cards.shuffled()
        totalPairs = min(6, flashcards.count)
        matchedPairs = 0
    }
    
    // Start the game and timer
    func startGame() {
        gameStarted = true
        startTime = Date()
        secondsRemaining = gameDuration
        
        // Start the timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.secondsRemaining > 0 {
                self.secondsRemaining -= 1
            } else {
                self.timeExpired = true
                self.timer?.invalidate()
                self.timer = nil
            }
        }
    }
    
    // Handle card selection
    func selectCard(_ selectedCard: MatchingCard) {
        // Prevent selecting cards while processing a match
        if cardSelectionLocked {
            return
        }
        
        // Find the index of the selected card
        guard let index = gameCards.firstIndex(where: { $0.id == selectedCard.id }) else {
            return
        }
        
        // Mark card as selected (visually) - we're not actually flipping since cards start flipped
        gameCards[index].isFlipped = true
        
        // Process selection
        if firstSelectedCard == nil {
            // First card selected
            firstSelectedCard = gameCards[index]
        } else {
            // Second card selected - don't allow selecting the same card twice
            if firstSelectedCard?.id == selectedCard.id {
                return
            }
            secondSelectedCard = gameCards[index]
            
            // Process the pair
            processPair()
        }
    }
    
    // Process a pair of selected cards
    private func processPair() {
        // Lock selection while processing
        cardSelectionLocked = true
        
        guard let first = firstSelectedCard, let second = secondSelectedCard else {
            cardSelectionLocked = false
            return
        }
        
        // Check if cards form a matching pair
        let isMatch = first.pairID == second.pairID && first.isTermCard != second.isTermCard
        
        if isMatch {
            // Mark both cards as matched
            updateMatchedStatus(for: first.id, isMatched: true)
            updateMatchedStatus(for: second.id, isMatched: true)
            
            // Increment matched pairs
            matchedPairs += 1
            
            // Check if all pairs are matched
            if matchedPairs >= totalPairs {
                gameWon = true
                gameOver = true
                timer?.invalidate()
                timer = nil
                
                // Calculate time used
                if let startTime = startTime {
                    timeUsed = Date().timeIntervalSince(startTime)
                }
            }
            
            // Reset selection state
            resetSelection()
        } else {
            // Not a match, mark cards as incorrect (visual feedback)
            if let firstIndex = gameCards.firstIndex(where: { $0.id == first.id }) {
                gameCards[firstIndex].isIncorrect = true
            }
            
            if let secondIndex = gameCards.firstIndex(where: { $0.id == second.id }) {
                gameCards[secondIndex].isIncorrect = true
            }
            
            // After a delay, reset the incorrect state and selection
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                // Reset incorrect state
                if let firstIndex = self.gameCards.firstIndex(where: { $0.id == first.id }) {
                    self.gameCards[firstIndex].isIncorrect = false
                }
                
                if let secondIndex = self.gameCards.firstIndex(where: { $0.id == second.id }) {
                    self.gameCards[secondIndex].isIncorrect = false
                }
                
                // Reset selection to allow reusing these cards
                self.resetSelection()
            }
        }
    }
    
    // Update the matched status of a card
    private func updateMatchedStatus(for id: UUID, isMatched: Bool) {
        if let index = gameCards.firstIndex(where: { $0.id == id }) {
            gameCards[index].isMatched = isMatched
        }
    }
    
    // Update the flipped status of a card (visual selection)
    private func updateFlippedStatus(for id: UUID, isFlipped: Bool) {
        if let index = gameCards.firstIndex(where: { $0.id == id }) {
            if !isFlipped {
                // In our modified game, "not flipped" means not selected
                gameCards[index].isFlipped = isFlipped
            }
        }
    }
    
    // Reset the current card selection
    private func resetSelection() {
        firstSelectedCard = nil
        secondSelectedCard = nil
        cardSelectionLocked = false
    }
    
    // Reset the game to play again
    func resetGame() {
        // Clear timer
        timer?.invalidate()
        timer = nil
        
        // Reset game state
        gameStarted = false
        gameOver = false
        gameWon = false
        timeExpired = false
        matchedPairs = 0
        
        // Shuffle cards and reset their state
        for i in 0..<gameCards.count {
            gameCards[i].isFlipped = true  // Keep cards flipped (content showing)
            gameCards[i].isMatched = false
            gameCards[i].isIncorrect = false
        }
        gameCards.shuffle()
    }
    
    // End the game (used when time expires)
    func endGame() {
        gameOver = true
        timer?.invalidate()
        timer = nil
    }
    
    // Format a time interval into MM:SS
    func formatTime(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    deinit {
        timer?.invalidate()
    }
}
