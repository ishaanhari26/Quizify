//
//  AchievementsManager.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 3/29/25.
//


import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

class AchievementsManager: ObservableObject {
    @Published var achievements: [Achievement] = []
    @Published var recentlyUnlocked: [Achievement] = []
    @Published var isLoading: Bool = true
    @Published var showUnlockAnimation: Bool = false
    @Published var currentUnlockedAchievement: Achievement?
    
    // Singleton instance
    static let shared = AchievementsManager()
    
    private init() {
        loadAchievements()
    }
    
    // Load user achievements
    func loadAchievements() {
        isLoading = true
        
        guard let userID = AuthManager.shared.getUserID() else {
            // No user logged in, use default achievements with zero progress
            createDefaultAchievements()
            isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        let achievementsRef = db.collection("Users").document(userID).collection("Achievements")
        
        achievementsRef.getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error loading achievements: \(error.localizedDescription)")
                self.createDefaultAchievements()
                self.isLoading = false
                return
            }
            
            if let snapshot = snapshot, !snapshot.isEmpty {
                // User has achievements, load them
                var loadedAchievements: [Achievement] = []
                
                for document in snapshot.documents {
                    let data = document.data()
                    
                    let id = document.documentID
                    let title = data["title"] as? String ?? ""
                    let description = data["description"] as? String ?? ""
                    let icon = data["icon"] as? String ?? "star.fill"
                    let categoryString = data["category"] as? String ?? AchievementCategory.study.rawValue
                    let category = AchievementCategory(rawValue: categoryString) ?? .study
                    let progress = data["progress"] as? Int ?? 0
                    let targetValue = data["targetValue"] as? Int ?? 1
                    let isUnlocked = data["isUnlocked"] as? Bool ?? false
                    let unlockedTimestamp = data["unlockedDate"] as? Timestamp
                    let color = data["color"] as? String ?? "#C97D60"
                    
                    var unlockedDate: Date? = nil
                    if let timestamp = unlockedTimestamp {
                        unlockedDate = timestamp.dateValue()
                    }
                    
                    let achievement = Achievement(
                        id: id,
                        title: title,
                        description: description,
                        icon: icon,
                        category: category,
                        progress: progress,
                        targetValue: targetValue,
                        isUnlocked: isUnlocked,
                        unlockedDate: unlockedDate,
                        color: color
                    )
                    
                    loadedAchievements.append(achievement)
                }
                
                self.achievements = loadedAchievements
                
                // Get recently unlocked achievements (last 7 days)
                let calendar = Calendar.current
                let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                
                self.recentlyUnlocked = loadedAchievements.filter { achievement in
                    if let unlockDate = achievement.unlockedDate, achievement.isUnlocked {
                        return unlockDate >= oneWeekAgo
                    }
                    return false
                }
                
                self.isLoading = false
            } else {
                // User has no achievements yet, create defaults and save them
                self.createDefaultAchievements()
                self.saveDefaultAchievements()
                self.isLoading = false
            }
        }
    }
    
    // Create the default set of achievements
    private func createDefaultAchievements() {
        achievements = [
            // Study achievements
            Achievement(
                id: "study_time_1",
                title: "Study Beginner",
                description: "Study for 1 hour total",
                icon: "clock.fill",
                category: .study,
                progress: 0,
                targetValue: 60,  // 60 minutes
                isUnlocked: false,
                unlockedDate: nil,
                color: "#6082C9"
            ),
            Achievement(
                id: "study_time_2",
                title: "Study Enthusiast",
                description: "Study for 5 hours total",
                icon: "clock.fill",
                category: .study,
                progress: 0,
                targetValue: 300,  // 300 minutes
                isUnlocked: false,
                unlockedDate: nil,
                color: "#6082C9"
            ),
            Achievement(
                id: "study_time_3",
                title: "Study Master",
                description: "Study for 24 hours total",
                icon: "clock.fill",
                category: .study,
                progress: 0,
                targetValue: 1440,  // 1440 minutes
                isUnlocked: false,
                unlockedDate: nil,
                color: "#6082C9"
            ),
            
            // Streak achievements
            Achievement(
                id: "streak_3",
                title: "Consistent Learner",
                description: "Maintain a 3-day study streak",
                icon: "flame.fill",
                category: .streak,
                progress: 0,
                targetValue: 3,
                isUnlocked: false,
                unlockedDate: nil,
                color: "#C97D60"
            ),
            Achievement(
                id: "streak_7",
                title: "Weekly Warrior",
                description: "Maintain a 7-day study streak",
                icon: "flame.fill",
                category: .streak,
                progress: 0,
                targetValue: 7,
                isUnlocked: false,
                unlockedDate: nil,
                color: "#C97D60"
            ),
            Achievement(
                id: "streak_30",
                title: "Monthly Master",
                description: "Maintain a 30-day study streak",
                icon: "flame.fill",
                category: .streak,
                progress: 0,
                targetValue: 30,
                isUnlocked: false,
                unlockedDate: nil,
                color: "#C97D60"
            ),
            
            // Creation achievements
            Achievement(
                id: "create_set_1",
                title: "Creator",
                description: "Create your first flashcard set",
                icon: "plus.rectangle.fill",
                category: .creation,
                progress: 0,
                targetValue: 1,
                isUnlocked: false,
                unlockedDate: nil,
                color: "#60C9A7"
            ),
            Achievement(
                id: "create_set_5",
                title: "Content Builder",
                description: "Create 5 flashcard sets",
                icon: "plus.rectangle.fill",
                category: .creation,
                progress: 0,
                targetValue: 5,
                isUnlocked: false,
                unlockedDate: nil,
                color: "#60C9A7"
            ),
            Achievement(
                id: "create_set_10",
                title: "Knowledge Architect",
                description: "Create 10 flashcard sets",
                icon: "rectangle.stack.fill",
                category: .creation,
                progress: 0,
                targetValue: 10,
                isUnlocked: false,
                unlockedDate: nil,
                color: "#60C9A7"
            ),
            
            // Mastery achievements
            Achievement(
                id: "matching_game_1",
                title: "Quick Matcher",
                description: "Complete a matching game in under 30 seconds",
                icon: "gamecontroller.fill",
                category: .mastery,
                progress: 0,
                targetValue: 1,
                isUnlocked: false,
                unlockedDate: nil,
                color: "#C9B260"
            ),
            Achievement(
                id: "study_sets_5",
                title: "Diverse Learner",
                description: "Study 5 different sets",
                icon: "books.vertical.fill",
                category: .mastery,
                progress: 0,
                targetValue: 5,
                isUnlocked: false,
                unlockedDate: nil,
                color: "#C9B260"
            ),
            Achievement(
                id: "create_cards_50",
                title: "Card Collector",
                description: "Create 50 flashcards total",
                icon: "rectangle.on.rectangle.fill",
                category: .mastery,
                progress: 0,
                targetValue: 50,
                isUnlocked: false,
                unlockedDate: nil,
                color: "#C9B260"
            ),
            
            // Social achievements
            Achievement(
                id: "public_set_1",
                title: "Knowledge Sharer",
                description: "Make your first set public",
                icon: "globe",
                category: .social,
                progress: 0,
                targetValue: 1,
                isUnlocked: false,
                unlockedDate: nil,
                color: "#9460C9"
            ),
            Achievement(
                id: "public_set_5",
                title: "Community Contributor",
                description: "Make 5 sets public",
                icon: "person.2.fill",
                category: .social,
                progress: 0,
                targetValue: 5,
                isUnlocked: false,
                unlockedDate: nil,
                color: "#9460C9"
            ),
            Achievement(
                id: "profile_complete",
                title: "Identity Established",
                description: "Complete your user profile",
                icon: "person.fill",
                category: .social,
                progress: 0,
                targetValue: 1,
                isUnlocked: false,
                unlockedDate: nil,
                color: "#9460C9"
            )
        ]
    }
    
    // Save default achievements to Firestore for a new user
    private func saveDefaultAchievements() {
        guard let userID = AuthManager.shared.getUserID() else {
            return
        }
        
        let db = Firestore.firestore()
        
        for achievement in achievements {
            let achievementRef = db.collection("Users").document(userID).collection("Achievements").document(achievement.id)
            
            let data: [String: Any] = [
                "title": achievement.title,
                "description": achievement.description,
                "icon": achievement.icon,
                "category": achievement.category.rawValue,
                "progress": achievement.progress,
                "targetValue": achievement.targetValue,
                "isUnlocked": achievement.isUnlocked,
                "color": achievement.color
            ]
            
            achievementRef.setData(data) { error in
                if let error = error {
                    print("Error saving achievement: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Update achievement progress
    func updateAchievement(id: String, progress: Int, autoUnlock: Bool = true) {
        guard let userID = AuthManager.shared.getUserID() else {
            return
        }
        
        // Find the achievement in the local array
        guard let index = achievements.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        // Update the local achievement
        var achievement = achievements[index]
        let oldProgress = achievement.progress
        achievement.progress = progress
        
        // Check if the achievement should be unlocked
        if autoUnlock && progress >= achievement.targetValue && !achievement.isUnlocked {
            achievement.isUnlocked = true
            achievement.unlockedDate = Date()
            
            // Show unlock animation
            DispatchQueue.main.async {
                self.currentUnlockedAchievement = achievement
                self.showUnlockAnimation = true
            }
            
            // Add to recently unlocked
            if !self.recentlyUnlocked.contains(where: { $0.id == id }) {
                self.recentlyUnlocked.append(achievement)
            }
        }
        
        // Update the achievements array
        achievements[index] = achievement
        
        // Update in Firestore
        let db = Firestore.firestore()
        let achievementRef = db.collection("Users").document(userID).collection("Achievements").document(id)
        
        var data: [String: Any] = [
            "progress": progress
        ]
        
        if achievement.isUnlocked && oldProgress < achievement.targetValue {
            data["isUnlocked"] = true
            data["unlockedDate"] = Timestamp(date: achievement.unlockedDate ?? Date())
        }
        
        achievementRef.updateData(data) { error in
            if let error = error {
                print("Error updating achievement: \(error.localizedDescription)")
            }
        }
    }
    
    // Increment achievement progress by a specific amount
    func incrementAchievement(id: String, by amount: Int = 1) {
        guard let index = achievements.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        let currentProgress = achievements[index].progress
        updateAchievement(id: id, progress: currentProgress + amount)
    }
    
    // Check and update achievements based on study time
    func checkStudyTimeAchievements(minutes: Int) {
        // Update study time achievements
        let studyAchievements = achievements.filter { $0.category == .study }
        
        for achievement in studyAchievements {
            updateAchievement(id: achievement.id, progress: minutes)
        }
    }
    
    // Check and update streak achievements
    func checkStreakAchievements(currentStreak: Int) {
        let streakAchievements = achievements.filter { $0.category == .streak }
        
        for achievement in streakAchievements {
            if currentStreak >= achievement.targetValue {
                updateAchievement(id: achievement.id, progress: currentStreak)
            }
        }
    }
    
    // Check and update set creation achievements
    func checkSetCreationAchievements(setCount: Int) {
        let creationAchievements = achievements.filter {
            $0.category == .creation && $0.id.starts(with: "create_set")
        }
        
        for achievement in creationAchievements {
            if setCount >= achievement.targetValue {
                updateAchievement(id: achievement.id, progress: setCount)
            }
        }
    }
    
    // Check and update public set achievements
    func checkPublicSetAchievements(publicSetCount: Int) {
        let socialAchievements = achievements.filter {
            $0.category == .social && $0.id.starts(with: "public_set")
        }
        
        for achievement in socialAchievements {
            if publicSetCount >= achievement.targetValue {
                updateAchievement(id: achievement.id, progress: publicSetCount)
            }
        }
    }
    
    // Check and update profile completion achievement
    func checkProfileCompletionAchievement(isComplete: Bool) {
        if isComplete {
            updateAchievement(id: "profile_complete", progress: 1)
        }
    }
    
    // Check and update matching game achievement
    func checkMatchingGameAchievement(timeUsed: TimeInterval) {
        // Quick Matcher achievement - complete a game in under 30 seconds
        if timeUsed <= 30 {
            updateAchievement(id: "matching_game_1", progress: 1)
        }
    }
    
    // Check and update card creation achievement
    func checkCardCreationAchievement(totalCards: Int) {
        updateAchievement(id: "create_cards_50", progress: totalCards)
    }
    
    // Check and update diverse learner achievement
    func checkDiverseLearnerAchievement(uniqueSetCount: Int) {
        updateAchievement(id: "study_sets_5", progress: uniqueSetCount)
    }
}
