//
//  GenerateSetView.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 3/22/25.
//

//
//  GenerateSetView.swift
//  Quizify
//
//  Created by Rishi Suryavanshi

import SwiftUI

struct GenerateSetView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = GenerateSetViewModel()
    @State private var showConfirmation = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        // Prompt input section
                        if viewModel.generatedCards.isEmpty {
                            promptInputSection
                        } else {
                            // Set details section (when cards have been generated)
                            setDetailsSection
                            
                            // Generated cards list
                            generatedCardsSection
                        }
                    }
                    .padding(.bottom, 100)
                }
                
                // Bottom buttons
                bottomButtonsView
            }
            
            // Loading overlay
            if viewModel.isGenerating {
                loadingOverlay
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert(viewModel.errorMessage, isPresented: Binding(
            get: { !viewModel.errorMessage.isEmpty },
            set: { if !$0 { viewModel.errorMessage = "" } }
        )) {
            Button("OK", role: .cancel) {}
        }
        .alert("Save Set", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                viewModel.saveGeneratedSet(dataManager: dataManager) {
                    dismiss()
                }
            }
        } message: {
            Text("Save this set with \(viewModel.generatedCards.count) cards?")
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
                    
                    Text("Generate Set")
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
    
    private var promptInputSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What would you like to learn?")
                .font(.custom("Kiwi Maru Regular", size: 20))
                .foregroundColor(.black)
                .padding(.top, 20)
                .padding(.horizontal)
            
            Text("Enter a topic, subject, or specific question")
                .font(.custom("Kiwi Maru Light", size: 16))
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            // Prompt text field
            TextField("e.g., 'Spanish vocabulary for beginners' or 'Photosynthesis'", text: $viewModel.prompt)
                .font(.custom("Kiwi Maru Regular", size: 16))
                .padding()
                .frame(minHeight: 100)
                .background(Color(hex: "#CECECE").opacity(0.2))
                .cornerRadius(15)
                .multilineTextAlignment(.leading)
                .padding(.horizontal)
            
            // Card count slider
            VStack(alignment: .leading) {
                Text("Number of flashcards: \(viewModel.cardCount)")
                    .font(.custom("Kiwi Maru Regular", size: 16))
                    .foregroundColor(.gray)
                
                Slider(value: Binding(
                    get: { Double(viewModel.cardCount) },
                    set: { viewModel.cardCount = Int($0) }
                ), in: 5...20, step: 1)
                .accentColor(Color(hex: "#C97D60"))
            }
            .padding(.horizontal)
            .padding(.top, 10)
        }
    }
    
    private var setDetailsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Title field
            VStack(alignment: .leading) {
                Text("Set Title")
                    .font(.custom("Kiwi Maru Regular", size: 16))
                    .foregroundColor(.black)
                    .padding(.leading, 10)
                
                TextField("Title", text: $viewModel.setTitle)
                    .font(.custom("Kiwi Maru Regular", size: 18))
                    .frame(height: 52)
                    .padding(.horizontal)
                    .background(Color(hex: "#CECECE").opacity(0.2))
                    .cornerRadius(20)
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            // Description section
            VStack {
                if !viewModel.showDescription {
                    Button(action: {
                        viewModel.showDescription = true
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
                                viewModel.showDescription = false
                                viewModel.setDescription = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color(hex: "#C97D60"))
                                    .font(.system(size: 18))
                            }
                        }
                        .padding(.leading, 10)
                        .padding(.trailing, 5)
                        
                        TextField("Description", text: $viewModel.setDescription)
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
    }
    
    private var generatedCardsSection: some View {
        VStack(alignment: .leading) {
            Text("Generated Cards (\(viewModel.generatedCards.count))")
                .font(.custom("Kiwi Maru Regular", size: 22))
                .foregroundColor(Color.gray)
                .padding(.leading, 20)
                .padding(.top, 10)
            
            ForEach(Array(viewModel.generatedCards.enumerated()), id: \.element.id) { index, card in
                GeneratedCardView(
                    index: index,
                    term: Binding(
                        get: { viewModel.generatedCards[index].term },
                        set: { viewModel.generatedCards[index].term = $0 }
                    ),
                    definition: Binding(
                        get: { viewModel.generatedCards[index].definition },
                        set: { viewModel.generatedCards[index].definition = $0 }
                    )
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var bottomButtonsView: some View {
        Group {
            if viewModel.generatedCards.isEmpty {
                // Generate button
                Button(action: {
                    Task {
                        await viewModel.generateFlashcards()
                    }
                }) {
                    Text("Generate Flashcards")
                        .font(.custom("Kiwi Maru Regular", size: 18))
                        .frame(width: 250, height: 50)
                        .background(Color(hex: "#C97D60"))
                        .cornerRadius(20)
                        .foregroundColor(.white)
                }
                .padding(.vertical, 20)
                .disabled(viewModel.prompt.isEmpty || viewModel.isGenerating)
                .opacity(viewModel.prompt.isEmpty || viewModel.isGenerating ? 0.5 : 1.0)
            } else {
                // Save and regenerate buttons
                HStack(spacing: 20) {
                    Button(action: {
                        viewModel.generatedCards = []
                    }) {
                        Text("Regenerate")
                            .font(.custom("Kiwi Maru Regular", size: 18))
                            .frame(width: 170, height: 43)
                            .background(Color(hex: "#C97D60").opacity(0.7))
                            .cornerRadius(20)
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        showConfirmation = true
                    }) {
                        Text("Save Set")
                            .font(.custom("Kiwi Maru Regular", size: 18))
                            .frame(width: 170, height: 43)
                            .background(Color(hex: "#C97D60"))
                            .cornerRadius(20)
                            .foregroundColor(.white)
                    }
                }
                .padding(.vertical, 20)
            }
        }
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            VStack {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
                Text("Generating flashcards...")
                    .font(.custom("Kiwi Maru Light", size: 16))
                    .foregroundColor(.white)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.7))
            )
        }
    }
}

