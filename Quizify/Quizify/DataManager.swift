//
//  DataManager.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 3/18/25.
//

import Foundation
import Firebase
import FirebaseFirestore

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
    // Update in DataManager.swift
    func fetchSets() {
        sets.removeAll()
        let db = Firestore.firestore()
        let ref = db.collection("Sets")
        ref.getDocuments { snapshot, error in
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
    
    // Add a new set and its cards to Firestore
    func addSet(title: String, description: String?, cards: [FlashCard]) {
        let db = Firestore.firestore()
        
        // Create a new document in the Sets collection
        let setRef = db.collection("Sets").document()
        let setID = setRef.documentID
        
        // Set data for the new set
        let setData: [String: Any] = [
            "title": title,
            "description": description ?? "",
            "cardCount": cards.count,
            "createdAt": Timestamp(date: Date())
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
        
        let studyData: [String: Any] = [
            "setID": setID,
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
        let studyTimesRef = db.collection("StudyTimes").whereField("setID", isEqualTo: setID)
        
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
