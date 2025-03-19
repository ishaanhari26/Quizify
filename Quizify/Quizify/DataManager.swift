//
//  DataManager.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 3/18/25.
//

//
//  DataManager.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 3/18/25.
//

import Foundation
import Firebase
import FirebaseFirestore

struct Set: Identifiable {
    var id: String
    var title: String
    var description: String?
    var cardCount: Int
    var createdAt: Date
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
        ref.getDocuments { snapshot, error in
            guard error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            if let snapshot = snapshot {
                for document in snapshot.documents {
                    let data = document.data()
                    
                    let id = document.documentID
                    let title = data["title"] as? String ?? ""
                    let description = data["description"] as? String
                    let cardCount = data["cardCount"] as? Int ?? 0
                    let timestamp = data["createdAt"] as? Timestamp ?? Timestamp(date: Date())
                    
                    let set = Set(
                        id: id,
                        title: title,
                        description: description,
                        cardCount: cardCount,
                        createdAt: timestamp.dateValue()
                    )
                    self.sets.append(set)
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
    
    // Legacy method - backward compatibility
    func addCard(term: String, def: String = "") {
        let db = Firestore.firestore()
        let ref = db.collection("Card").document(term)
        ref.setData(["term": term, "def": def, "id": term]) { error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
}
