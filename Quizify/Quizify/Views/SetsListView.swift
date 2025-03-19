//
//  SetsListView.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 3/18/25.
//

import SwiftUI

struct SetsListView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showCreateSetSheet = false
    
    var body: some View {
        NavigationView {
            VStack {
                if dataManager.sets.isEmpty {
                    ContentUnavailableView(
                        "No Sets",
                        systemImage: "folder.badge.questionmark",
                        description: Text("Create your first set to get started")
                    )
                    .padding()
                } else {
                    List {
                        ForEach(dataManager.sets) { set in
                            NavigationLink(destination: SetDetailView(setID: set.id, setTitle: set.title)) {
                                HStack(spacing: 15) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(hex: "#edae95"))
                                            .frame(width: 60, height: 60)
                                        
                                        Text("\(set.cardCount)")
                                            .font(.custom("Kiwi Maru Medium", size: 20))
                                            .foregroundColor(.white)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(set.title)
                                            .font(.custom("Kiwi Maru Regular", size: 18))
                                            .foregroundColor(.primary)
                                        
                                        if let description = set.description, !description.isEmpty {
                                            Text(description)
                                                .font(.custom("Kiwi Maru Light", size: 14))
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                        
                                        Text("\(set.cardCount) cards")
                                            .font(.custom("Kiwi Maru Light", size: 14))
                                            .foregroundColor(Color(hex: "#C97D60"))
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .onDelete(perform: deleteSet)
                    }
                }
            }
            .navigationTitle("My Sets")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showCreateSetSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateSetSheet) {
                ManualCreateView()
                    .environmentObject(dataManager)
            }
            .onAppear {
                dataManager.fetchSets()
            }
        }
    }
    
    func deleteSet(at offsets: IndexSet) {
        // Here you would add the code to delete the set from Firebase
        // For now, we'll just remove it from the local array
        // dataManager.deleteSet(at: offsets)
    }
}

// This view shows the details of a set and its cards
struct SetDetailView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var cards: [Card] = []
    @State private var isLoading = true
    
    let setID: String
    let setTitle: String
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading cards...")
            } else if cards.isEmpty {
                ContentUnavailableView(
                    "No Cards",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("This set doesn't have any cards yet")
                )
            } else {
                List {
                    ForEach(cards, id: \.id) { card in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(card.term)
                                .font(.custom("Kiwi Maru Regular", size: 18))
                                .foregroundColor(.primary)
                            
                            Divider()
                            
                            Text(card.def)
                                .font(.custom("Kiwi Maru Light", size: 16))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .navigationTitle(setTitle)
        .onAppear {
            loadCards()
        }
    }
    
    private func loadCards() {
        isLoading = true
        dataManager.fetchCardsForSet(setID: setID) { fetchedCards in
            self.cards = fetchedCards
            self.isLoading = false
        }
    }
}

#Preview {
    SetsListView()
        .environmentObject(DataManager())
}
