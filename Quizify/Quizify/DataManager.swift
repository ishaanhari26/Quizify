//
//  DataManager.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 3/18/25.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth

// Update in DataManager.swift
struct Set: Identifiable {
    var id: String
    var title: String
    var description: String?
    var cardCount: Int
    var createdAt: Date
    var totalStudyTime: TimeInterval?
    
    // Format the total study time
    var formattedStudyTime: String {
        guard let time = totalStudyTime else { return "Not studied yet" }
        
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
struct Card: Identifiable {
    var id: String
    var term: String
    var def: String
}

class DataManager: ObservableObject {
    @Published var cards: [Card] = []
    @Published var sets: [Set] = []
    
    init() {
        fetchCards()
        fetchSets()
    }
    
    func fetchCards() {
        cards.removeAll()
        let db = Firestore.firestore()
        let ref = db.collection("Card")
        ref.getDocuments { snapshot, error in
            guard error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            if let snapshot = snapshot {
                for document in snapshot.documents {
                    let data = document.data()
                    
                    let id = data["id"] as? String ?? ""
                    let term = data["term"] as? String ?? ""
                    let def = data["def"] as? String ?? ""
                    
                    let card = Card(id: id, term: term, def: def)
                    self.cards.append(card)
                }
            }
        }
    }
    func fetchSets() {
        sets.removeAll()
        let db = Firestore.firestore()
        let ref = db.collection("Sets")
        
        // Get the current user ID, if available
        guard let userID = AuthManager.shared.getUserID() else {
            print("No user is signed in")
            return
        }
        
        // Query only the sets created by the current user
        ref.whereField("userID", isEqualTo: userID).getDocuments { snapshot, error in
            guard error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            if let snapshot = snapshot {
                // Create a dispatch group to wait for all sets to be processed
                let group = DispatchGroup()
                
                var tempSets: [Set] = []
                
                for document in snapshot.documents {
                    let data = document.data()
                    
                    let id = document.documentID
                    let title = data["title"] as? String ?? ""
                    let description = data["description"] as? String
                    let cardCount = data["cardCount"] as? Int ?? 0
                    let timestamp = data["createdAt"] as? Timestamp ?? Timestamp(date: Date())
                    
                    // Create a set without study time initially
                    var newSet = Set(
                        id: id,
                        title: title,
                        description: description,
                        cardCount: cardCount,
                        createdAt: timestamp.dateValue()
                    )
                    
                    // Enter the dispatch group to fetch study time
                    group.enter()
                    
                    // Fetch study time for this set
                    self.getTotalStudyTime(setID: id) { totalTime in
                        newSet.totalStudyTime = totalTime
                        
                        tempSets.append(newSet)
                        group.leave()
                    }
                }
                
                // When all sets have been processed, sort and publish
                group.notify(queue: .main) {
                    // Sort by most recently created
                    self.sets = tempSets.sorted(by: { $0.createdAt > $1.createdAt })
                }
            }
        }
    }
    
    
    
    // Add this function to the DataManager class if it's missing or needs updating
    
    // Fetch all cards for a specific set
    func fetchCardsForSet(setID: String, completion: @escaping ([Card]) -> Void) {
        var setCards: [Card] = []
        
        let db = Firestore.firestore()
        let cardsRef = db.collection("Sets").document(setID).collection("Cards")
        
        cardsRef.order(by: "position").getDocuments { snapshot, error in
            guard error == nil else {
                print(error!.localizedDescription)
                completion([])
                return
            }
            
            if let snapshot = snapshot {
                for document in snapshot.documents {
                    let data = document.data()
                    
                    let id = document.documentID
                    let term = data["term"] as? String ?? ""
                    let def = data["definition"] as? String ?? ""
                    
                    let card = Card(id: id, term: term, def: def)
                    setCards.append(card)
                }
                completion(setCards)
            } else {
                completion([])
            }
        }
    }
    
    // Add a new set and its cards to Firestore
    func addSet(title: String, description: String?, cards: [FlashCard]) {
        let db = Firestore.firestore()
        
        // Get the current user ID, if available
        guard let userID = AuthManager.shared.getUserID() else {
            print("Cannot create set: No user is signed in")
            return
        }
        
        // Create a new document in the Sets collection
        let setRef = db.collection("Sets").document()
        let setID = setRef.documentID
        
        // Include the userID in the set data
        let setData: [String: Any] = [
            "title": title,
            "description": description ?? "",
            "cardCount": cards.count,
            "createdAt": Timestamp(date: Date()),
            "userID": userID  // Add the user ID to associate the set with the user
        ]
        
        // Create the set document
        setRef.setData(setData) { error in
            if let error = error {
                print("Error creating set: \(error.localizedDescription)")
                return
            }
            
            // After creating the set, add each card to the Cards subcollection
            for (index, card) in cards.enumerated() {
                let cardRef = setRef.collection("Cards").document()
                
                let cardData: [String: Any] = [
                    "term": card.term,
                    "definition": card.definition,
                    "position": index,
                    "createdAt": Timestamp(date: Date())
                ]
                
                cardRef.setData(cardData) { error in
                    if let error = error {
                        print("Error adding card: \(error.localizedDescription)")
                    }
                }
            }
            
            // Refresh the sets list after adding
            self.fetchSets()
        }
    }
    
    // Delete a set and all its cards from Firestore
    func deleteSet(setID: String, completion: @escaping (Bool) -> Void = { _ in }) {
        let db = Firestore.firestore()
        let setRef = db.collection("Sets").document(setID)
        
        // First, get all cards in the set to delete them
        let cardsRef = setRef.collection("Cards")
        
        // Get all documents in the Cards subcollection
        cardsRef.getDocuments { (snapshot, error) in
            if let error = error {
                print("Error getting card documents: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            // Use a batch to delete all cards and the set
            let batch = db.batch()
            
            // Add card deletions to batch
            if let snapshot = snapshot {
                for document in snapshot.documents {
                    batch.deleteDocument(document.reference)
                }
            }
            
            // Add set deletion to batch
            batch.deleteDocument(setRef)
            
            // Commit the batch deletion
            batch.commit { (error) in
                if let error = error {
                    print("Error deleting set and cards: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                // Remove the set from the local array
                if let index = self.sets.firstIndex(where: { $0.id == setID }) {
                    self.sets.remove(at: index)
                }
                
                completion(true)
            }
        }
    }
}

// Add to DataManager.swift
extension DataManager {
    // Record study time for a set
    func recordStudyTime(setID: String, duration: TimeInterval) {
        let db = Firestore.firestore()
        let studyTimeRef = db.collection("StudyTimes").document()
        
        // Get the current user ID, if available
        guard let userID = AuthManager.shared.getUserID() else {
            print("Cannot record study time: No user is signed in")
            return
        }
        
        let studyData: [String: Any] = [
            "setID": setID,
            "userID": userID,  // Include the user ID
            "duration": duration,
            "timestamp": Timestamp(date: Date())
        ]
        
        studyTimeRef.setData(studyData) { error in
            if let error = error {
                print("Error recording study time: \(error.localizedDescription)")
            }
        }
    }
    
    // Get total study time for a set
    func getTotalStudyTime(setID: String, completion: @escaping (TimeInterval) -> Void) {
        let db = Firestore.firestore()
        
        // Get the current user ID, if available
        guard let userID = AuthManager.shared.getUserID() else {
            print("Cannot get study time: No user is signed in")
            completion(0)
            return
        }
        
        // Query only study times for the current user
        let studyTimesRef = db.collection("StudyTimes")
            .whereField("setID", isEqualTo: setID)
            .whereField("userID", isEqualTo: userID)
        
        studyTimesRef.getDocuments { snapshot, error in
            guard error == nil else {
                print(error!.localizedDescription)
                completion(0)
                return
            }
            
            var totalTime: TimeInterval = 0
            
            if let snapshot = snapshot {
                for document in snapshot.documents {
                    let data = document.data()
                    
                    if let duration = data["duration"] as? TimeInterval {
                        totalTime += duration
                    }
                }
                
                completion(totalTime)
            } else {
                completion(0)
            }
        }
    }
}


// Add to DataManager.swift
extension DataManager {

    
    // Record daily study time
    func recordDailyStudyTime(date: String, duration: TimeInterval) {
        let db = Firestore.firestore()
        
        // Get the current user ID, if available
        guard let userID = AuthManager.shared.getUserID() else {
            print("Cannot record daily study time: No user is signed in")
            return
        }
        
        // Create a document ID that combines the user ID and date
        let documentID = "\(userID)_\(date)"
        let dailyRef = db.collection("DailyStudy").document(documentID)
        
        // First, check if the document exists
        dailyRef.getDocument { document, error in
            if let document = document, document.exists, let data = document.data() {
                // Document exists, update the total time
                let currentTotalTime = data["totalTime"] as? TimeInterval ?? 0
                let newTotalTime = currentTotalTime + duration
                
                // Update the document with the new total time
                dailyRef.updateData([
                    "totalTime": newTotalTime,
                    "lastUpdated": Timestamp(date: Date())
                ])
            } else {
                // Document doesn't exist, create it
                let dailyData: [String: Any] = [
                    "userID": userID,
                    "date": date,
                    "totalTime": duration,
                    "sessionCount": 1,
                    "lastUpdated": Timestamp(date: Date())
                ]
                
                dailyRef.setData(dailyData) { error in
                    if let error = error {
                        print("Error recording daily study time: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // Update study streak information
    func updateStudyStreak(date: String) {
        let db = Firestore.firestore()
        
        // Get the current user ID
        guard let userID = AuthManager.shared.getUserID() else {
            print("Cannot update streak: No user is signed in")
            return
        }
        
        // Reference to the user document
        let userRef = db.collection("Users").document(userID)
        
        userRef.getDocument { document, error in
            if let document = document, document.exists, let data = document.data() {
                // Get current streak data
                let currentStreak = data["currentStreak"] as? Int ?? 0
                let lastStudyDate = data["lastStudyDate"] as? String ?? ""
                let maxStreak = data["maxStreak"] as? Int ?? 0
                
                // Check if the streak continues
                let isStreakContinuation = self.isConsecutiveDay(lastDate: lastStudyDate, currentDate: date)
                
                // Calculate the new streak
                let newStreak: Int
                if lastStudyDate.isEmpty {
                    // First time studying
                    newStreak = 1
                } else if date == lastStudyDate {
                    // Same day, no change to streak
                    newStreak = currentStreak
                } else if isStreakContinuation {
                    // Consecutive day, increase streak
                    newStreak = currentStreak + 1
                } else {
                    // Streak broken, start new streak
                    newStreak = 1
                }
                
                // Update the document with the new streak information
                let newMaxStreak = max(maxStreak, newStreak)
                userRef.updateData([
                    "currentStreak": newStreak,
                    "lastStudyDate": date,
                    "maxStreak": newMaxStreak
                ])
            } else {
                // Document doesn't exist, create it
                let userData: [String: Any] = [
                    "currentStreak": 1,
                    "lastStudyDate": date,
                    "maxStreak": 1
                ]
                
                userRef.setData(userData) { error in
                    if let error = error {
                        print("Error updating study streak: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // Helper function to check if two dates are consecutive days
    private func isConsecutiveDay(lastDate: String, currentDate: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let last = dateFormatter.date(from: lastDate),
              let current = dateFormatter.date(from: currentDate) else {
            return false
        }
        
        let calendar = Calendar.current
        
        // Get yesterday's date
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: current) else {
            return false
        }
        
        // Check if the last study date was yesterday
        return calendar.isDate(last, inSameDayAs: yesterday)
    }
    
    // Get user's current study streak
    func getStudyStreak(completion: @escaping (Int, Int, String) -> Void) {
        let db = Firestore.firestore()
        
        // Get the current user ID
        guard let userID = AuthManager.shared.getUserID() else {
            print("Cannot get streak: No user is signed in")
            completion(0, 0, "")
            return
        }
        
        let userRef = db.collection("Users").document(userID)
        
        userRef.getDocument { document, error in
            if let document = document, document.exists, let data = document.data() {
                let currentStreak = data["currentStreak"] as? Int ?? 0
                let maxStreak = data["maxStreak"] as? Int ?? 0
                let lastStudyDate = data["lastStudyDate"] as? String ?? ""
                
                completion(currentStreak, maxStreak, lastStudyDate)
            } else {
                completion(0, 0, "")
            }
        }
    }
    
    // Get daily study data for the last N days
    func getDailyStudyData(days: Int, completion: @escaping ([StudyAnalyticsViewModel.DailyStudyData]) -> Void) {
        let db = Firestore.firestore()
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Get the current user ID
        guard let userID = AuthManager.shared.getUserID() else {
            print("Cannot get daily study data: No user is signed in")
            completion([])
            return
        }
        
        var dailyData: [StudyAnalyticsViewModel.DailyStudyData] = []
        let today = Date()
        
        // Create a dispatch group to wait for all days to be processed
        let group = DispatchGroup()
        
        for day in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -day, to: today) {
                let dateString = dateFormatter.string(from: date)
                
                // Enter the dispatch group
                group.enter()
                
                // The document ID is a combination of user ID and date
                let documentID = "\(userID)_\(dateString)"
                
                // Fetch study data for this day
                let dailyRef = db.collection("DailyStudy").document(documentID)
                dailyRef.getDocument { document, error in
                    if let document = document, document.exists, let data = document.data() {
                        if let totalTime = data["totalTime"] as? TimeInterval {
                            let minutesStudied = totalTime / 60 // Convert to minutes
                            
                            let dailyItem = StudyAnalyticsViewModel.DailyStudyData(
                                date: date,
                                minutesStudied: minutesStudied
                            )
                            
                            dailyData.append(dailyItem)
                        }
                    } else {
                        // No data for this day, record zero
                        let dailyItem = StudyAnalyticsViewModel.DailyStudyData(
                            date: date,
                            minutesStudied: 0
                        )
                        
                        dailyData.append(dailyItem)
                    }
                    
                    group.leave()
                }
            }
        }
        
        // When all days have been processed, sort and return the data
        group.notify(queue: .main) {
            let sortedData = dailyData.sorted(by: { $0.date < $1.date })
            completion(sortedData)
        }
    }
}

// Add to DataManager.swift - Public Sets Support

extension DataManager {
    // Add a new set with public visibility option
    func addSet(title: String, description: String?, cards: [FlashCard], isPublic: Bool = false) {
        let db = Firestore.firestore()
        
        // Get the current user ID, if available
        guard let userID = AuthManager.shared.getUserID() else {
            print("Cannot create set: No user is signed in")
            return
        }
        
        // Create a new document in the Sets collection
        let setRef = db.collection("Sets").document()
        let setID = setRef.documentID
        
        // Include the userID and public flag in the set data
        let setData: [String: Any] = [
            "title": title,
            "description": description ?? "",
            "cardCount": cards.count,
            "createdAt": Timestamp(date: Date()),
            "userID": userID,
            "isPublic": isPublic  // Add public visibility flag
        ]
        
        // Create the set document
        setRef.setData(setData) { error in
            if let error = error {
                print("Error creating set: \(error.localizedDescription)")
                return
            }
            
            // After creating the set, add each card to the Cards subcollection
            for (index, card) in cards.enumerated() {
                let cardRef = setRef.collection("Cards").document()
                
                let cardData: [String: Any] = [
                    "term": card.term,
                    "definition": card.definition,
                    "position": index,
                    "createdAt": Timestamp(date: Date())
                ]
                
                cardRef.setData(cardData) { error in
                    if let error = error {
                        print("Error adding card: \(error.localizedDescription)")
                    }
                }
            }
            
            // Update the user's setCount in their profile
            self.incrementUserSetCount(userID: userID)
            
            // Refresh the sets list after adding
            self.fetchSets()
        }
    }
    
    // Make an existing set public or private
    func updateSetVisibility(setID: String, isPublic: Bool, completion: @escaping (Bool) -> Void = { _ in }) {
        let db = Firestore.firestore()
        let setRef = db.collection("Sets").document(setID)
        
        setRef.updateData([
            "isPublic": isPublic
        ]) { error in
            if let error = error {
                print("Error updating set visibility: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            completion(true)
            
            // Refresh the sets list
            self.fetchSets()
        }
    }
    
    // Keep track of the number of sets a user has created
    private func incrementUserSetCount(userID: String) {
        let db = Firestore.firestore()
        let userRef = db.collection("Users").document(userID)
        
        // First get the current count
        userRef.getDocument { document, error in
            var currentCount = 0
            
            if let document = document, document.exists {
                currentCount = document.data()?["setCount"] as? Int ?? 0
            }
            
            // Increment the count
            userRef.setData([
                "setCount": currentCount + 1,
                "email": Auth.auth().currentUser?.email ?? "",
                "updatedAt": Timestamp(date: Date())
            ], merge: true) { error in
                if let error = error {
                    print("Error updating user set count: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Update user profile information
    func updateUserProfile(displayName: String? = nil, username: String? = nil, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let userID = AuthManager.shared.getUserID() else {
            completion(false)
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("Users").document(userID)
        
        var userData: [String: Any] = [
            "updatedAt": Timestamp(date: Date())
        ]
        
        if let displayName = displayName {
            userData["displayName"] = displayName
        }
        
        if let username = username {
            userData["username"] = username.lowercased()
        }
        
        // Make sure we have the email
        if let email = Auth.auth().currentUser?.email {
            userData["email"] = email
        }
        
        // Add createdAt if this is the first time
        userRef.getDocument { document, error in
            if let document = document, !document.exists {
                userData["createdAt"] = Timestamp(date: Date())
                userData["setCount"] = 0
                userData["currentStreak"] = 0
                userData["maxStreak"] = 0
            }
            
            userRef.setData(userData, merge: true) { error in
                if let error = error {
                    print("Error updating user profile: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                completion(true)
            }
        }
    }
    
    func updateUserDisplayName(username: String? = nil, displayName: String? = nil, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let userID = AuthManager.shared.getUserID(), let user = Auth.auth().currentUser else {
            completion(false)
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("Users").document(userID)
        
        // Get the existing user data
        userRef.getDocument { document, error in
            var userData: [String: Any] = [
                "updatedAt": Timestamp(date: Date())
            ]
            
            // Get email
            let email = user.email ?? ""
            userData["email"] = email
            
            // Username logic
            if let username = username, !username.isEmpty {
                userData["username"] = username.lowercased()
            } else if let existingUsername = document?.data()?["username"] as? String, !existingUsername.isEmpty {
                // Keep existing username
            } else {
                // Generate username from email if both are missing
                userData["username"] = email.components(separatedBy: "@").first?.lowercased() ?? "user"
            }
            
            // Display name logic
            if let displayName = displayName, !displayName.isEmpty {
                userData["displayName"] = displayName
            } else if let existingDisplayName = document?.data()?["displayName"] as? String, !existingDisplayName.isEmpty {
                // Keep existing display name
            } else {
                // Generate display name from username or email
                let generatedUsername = userData["username"] as? String ?? email.components(separatedBy: "@").first ?? "User"
                userData["displayName"] = generatedUsername.capitalized
            }
            
            // Add createdAt if this is the first time
            if document == nil || !document!.exists {
                userData["createdAt"] = Timestamp(date: Date())
                userData["setCount"] = 0
                userData["currentStreak"] = 0
                userData["maxStreak"] = 0
            }
            
            userRef.setData(userData, merge: true) { error in
                if let error = error {
                    print("Error updating user profile: \(error.localizedDescription)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
}

// Add this extension to the DataManager.swift file

// Extensions for handling recommended sets
extension DataManager {
    // Fetch recommended sets for the current user
    func fetchRecommendedSets(completion: @escaping ([Set]) -> Void) {
        let db = Firestore.firestore()
        
        // Get the current user ID
        guard let userID = AuthManager.shared.getUserID() else {
            completion([])
            return
        }
        
        // Fetch user's class preferences from their profile
        db.collection("Users").document(userID).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            var userClasses: [String] = []
            
            if let document = document, document.exists, let data = document.data(),
               let classes = data["apClasses"] as? [String] {
                userClasses = classes
            }
            
            if userClasses.isEmpty {
                // If no classes selected, return empty array
                completion([])
                return
            }
            
            // Query sets that match user's classes and are marked as recommended
            let ref = db.collection("Sets")
            
            // Take up to 3 classes to keep the query manageable
            let classesToQuery = Array(userClasses.prefix(3))
            
            // Build query to find sets that match selected classes
            ref.whereField("isRecommended", isEqualTo: true)
                .whereField("subject", in: classesToQuery)
                .getDocuments { snapshot, error in
                    guard error == nil else {
                        print(error!.localizedDescription)
                        completion([])
                        return
                    }
                    
                    var recommendedSets: [Set] = []
                    
                    if let snapshot = snapshot {
                        // Process results
                        for document in snapshot.documents {
                            let data = document.data()
                            
                            let id = document.documentID
                            let title = data["title"] as? String ?? ""
                            let description = data["description"] as? String
                            let cardCount = data["cardCount"] as? Int ?? 0
                            let timestamp = data["createdAt"] as? Timestamp ?? Timestamp(date: Date())
                            
                            let newSet = Set(
                                id: id,
                                title: title,
                                description: description,
                                cardCount: cardCount,
                                createdAt: timestamp.dateValue()
                            )
                            
                            recommendedSets.append(newSet)
                        }
                    }
                    
                    // Return the recommended sets
                    completion(recommendedSets)
                }
        }
    }
    
    // Save a generated recommended set to the user's library
    func saveRecommendedSet(title: String, description: String?, subject: String, cards: [FlashCard], completion: @escaping (Bool) -> Void = { _ in }) {
        guard let userID = AuthManager.shared.getUserID() else {
            completion(false)
            return
        }
        
        let db = Firestore.firestore()
        let setRef = db.collection("Sets").document()
        
        // Create set data
        let setData: [String: Any] = [
            "title": title,
            "description": description ?? "",
            "cardCount": cards.count,
            "createdAt": Timestamp(date: Date()),
            "userID": userID,
            "isPublic": false,
            "subject": subject,
            "isRecommended": true
        ]
        
        // Create the set document
        setRef.setData(setData) { error in
            if let error = error {
                print("Error creating recommended set: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            // After creating the set, add each card to the Cards subcollection
            for (index, card) in cards.enumerated() {
                let cardRef = setRef.collection("Cards").document()
                
                let cardData: [String: Any] = [
                    "term": card.term,
                    "definition": card.definition,
                    "position": index,
                    "createdAt": Timestamp(date: Date())
                ]
                
                cardRef.setData(cardData) { error in
                    if let error = error {
                        print("Error adding card: \(error.localizedDescription)")
                    }
                }
            }
            
            // Update the user's setCount in their profile
            self.incrementUserSetCount(userID: userID)
            
            // Refresh the sets list after adding
            self.fetchSets()
            
            completion(true)
        }
    }
}



extension DataManager {
    // Update achievements when a set is created
    func updateAchievementsForNewSet(cardCount: Int) {
        guard let userID = AuthManager.shared.getUserID() else { return }
        
        let db = Firestore.firestore()
        
        // Get the user's current set count
        db.collection("Users").document(userID).getDocument { document, error in
            if let document = document, document.exists, let data = document.data() {
                let setCount = data["setCount"] as? Int ?? 0
                
                // Update creation achievements
                AchievementsManager.shared.checkSetCreationAchievements(setCount: setCount)
                
                // Update card count achievement
                self.getTotalCardCount { totalCardCount in
                    AchievementsManager.shared.checkCardCreationAchievement(totalCards: totalCardCount + cardCount)
                }
            }
        }
    }
    
    // Update achievements when a set is made public
    func updateAchievementsForPublicSet() {
        guard let userID = AuthManager.shared.getUserID() else { return }
        
        let db = Firestore.firestore()
        
        // Count public sets by this user
        db.collection("Sets")
            .whereField("userID", isEqualTo: userID)
            .whereField("isPublic", isEqualTo: true)
            .getDocuments { snapshot, error in
                if let snapshot = snapshot {
                    let publicSetCount = snapshot.documents.count
                    AchievementsManager.shared.checkPublicSetAchievements(publicSetCount: publicSetCount)
                }
            }
    }
    
    // Update achievements after completing a study session
    func updateAchievementsForStudySession(setID: String, duration: TimeInterval) {
        // Convert duration to minutes for achievement tracking
        let studyMinutes = Int(duration / 60)
        
        // Get total study time
        calculateTotalStudyTime { totalMinutes in
            AchievementsManager.shared.checkStudyTimeAchievements(minutes: totalMinutes)
        }
        
        // Check for streak achievements
        getStudyStreak { currentStreak, maxStreak, _ in
            AchievementsManager.shared.checkStreakAchievements(currentStreak: currentStreak)
        }
        
        // Update diverse learner achievement (unique sets studied)
        getUniqueStudiedSetsCount { uniqueSetCount in
            AchievementsManager.shared.checkDiverseLearnerAchievement(uniqueSetCount: uniqueSetCount)
        }
    }
    
    // Calculate total study time across all sets
    private func calculateTotalStudyTime(completion: @escaping (Int) -> Void) {
        guard let userID = AuthManager.shared.getUserID() else {
            completion(0)
            return
        }
        
        let db = Firestore.firestore()
        db.collection("StudyTimes")
            .whereField("userID", isEqualTo: userID)
            .getDocuments { snapshot, error in
                var totalTime: TimeInterval = 0
                
                if let snapshot = snapshot {
                    for document in snapshot.documents {
                        if let duration = document.data()["duration"] as? TimeInterval {
                            totalTime += duration
                        }
                    }
                }
                
                // Convert to minutes
                let totalMinutes = Int(totalTime / 60)
                completion(totalMinutes)
            }
    }
    
    // Get the total number of unique sets studied
    private func getUniqueStudiedSetsCount(completion: @escaping (Int) -> Void) {
        guard let userID = AuthManager.shared.getUserID() else {
            completion(0)
            return
        }
        
        let db = Firestore.firestore()
        db.collection("StudyTimes")
            .whereField("userID", isEqualTo: userID)
            .getDocuments { snapshot, error in
                if let snapshot = snapshot {
                    // Get unique set IDs using a dictionary for uniqueness
                    var uniqueSetIDs = [String: Bool]()
                    for document in snapshot.documents {
                        if let setID = document.data()["setID"] as? String {
                            uniqueSetIDs[setID] = true
                        }
                    }
                    completion(uniqueSetIDs.count)
                } else {
                    completion(0)
                }
            }
    }
    
    // Get the total card count created by the user
    private func getTotalCardCount(completion: @escaping (Int) -> Void) {
        guard let userID = AuthManager.shared.getUserID() else {
            completion(0)
            return
        }
        
        let db = Firestore.firestore()
        db.collection("Sets")
            .whereField("userID", isEqualTo: userID)
            .getDocuments { snapshot, error in
                var totalCards = 0
                
                if let snapshot = snapshot {
                    for document in snapshot.documents {
                        if let cardCount = document.data()["cardCount"] as? Int {
                            totalCards += cardCount
                        }
                    }
                }
                
                completion(totalCards)
            }
    }
    
    // Update achievements after completing a matching game
    func updateAchievementsForMatchingGame(timeUsed: TimeInterval) {
        AchievementsManager.shared.checkMatchingGameAchievement(timeUsed: timeUsed)
    }
    
    // Update achievement when profile is completed
    func updateAchievementForProfileCompletion() {
        AchievementsManager.shared.checkProfileCompletionAchievement(isComplete: true)
    }
}
