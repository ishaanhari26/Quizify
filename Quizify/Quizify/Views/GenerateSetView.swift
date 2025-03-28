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

//
//  GenerateSetView.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 3/22/25.
//

import SwiftUI

struct GenerateSetView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = GenerateSetViewModel()
    @State private var showConfirmation = false
   
    
    // Predefined subjects to help users with prompts
    let subjectSuggestions = [
        "World History", "Biology", "Physics", "Computer Science",
        "Mathematics", "Literature", "Chemistry", "Psychology"
    ]
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                if viewModel.generatedCards.isEmpty {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Set details section
                            setDetailsSection
                            
                            // Prompt input section
                            promptInputSection
                            
                            // Topic suggestions
                            topicSuggestionsSection
                            
                            // Generate button
                            generateButton
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                } else {
                    // Review generated cards view
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            // Set details
                            setDetailsSection
                            
                            // Generated cards list
                            generatedCardsSection
                        }
                        .padding(.bottom, 100)
                    }
                    
                    // Bottom buttons
                    bottomButtonsView
                }
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
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: $viewModel.isPublic) {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.isPublic ? "globe" : "lock")
                            .foregroundColor(viewModel.isPublic ? Color(hex: "#6082C9") : .gray)
                        
                        Text(viewModel.isPublic ? "Public - visible to all users" : "Private - only visible to you")
                            .font(.custom("Kiwi Maru Light", size: 16))
                            .foregroundColor(viewModel.isPublic ? Color(hex: "#6082C9") : .gray)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#6082C9")))
            }
            .padding(.horizontal)
            .padding(.top, 10)
        }
    }
    
    private var promptInputSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Card count slider
            VStack(alignment: .leading) {
                Text("Number of Cards: \(viewModel.cardCount)")
                    .font(.custom("Kiwi Maru Regular", size: 16))
                    .foregroundColor(.black)
                    .padding(.leading, 10)
                
                Slider(value: Binding(
                    get: { Double(viewModel.cardCount) },
                    set: { viewModel.cardCount = Int($0) }
                ), in: 5...20, step: 1)
                .accentColor(Color(hex: "#C97D60"))
                .padding(.horizontal, 10)
            }
            
            // What would you like to learn
            Text("What would you like to learn?")
                .font(.custom("Kiwi Maru Regular", size: 20))
                .foregroundColor(.black)
                .padding(.top, 10)
            
            Text("Enter a topic, subject, or specific question")
                .font(.custom("Kiwi Maru Light", size: 16))
                .foregroundColor(.gray)
            
            // Prompt text field
            TextEditor(text: $viewModel.prompt)
                .font(.custom("Kiwi Maru Regular", size: 16))
                .padding()
                .frame(minHeight: 120)
                .background(Color(hex: "#CECECE").opacity(0.2))
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color(hex: "#C97D60"), lineWidth: 1)
                )
            
            // Helper text
            Text("Example: \"Generate flashcards about the solar system\" or \"Create cards for basic Spanish vocabulary\"")
                .font(.custom("Kiwi Maru Light", size: 14))
                .foregroundColor(.gray)
                .padding(.horizontal, 10)
        }
    }
    
    private var topicSuggestionsSection: some View {
        VStack(alignment: .leading) {
            Text("Suggested Topics:")
                .font(.custom("Kiwi Maru Regular", size: 16))
                .foregroundColor(.black)
                .padding(.leading, 10)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(subjectSuggestions, id: \.self) { subject in
                        Button(action: {
                            if viewModel.prompt.isEmpty {
                                viewModel.prompt = "Generate flashcards about \(subject)"
                            } else {
                                viewModel.prompt += " related to \(subject)"
                            }
                        }) {
                            Text(subject)
                                .font(.custom("Kiwi Maru Light", size: 14))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(hex: "#C97D60").opacity(0.2))
                                .foregroundColor(Color(hex: "#C97D60"))
                                .cornerRadius(15)
                        }
                    }
                }
                .padding(.horizontal, 10)
            }
        }
    }
    
    private var generateButton: some View {
        Button(action: {
            Task {
                await viewModel.generateFlashcards()
            }
        }) {
            Text("Generate Flashcards")
                .font(.custom("Kiwi Maru Regular", size: 18))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(viewModel.prompt.isEmpty || viewModel.isGenerating ? Color(hex: "#C97D60").opacity(0.5) : Color(hex: "#C97D60"))
                .cornerRadius(20)
                .foregroundColor(.white)
        }
        .disabled(viewModel.prompt.isEmpty || viewModel.isGenerating)
        .padding(.vertical, 20)
    }
    
    private var generatedCardsSection: some View {
        VStack(alignment: .leading) {
            Text("Generated Cards (\(viewModel.generatedCards.count))")
                .font(.custom("Kiwi Maru Regular", size: 22))
                .foregroundColor(Color.gray)
                .padding(.leading, 20)
                .padding(.top, 10)
            
            // Use ForEach with the cards' id property to avoid index issues
            ForEach(viewModel.generatedCards) { card in
                let index = viewModel.generatedCards.firstIndex(where: { $0.id == card.id }) ?? 0
                
                if index < viewModel.generatedCards.count {
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
        }
        .padding(.horizontal)
    }
    
    private var bottomButtonsView: some View {
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
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            VStack {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Generating flashcards...")
                    .font(.custom("Kiwi Maru Light", size: 16))
                    .foregroundColor(.white)
                    .padding(.top, 10)
            }
            .padding(30)
            .background(Color(hex: "#C97D60").opacity(0.8))
            .cornerRadius(15)
        }
    }
}

// Generated Card View for reviewing generated cards
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
