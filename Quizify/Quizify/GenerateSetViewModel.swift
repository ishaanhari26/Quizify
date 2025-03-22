//
//  GenerateSetViewModel.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 3/22/25.
//


import Foundation
import SwiftUI

@MainActor
class GenerateSetViewModel: ObservableObject {
    @Published var prompt: String = ""
    @Published var isGenerating: Bool = false
    @Published var errorMessage: String = ""
    @Published var generatedCards: [FlashCard] = []
    @Published var cardCount: Int = 10
    @Published var setTitle: String = ""
    @Published var setDescription: String = ""
    @Published var showDescription: Bool = true
    
    // Generate flashcards based on the prompt
    func generateFlashcards() async {
        guard !prompt.isEmpty else {
            errorMessage = "Please enter a topic or question"
            return
        }
        
        isGenerating = true
        errorMessage = ""
        
        do {
            generatedCards = try await GeminiService.shared.generateFlashcards(from: prompt, cardCount: cardCount)
            
            // Auto-generate a title if none provided
            if setTitle.isEmpty {
                setTitle = prompt.count > 30 ? String(prompt.prefix(30)) + "..." : prompt
            }
            
        } catch {
            errorMessage = "Failed to generate flashcards: \(error.localizedDescription)"
        }
        
        isGenerating = false
    }
    
    // Reset the state
    func reset() {
        prompt = ""
        generatedCards = []
        errorMessage = ""
        setTitle = ""
        setDescription = ""
    }
    
    // Save the generated set to Firestore
    func saveGeneratedSet(dataManager: DataManager, completion: @escaping () -> Void) {
        guard !generatedCards.isEmpty, !setTitle.isEmpty else {
            errorMessage = "Cannot save: Missing cards or title"
            return
        }
        
        // Save to Firebase using the existing DataManager
        dataManager.addSet(
            title: setTitle,
            description: showDescription ? setDescription : nil,
            cards: generatedCards
        )
        
        // Call completion handler
        completion()
    }
}

