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
    
    @Environment(\.dismiss) var dismiss
    @State private var showDescription = false
    @State private var descriptionText = ""
    @State private var cards = [FlashCard]()
    
    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                // Orange header
                VStack {
                    // Back button and title
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .font(.system(size: 25))
                        }
                        .padding(.leading, 20)
                        
                        Spacer()
                        
                        Text("Create Set")
                            .font(.custom("Kiwi Maru Medium", size: 25))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Empty spacer for visual balance with back button
                        Color.clear.frame(width: 25, height: 25)
                            .padding(.trailing, 20)
                    }
                    .padding(.top, 70)
                    .padding(.bottom, 20)
                }
                .background(Color(hex: "#C97D60"))
                .frame(maxWidth: .infinity)
                
                // Form content
                ScrollView {
                    VStack(spacing: 20) {
                        // Title field
                        VStack(alignment: .leading) {
                            Text("Set Title")
                                .font(.custom("Kiwi Maru Regular", size: 16))
                                .foregroundColor(Color(.black))
                                .padding(.leading, 10)
                            
                            TextField("Title", text: .constant(""))
                                .textInputAutocapitalization(.never)
                                .font(.custom("Kiwi Maru Regular", size: 18))
                                .frame(height: 52)
                                .padding(.horizontal)
                                .background(Color(hex: "#CECECE").opacity(0.2))
                                .cornerRadius(20)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // Add description button
                        if !showDescription {
                            Button(action: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    showDescription = true
                                }
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
                        }
                        
                        // Description field - appears with animation
                        if showDescription {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("Description")
                                        .font(.custom("Kiwi Maru Regular", size: 16))
                                        .foregroundColor(Color(.black))
                                    
                                    Spacer()
                                    
                                    // Remove description button
                                    Button(action: {
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                            showDescription = false
                                            descriptionText = ""
                                        }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(Color(hex: "#C97D60"))
                                            .font(.system(size: 18))
                                    }
                                }
                                .padding(.leading, 10)
                                .padding(.trailing, 5)
                                
                                TextField("Description", text: $descriptionText)
                                    .textInputAutocapitalization(.never)
                                    .font(.custom("Kiwi Maru Regular", size: 18))
                                    .frame(height: 100)
                                    .padding(.horizontal)
                                    .background(Color(hex: "#CECECE").opacity(0.2))
                                    .cornerRadius(20)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }
                            .padding(.horizontal)
                            .transition(.scale.combined(with: .opacity))
                        }
                        
                        // Cards section
                        if !cards.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Cards")
                                    .font(.custom("Kiwi Maru Regular", size: 22))
                                    .foregroundColor(Color(.gray))
                                    .padding(.leading, 10)
                                    .padding(.top, 10)
                                
                                ForEach(cards) { card in
                                    CardView(card: card)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 100) // Add padding at the bottom for scrolling
                }
                
                Spacer()
                
                // Add card button
                Button(action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        cards.append(FlashCard())
                    }
                }) {
                    Text("Add Card")
                        .font(.custom("Kiwi Maru Regular", size: 18))
                        .frame(width: 233, height: 43)
                        .background(Color(hex: "#C97D60"))
                        .cornerRadius(20)
                        .foregroundColor(.white)
                }
                .padding(.bottom, 30)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
    }
}

struct CardView: View {
    var card: FlashCard
    @State private var isFocusedTerm = false
    @State private var isFocusedDef = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Term field
            VStack(alignment: .leading) {
                Text("Term")
                    .font(.custom("Kiwi Maru Regular", size: 14))
                    .foregroundColor(Color(.gray))
                    .padding(.leading, 5)
                
                TextField("Enter term", text: .constant(card.term))
                    .textInputAutocapitalization(.never)
                    .font(.custom("Kiwi Maru Regular", size: 16))
                    .padding(12)
                    .background(Color(hex: "#EFEFEF"))
                    .cornerRadius(12)
                    .onTapGesture {
                        isFocusedTerm = true
                        isFocusedDef = false
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isFocusedTerm ? Color(hex: "#C97D60") : Color.clear, lineWidth: 2)
                    )
            }
            
            // Definition field
            VStack(alignment: .leading) {
                Text("Definition")
                    .font(.custom("Kiwi Maru Regular", size: 14))
                    .foregroundColor(Color(.gray))
                    .padding(.leading, 5)
                
                TextField("Enter definition", text: .constant(card.definition))
                    .textInputAutocapitalization(.never)
                    .font(.custom("Kiwi Maru Regular", size: 16))
                    .padding(12)
                    .background(Color(hex: "#EFEFEF"))
                    .cornerRadius(12)
                    .onTapGesture {
                        isFocusedDef = true
                        isFocusedTerm = false
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isFocusedDef ? Color(hex: "#C97D60") : Color.clear, lineWidth: 2)
                    )
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.vertical, 5)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity).animation(.spring(response: 0.5, dampingFraction: 0.7)),
            removal: .scale(scale: 0.8).combined(with: .opacity).animation(.easeOut(duration: 0.3))
        ))
    }
}

#Preview {
    ManualCreateView()
}
