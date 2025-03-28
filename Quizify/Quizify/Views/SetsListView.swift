//
//  SetsListView.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 3/18/25.
//

import SwiftUI
import FirebaseFirestore

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

// Update SetCardView in SetsListView.swift
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
                        .lineLimit(1)
                }
                
                // Study time and date info
                HStack {
                    // Date formatter
                    Text(formattedDate(set.createdAt))
                        .font(.custom("Kiwi Maru Light", size: 12))
                        .foregroundColor(Color(hex: "#C97D60"))
                    
                    // Study time if available
                    if let totalTime = set.totalStudyTime, totalTime > 0 {
                        Circle()
                            .fill(Color(hex: "#C97D60").opacity(0.5))
                            .frame(width: 4, height: 4)
                        
                        HStack(spacing: 2) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: "#C97D60"))
                            
                            Text(set.formattedStudyTime)
                                .font(.custom("Kiwi Maru Light", size: 12))
                                .foregroundColor(Color(hex: "#C97D60"))
                        }
                    }
                }
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
    @State private var currentCardIndex = 0
    @State private var flipped = false
    @Environment(\.dismiss) var dismiss
    @StateObject private var timeTracker = StudyTimeTracker()
    @State private var showVisibilityToggle = false
    @State private var isOwner = false
    
    let setID: String
    let setTitle: String
    
    var body: some View {
        ZStack {
            // Background color
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom header
                headerView
                
                if isOwner {
                    HStack {
                        Spacer()
                        SetVisibilityToggle(setID: setID)
                            .frame(width: 150)
                            .padding(.trailing, 20)
                    }
                    .padding(.top, 10)
                }
                
                if timeTracker.isTracking {
                    studyTimerView
                }
                
                // Content
                if isLoading {
                    loadingView
                } else if cards.isEmpty {
                    emptyCardsView
                } else {
                    // Make the entire content area scrollable
                    ScrollViewReader { scrollProxy in
                        ScrollView {
                            VStack(spacing: 20) {
                                // Card counter
                                Text("Card \(currentCardIndex + 1) of \(cards.count)")
                                    .font(.custom("Kiwi Maru Light", size: 16))
                                    .foregroundColor(Color(hex: "#C97D60"))
                                    .padding(.top, 20)
                                    .id("topCard") // ID for scrolling
                                
                                // Current flashcard
                                flashcardView
                                    .padding(.horizontal, 20)
                                
                                // Navigation controls
                                navigationControls
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 20)
                                
                                // Divider
                                Rectangle()
                                    .fill(Color(hex: "#EEEEEE"))
                                    .frame(height: 1)
                                    .padding(.horizontal, 20)
                                
                                // All cards list header
                                Text("All Cards")
                                    .font(.custom("Kiwi Maru Regular", size: 20))
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 10)
                                
                                // Cards list (now part of the main ScrollView)
                                VStack(spacing: 15) {
                                    ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                                        CompactCardView(
                                            card: card,
                                            isSelected: index == currentCardIndex,
                                            onTap: {
                                                withAnimation {
                                                    currentCardIndex = index
                                                    flipped = false
                                                    
                                                    // Scroll to the top card with animation
                                                    withAnimation {
                                                        scrollProxy.scrollTo("topCard", anchor: .top)
                                                    }
                                                }
                                            }
                                        )
                                        .padding(.horizontal, 20)
                                    }
                                }
                                .padding(.bottom, 80)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            loadCards()
            
            // Start tracking time when view appears
            if !timeTracker.isTracking {
                timeTracker.startTracking(setID: setID)
            }
            
            // Check if current user is the owner of this set
            checkOwnership()
        }
        .onDisappear {
            // Stop tracking when view disappears
            if timeTracker.isTracking {
                timeTracker.stopTracking(dataManager: dataManager)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private var studyTimerView: some View {
        HStack {
            Image(systemName: "clock")
                .foregroundColor(Color(hex: "#C97D60"))
            
            Text(timeTracker.formattedTime(from: timeTracker.elapsedTime))
                .font(.custom("Kiwi Maru Regular", size: 16))
                .foregroundColor(Color(hex: "#C97D60"))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 15)
        .background(Color(hex: "#C97D60").opacity(0.1))
        .cornerRadius(15)
        .padding(.top, 10)
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
                    
                    Text(setTitle)
                        .font(.custom("Kiwi Maru Medium", size: 25))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Add a game button
                    NavigationLink(destination: MatchingGameView(setID: setID, setTitle: setTitle)) {
                        Image(systemName: "gamecontroller.fill")
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
    
//    ADD ANYWHERE
//    Button(action: {
//        // This action will be handled by the NavigationLink
//    }) {
//        NavigationLink(destination: MatchingGameView(setID: setID, setTitle: setTitle)) {
//            ZStack {
//                Circle()
//                    .fill(Color(hex: "#6082C9"))
//                    .frame(width: 60, height: 60)
//                
//                Image(systemName: "gamecontroller.fill")
//                    .font(.system(size: 24))
//                    .foregroundColor(.white)
//            }
//        }
//    }
    
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
    
    private var flashcardView: some View {
        ZStack {
            // Card
            VStack {
                ZStack {
                    // Card background with shadow
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                        .contentShape(Rectangle()) // Make the entire card tappable
                    
                    // Fixed position for Term/Definition label
                    VStack {
                        HStack {
                            Text(flipped ? "Definition" : "Term")
                                .font(.custom("Kiwi Maru Regular", size: 16))
                                .foregroundColor(Color(hex: "#C97D60"))
                                .padding(.top, 25)
                                .padding(.leading, 25)
                            Spacer()
                        }
                        Spacer()
                    }
                    .zIndex(2) // Ensure the label stays on top
                    
                    // Front of card (Term)
                    if !flipped && cards.indices.contains(currentCardIndex) {
                        VStack(alignment: .leading, spacing: 15) {
                            // Empty space to account for the fixed label
                            Text("")
                                .font(.custom("Kiwi Maru Regular", size: 16))
                                .padding(.bottom, 10)
                            
                            // Term content
                            Text(cards[currentCardIndex].term)
                                .font(.custom("Kiwi Maru Regular", size: 22))
                                .foregroundColor(.black)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 20) // Add some space below the fixed label
                            
                            Spacer()
                        }
                        .padding(25)
                    }
                    
                    // Back of card (Definition) - Note the rotation to make text readable when flipped
                    if flipped && cards.indices.contains(currentCardIndex) {
                        VStack(alignment: .leading, spacing: 15) {
                            // Empty space to account for the fixed label
                            Text("")
                                .font(.custom("Kiwi Maru Regular", size: 16))
                                .padding(.bottom, 10)
                            
                            // Definition content
                            Text(cards[currentCardIndex].def)
                                .font(.custom("Kiwi Maru Regular", size: 22))
                                .foregroundColor(.black)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 20) // Add some space below the fixed label
                            
                            Spacer()
                        }
                        .padding(25)
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                    }
                }
                .rotation3DEffect(
                    .degrees(flipped ? 180 : 0),
                    axis: (x: 0.0, y: 1.0, z: 0.0)
                )
                .onTapGesture {
                    withAnimation(.spring()) {
                        flipped.toggle()
                    }
                }
            }
            .frame(height: 300)
        }
    }
    
    private var navigationControls: some View {
        HStack(spacing: 30) {
            // Previous button
            Button(action: {
                withAnimation {
                    flipped = false
                    currentCardIndex = max(0, currentCardIndex - 1)
                }
            }) {
                Image(systemName: "arrow.left.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(currentCardIndex > 0 ? Color(hex: "#C97D60") : Color.gray.opacity(0.5))
            }
            .disabled(currentCardIndex <= 0)
            
            Spacer()
            
            // Flip button (larger center button)
            Button(action: {
                withAnimation(.spring()) {
                    flipped.toggle()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#C97D60"))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            // Next button
            Button(action: {
                withAnimation {
                    flipped = false
                    currentCardIndex = min(cards.count - 1, currentCardIndex + 1)
                }
            }) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(currentCardIndex < cards.count - 1 ? Color(hex: "#C97D60") : Color.gray.opacity(0.5))
            }
            .disabled(currentCardIndex >= cards.count - 1)
        }
        .padding(.vertical, 10)
    }
    
    
    
    private func checkOwnership() {
        guard let currentUserID = AuthManager.shared.getUserID() else {
            isOwner = false
            return
        }
        
        let db = Firestore.firestore()
        db.collection("Sets").document(setID).getDocument { document, error in
            if let document = document, document.exists {
                let ownerID = document.data()?["userID"] as? String ?? ""
                self.isOwner = (ownerID == currentUserID)
            } else {
                self.isOwner = false
            }
        }
    }
    
    // Removed allCardsList since it's now integrated directly in the body
    
    private func loadCards() {
        isLoading = true
        dataManager.fetchCardsForSet(setID: setID) { fetchedCards in
            self.cards = fetchedCards
            self.isLoading = false
        }
    }
}

// Compact card view for the list of all cards
struct CompactCardView: View {
    let card: Card
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 15) {
                // Term preview
                VStack(alignment: .leading, spacing: 5) {
                    Text(card.term)
                        .font(.custom("Kiwi Maru Regular", size: 16))
                        .foregroundColor(.black)
                        .lineLimit(1)
                    
                    Text(card.def)
                        .font(.custom("Kiwi Maru Light", size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(hex: "#C97D60"))
                    .font(.system(size: 14))
            }
            .padding(15)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: "#C97D60").opacity(0.1) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color(hex: "#C97D60") : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SetsListView()
        .environmentObject(DataManager())
}
