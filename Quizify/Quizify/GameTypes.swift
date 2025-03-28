//
//  GameTypes.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 3/27/25.
//

import Foundation
import SwiftUI

// Study mode types
enum StudyMode: String, CaseIterable, Identifiable {
    case flashcards = "Flashcards"
    case matching = "Matching Game"
    case quiz = "Quiz"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .flashcards:
            return "rectangle.fill.on.rectangle.fill"
        case .matching:
            return "gamecontroller.fill"
        case .quiz:
            return "questionmark.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .flashcards:
            return "Traditional flashcard review with term and definition sides"
        case .matching:
            return "Match terms with their definitions in a timed game"
        case .quiz:
            return "Test your knowledge with multiple choice questions"
        }
    }
    
    var color: Color {
        switch self {
        case .flashcards:
            return Color(hex: "#C97D60")
        case .matching:
            return Color(hex: "#6082C9")
        case .quiz:
            return Color(hex: "#60C9A7")
        }
    }
}

// Add this to modify your SetDetailView.swift:
// You could add a study mode selector at the top of the content area
struct StudyModeSelector: View {
    @Binding var selectedMode: StudyMode
    let setID: String
    let setTitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Study Modes")
                .font(.custom("Kiwi Maru Regular", size: 18))
                .foregroundColor(.gray)
                .padding(.leading, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(StudyMode.allCases) { mode in
                        NavigationLink(
                            destination: destinationView(for: mode, setID: setID, setTitle: setTitle)
                        ) {
                            VStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(mode.color.opacity(0.2))
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: mode.icon)
                                        .font(.system(size: 24))
                                        .foregroundColor(mode.color)
                                }
                                
                                Text(mode.rawValue)
                                    .font(.custom("Kiwi Maru Regular", size: 14))
                                    .foregroundColor(mode == selectedMode ? mode.color : .gray)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(mode == selectedMode ? mode.color : Color.clear, lineWidth: 2)
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 10)
    }
    
    @ViewBuilder
    private func destinationView(for mode: StudyMode, setID: String, setTitle: String) -> some View {
        switch mode {
        case .flashcards:
            EmptyView() // This is the current view, so no navigation needed
        case .matching:
            MatchingGameView(setID: setID, setTitle: setTitle)
        case .quiz:
            Text("Quiz mode coming soon!")
                .font(.custom("Kiwi Maru Regular", size: 18))
                .foregroundColor(.gray)
                .padding()
        }
    }
}
