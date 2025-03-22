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
    @State private var isDeleting = false
    @State private var showDeleteAlert = false
    @State private var setToDelete: Set? = nil
    @State private var showDeleteConfirmation = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background color
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom header
                headerView
                
                // Content
                if dataManager.sets.isEmpty {
                    emptyStateView
                } else {
                    setsList
                }
            }
        }
        .sheet(isPresented: $showCreateSetSheet) {
            ManualCreateView()
                .environmentObject(dataManager)
        }
        .alert("Delete Set", isPresented: $showDeleteConfirmation, presenting: setToDelete) { set in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteSet(set)
            }
        } message: { set in
            Text("Are you sure you want to delete \"\(set.title)\"? This action cannot be undone.")
        }
        .overlay {
            if isDeleting {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    Text("Deleting...")
                        .font(.custom("Kiwi Maru Light", size: 14))
                        .foregroundColor(.white)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.7))
                )
            }
        }
        .onAppear {
            dataManager.fetchSets()
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // MARK: - Component Views
    
    private var headerView: some View {
        ZStack {
            Color(hex: "#C97D60").ignoresSafeArea(edges: .top)
            
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.system(size: 22))
                    }
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    Text("My Sets")
                        .font(.custom("Kiwi Maru Medium", size: 25))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        showCreateSetSheet = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .font(.system(size: 22))
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 25)
                .padding(.bottom, 15)
            }
        }
        .frame(height: 75)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 25) {
            Spacer()
            
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 70))
                .foregroundColor(Color(hex: "#C97D60").opacity(0.7))
            
            Text("No Sets")
                .font(.custom("Kiwi Maru Regular", size: 24))
                .foregroundColor(Color.gray)
            
            Text("Create your first set to get started")
                .font(.custom("Kiwi Maru Light", size: 18))
                .foregroundColor(Color.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                showCreateSetSheet = true
            }) {
                Text("Create Set")
                    .font(.custom("Kiwi Maru Regular", size: 18))
                    .frame(width: 170, height: 43)
                    .background(Color(hex: "#C97D60"))
                    .cornerRadius(20)
                    .foregroundColor(.white)
            }
            .padding(.top, 20)
            .shadow(color: Color(hex: "#C97D60").opacity(0.5), radius: 5, x: 0, y: 5)
            
            Spacer()
        }
        .padding()
    }
    
    private var setsList: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(dataManager.sets) { set in
                    ZStack {
                        // Link to detail view
                        NavigationLink(destination: SetDetailView(setID: set.id, setTitle: set.title)) {
                            SetCardView(set: set)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Delete button overlay at the trailing edge
                        HStack {
                            Spacer()
                            Button(action: {
                                setToDelete = set
                                showDeleteConfirmation = true
                            }) {
                                Image(systemName: "trash.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 24))
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(Color.white)
                                    )
                                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                            }
                            .offset(x: 8, y: 0)
                        }
                        .padding(.trailing, 5)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
    }
    
    // Function to delete a set
    private func deleteSet(_ set: Set) {
        isDeleting = true
        dataManager.deleteSet(setID: set.id) { success in
            isDeleting = false
            if success {
                // The set has already been removed from the array in the dataManager
            } else {
                // Handle error case
                // You could show an alert here
            }
        }
    }
}

// Custom Set Card View component
struct SetCardView: View {
    let set: Set
    
    var body: some View {
        HStack(spacing: 15) {
            // Card count indicator
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(hex: "#edae95"))
                    .frame(width: 70, height: 70)
                
                VStack(spacing: 2) {
                    Text("\(set.cardCount)")
                        .font(.custom("Kiwi Maru Medium", size: 22))
                        .foregroundColor(.white)
                    
                    Text("cards")
                        .font(.custom("Kiwi Maru Light", size: 14))
                        .foregroundColor(.white)
                }
            }
            
            // Set details
            VStack(alignment: .leading, spacing: 8) {
                Text(set.title)
                    .font(.custom("Kiwi Maru Regular", size: 18))
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                if let description = set.description, !description.isEmpty {
                    Text(description)
                        .font(.custom("Kiwi Maru Light", size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Date formatter
                Text(formattedDate(set.createdAt))
                    .font(.custom("Kiwi Maru Light", size: 12))
                    .foregroundColor(Color(hex: "#C97D60"))
            }
            .padding(.vertical, 10)
            
            Spacer()
            
            // Chevron indicator
            Image(systemName: "chevron.right")
                .foregroundColor(Color(hex: "#C97D60"))
                .font(.system(size: 14))
                .padding(.trailing, 5)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 15)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // Format the date for display
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

// This view shows the details of a set and its cards
struct SetDetailView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var cards: [Card] = []
    @State private var isLoading = true
    @Environment(\.dismiss) var dismiss
    
    let setID: String
    let setTitle: String
    
    var body: some View {
        ZStack {
            // Background color
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom header
                ZStack {
                    Color(hex: "#C97D60").ignoresSafeArea(edges: .top)
                    
                    VStack {
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.white)
                                    .font(.system(size: 22))
                            }
                            .padding(.leading, 20)
                            
                            Spacer()
                            
                            Text(setTitle)
                                .font(.custom("Kiwi Maru Medium", size: 25))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Color.clear
                                .frame(width: 22, height: 22)
                                .padding(.trailing, 20)
                        }
                        .padding(.top, 25)
                        .padding(.bottom, 15)
                    }
                }
                .frame(height: 75)
                
                // Content
                if isLoading {
                    loadingView
                } else if cards.isEmpty {
                    emptyCardsView
                } else {
                    cardsListView
                }
            }
        }
        .onAppear {
            loadCards()
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // MARK: - Component Views
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            Text("Loading cards...")
                .font(.custom("Kiwi Maru Light", size: 16))
                .foregroundColor(.gray)
                .padding()
            Spacer()
        }
    }
    
    private var emptyCardsView: some View {
        VStack(spacing: 25) {
            Spacer()
            
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 70))
                .foregroundColor(Color(hex: "#C97D60").opacity(0.7))
            
            Text("No Cards")
                .font(.custom("Kiwi Maru Regular", size: 24))
                .foregroundColor(Color.gray)
            
            Text("This set doesn't have any cards yet")
                .font(.custom("Kiwi Maru Light", size: 18))
                .foregroundColor(Color.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
    
    private var cardsListView: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(cards, id: \.id) { card in
                    CardView(card: card)
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 100)
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

// Custom Card View component
struct CardView: View {
    let card: Card
    @State private var flipped = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
            
            VStack(alignment: .leading, spacing: 15) {
                if flipped {
                    // Definition side
                    Text("Definition")
                        .font(.custom("Kiwi Maru Regular", size: 14))
                        .foregroundColor(Color(hex: "#C97D60"))
                        .padding(.bottom, 5)
                    
                    Text(card.def)
                        .font(.custom("Kiwi Maru Regular", size: 18))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                } else {
                    // Term side
                    Text("Term")
                        .font(.custom("Kiwi Maru Regular", size: 14))
                        .foregroundColor(Color(hex: "#C97D60"))
                        .padding(.bottom, 5)
                    
                    Text(card.term)
                        .font(.custom("Kiwi Maru Regular", size: 18))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring()) {
                            flipped.toggle()
                        }
                    }) {
                        Text(flipped ? "Show Term" : "Show Definition")
                            .font(.custom("Kiwi Maru Light", size: 14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(Color(hex: "#C97D60"))
                            .cornerRadius(15)
                    }
                }
            }
            .padding(20)
        }
        .frame(height: 180)
        .padding(.vertical, 5)
    }
}

#Preview {
    SetsListView()
        .environmentObject(DataManager())
}
