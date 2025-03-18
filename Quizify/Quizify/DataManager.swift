//
//  DataManager.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 3/18/25.
//

import Foundation
import Firebase
import FirebaseFirestore



class DataManager: ObservableObject {
    @Published var sets: [Set] = []
    @Published var cards: [Card] = []
    
    init() {
        fetchCards()
    }
    
    func fetchCards(){
        
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
    
    
    func fetchSets(){
       
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
                    
                    let id = data["id"] as? String ?? ""
                    let title = data["title"] as? String ?? ""
                    let description = data["description"] as? String ?? ""
                    
                    
                    let set = Set(id: id, title: title, description: description)
                    self.sets.append(set)
                }
            }
            
            
        }
        
    }
    
    //Def parameter
    func addCard(term: String ){
        let db = Firestore.firestore()
        let ref = db.collection("Card").document(term)
        //You can add Def in this
        ref.setData(["term" : term, "id" : 10 ]) { error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
}