// View for displaying and editing generated cards
struct GeneratedCardView: View {
    let index: Int
    @Binding var term: String
    @Binding var definition: String
    @State private var isEditing = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Card \(index + 1)")
                    .font(.custom("Kiwi Maru Regular", size: 16))
                    .foregroundColor(Color(hex: "#C97D60"))
                
                Spacer()
                
                Button(action: {
                    isEditing.toggle()
                }) {
                    Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle.fill")
                        .foregroundColor(Color(hex: "#C97D60"))
                        .font(.system(size: 20))
                }
            }
            .padding(.horizontal, 5)
            
            // Term field
            VStack(alignment: .leading) {
                Text("Term")
                    .font(.custom("Kiwi Maru Regular", size: 14))
                    .foregroundColor(Color.gray)
                    .padding(.leading, 5)
                
                if isEditing {
                    TextField("Term", text: $term)
                        .font(.custom("Kiwi Maru Regular", size: 16))
                        .padding(12)
                        .background(Color(hex: "#EFEFEF"))
                        .cornerRadius(12)
                } else {
                    Text(term)
                        .font(.custom("Kiwi Maru Regular", size: 16))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: "#EFEFEF"))
                        .cornerRadius(12)
                }
            }
            
            // Definition field
            VStack(alignment: .leading) {
                Text("Definition")
                    .font(.custom("Kiwi Maru Regular", size: 14))
                    .foregroundColor(Color.gray)
                    .padding(.leading, 5)
                
                if isEditing {
                    TextField("Definition", text: $definition, axis: .vertical)
                        .lineLimit(5)
                        .font(.custom("Kiwi Maru Regular", size: 16))
                        .padding(12)
                        .background(Color(hex: "#EFEFEF"))
                        .cornerRadius(12)
                } else {
                    Text(definition)
                        .font(.custom("Kiwi Maru Regular", size: 16))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: "#EFEFEF"))
                        .cornerRadius(12)
                }
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
    GenerateSetView()
        .environmentObject(DataManager())
}

#Preview {
    GenerateSetView()
}
