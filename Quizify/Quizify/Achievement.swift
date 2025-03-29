//
//  Achievement.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 3/29/25.
//

import SwiftUI

struct Achievement: Identifiable, Codable {
    var id: String
    var title: String
    var description: String
    var icon: String
    var category: AchievementCategory
    var progress: Int
    var targetValue: Int
    var isUnlocked: Bool
    var unlockedDate: Date?
    var color: String
    
    // Calculate progress percentage
    var progressPercent: Double {
        return min(Double(progress) / Double(targetValue), 1.0)
    }
    
    // Format the unlocked date
    var formattedUnlockDate: String {
        guard let date = unlockedDate else { return "Not unlocked" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "Unlocked on \(formatter.string(from: date))"
    }
}

enum AchievementCategory: String, Codable, CaseIterable {
    case study = "Study"
    case streak = "Streak"
    case creation = "Creation"
    case mastery = "Mastery"
    case social = "Social"
    
    var displayName: String {
        return self.rawValue
    }
    
    var systemIcon: String {
        switch self {
        case .study:
            return "book.fill"
        case .streak:
            return "flame.fill"
        case .creation:
            return "plus.rectangle.fill"
        case .mastery:
            return "star.fill"
        case .social:
            return "person.2.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .study:
            return Color(hex: "#6082C9")
        case .streak:
            return Color(hex: "#C97D60")
        case .creation:
            return Color(hex: "#60C9A7")
        case .mastery:
            return Color(hex: "#C9B260")
        case .social:
            return Color(hex: "#9460C9")
        }
    }
}
