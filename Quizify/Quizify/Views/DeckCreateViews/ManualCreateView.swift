//
//  ManualCreateView.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 3/3/25.
//

import SwiftUI

struct FlashCard: Identifiable {
    let id = UUID()
    var term: String = ""
    var definition: String = ""
}

struct ManualCreateView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    
    @State private var showDescription = false
    @State private var descriptionText = ""
    @State private var titleText = ""
    @State private var cards = [FlashCard]()
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isCreatingSet = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        // Title field
                        titleField
                        
                        // Description
                        descriptionSection
                        
                        // Cards
                        cardsList
                    }
                    .padding(.bottom, 100)
                }
                
                // Bottom buttons
                bottomButtons
            }
            
            // Loading overlay
            if isCreatingSet {
                loadingOverlay
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
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
                    
                    Text("Create Set")
                        .font(.custom("Kiwi Maru Medium", size: 25))
                        .foregroundColor(.white)
                    
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
    }
    
    private var titleField: some View {
        VStack(alignment: .leading) {
            Text("Set Title")
                .font(.custom("Kiwi Maru Regular", size: 16))
                .foregroundColor(.black)
                .padding(.leading, 10)
            
            TextField("Title", text: $titleText)
                .font(.custom("Kiwi Maru Regular", size: 18))
                .frame(height: 52)
                .padding(.horizontal)
                .background(Color(hex: "#CECECE").opacity(0.2))
                .cornerRadius(20)
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }
    
    private var descriptionSection: some View {
        VStack {
            if !showDescription {
                Button(action: {
                    showDescription = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color(hex: "#C97D60"))
                        
                        Text("Add Description")
                            .font(.custom("Kiwi Maru Regular", size: 16))
                            .foregroundColor(Color(hex: "#C97D60"))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 15)
                    .background(Color(hex: "#CECECE").opacity(0.1))
                    .cornerRadius(15)
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Description")
                            .font(.custom("Kiwi Maru Regular", size: 16))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Button(action: {
                            showDescription = false
                            descriptionText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color(hex: "#C97D60"))
                                .font(.system(size: 18))
                        }
                    }
                    .padding(.leading, 10)
                    .padding(.trailing, 5)
                    
                    TextField("Description", text: $descriptionText)
                        .font(.custom("Kiwi Maru Regular", size: 18))
                        .frame(height: 100)
                        .padding(.horizontal)
                        .background(Color(hex: "#CECECE").opacity(0.2))
                        .cornerRadius(20)
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var cardsList: some View {
        VStack {
            if !cards.isEmpty {
                VStack(alignment: .leading) {
                    Text("Cards")
                        .font(.custom("Kiwi Maru Regular", size: 22))
                        .foregroundColor(Color.gray)
                        .padding(.leading, 10)
                        .padding(.top, 10)
                    
                    ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                        SimpleCardView(
                            index: index,
                            term: Binding(
                                get: { self.cards[index].term },
                                set: { self.cards[index].term = $0 }
                            ),
                            definition: Binding(
                                get: { self.cards[index].definition },
                                set: { self.cards[index].definition = $0 }
                            ),
                            onRemove: {
                                self.cards.remove(at: index)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var bottomButtons: some View {
        HStack(spacing: 20) {
            Button(action: {
                cards.append(FlashCard())
            }) {
                Text("Add Card")
                    .font(.custom("Kiwi Maru Regular", size: 18))
                    .frame(width: 170, height: 43)
                    .background(Color(hex: "#C97D60"))
                    .cornerRadius(20)
                    .foregroundColor(.white)
            }
            
            Button(action: {
                saveSet()
            }) {
                Text("Save Set")
                    .font(.custom("Kiwi Maru Regular", size: 18))
                    .frame(width: 170, height: 43)
                    .background(Color(hex: "#C97D60"))
                    .cornerRadius(20)
                    .foregroundColor(.white)
                    .opacity(isCreatingSet ? 0.5 : 1.0)
            }
            .disabled(isCreatingSet)
        }
        .padding(.vertical, 20)
    }
    
    private var loadingOverlay: some View {
        ProgressView()
            .scaleEffect(1.5)
            .padding()
            .background(Color.white.opacity(0.7))
            .cornerRadius(10)
    }
    
    // MARK: - Functions
    
    private func saveSet() {
        // Validate input
        guard !titleText.isEmpty else {
            alertMessage = "Please add a title for your set"
            showAlert = true
            return
        }
        
        guard !cards.isEmpty else {
            alertMessage = "Please add at least one card to your set"
            showAlert = true
            return
        }
        
        // Make sure all cards have both term and definition
        let emptyCards = cards.filter { $0.term.isEmpty || $0.definition.isEmpty }
        if !emptyCards.isEmpty {
            alertMessage = "Please complete all cards with both term and definition"
            showAlert = true
            return
        }
        
        // Save to Firebase
        isCreatingSet = true
        
        // Use the dataManager to save the set and its cards
        dataManager.addSet(
            title: titleText,
            description: showDescription ? descriptionText : nil,
            cards: cards
        )
        
        // Wait a moment before dismissing to allow Firebase operation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isCreatingSet = false
            dismiss()
        }
    }
}

// Simplified card view without complex animations
struct SimpleCardView: View {
    let index: Int
    @Binding var term: String
    @Binding var definition: String
    var onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Card \(index + 1)")
                    .font(.custom("Kiwi Maru Regular", size: 16))
                    .foregroundColor(Color(hex: "#C97D60"))
                
                Spacer()
                
                Button(action: onRemove) {
                    Image(systemName: "trash.fill")
                        .foregroundColor(Color.red.opacity(0.7))
                        .font(.system(size: 16))
                }
            }
            .padding(.horizontal, 5)
            
            // Term field
            VStack(alignment: .leading) {
                Text("Term")
                    .font(.custom("Kiwi Maru Regular", size: 14))
                    .foregroundColor(Color.gray)
                    .padding(.leading, 5)
                
                TextField("Enter term", text: $term)
                    .font(.custom("Kiwi Maru Regular", size: 16))
                    .padding(12)
                    .background(Color(hex: "#EFEFEF"))
                    .cornerRadius(12)
            }
            
            // Definition field
            VStack(alignment: .leading) {
                Text("Definition")
                    .font(.custom("Kiwi Maru Regular", size: 14))
                    .foregroundColor(Color.gray)
                    .padding(.leading, 5)
                
                TextField("Enter definition", text: $definition)
                    .font(.custom("Kiwi Maru Regular", size: 16))
                    .padding(12)
                    .background(Color(hex: "#EFEFEF"))
                    .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.vertical, 5)
    }
}



#Preview {
    ManualCreateView()
        .environmentObject(DataManager())
}
