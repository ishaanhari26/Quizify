import SwiftUI
import Firebase
import FirebaseFirestore

// Model to represent a recommended set
struct RecommendedSet: Identifiable {
    var id = UUID()
    var title: String
    var description: String?
    var subject: String
    var cardCount: Int
    var isLoading: Bool = false
    var isFavorite: Bool = false
}

class RecommendedSetsViewModel: ObservableObject {
    @Published var recommendedSets: [RecommendedSet] = []
    @Published var isLoading: Bool = true
    @Published var errorMessage: String = ""
    
    private var userClasses: [String] = []
    
    func loadUserClasses() {
        guard let userID = AuthManager.shared.getUserID() else {
            self.isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        db.collection("Users").document(userID).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = "Error loading user classes: \(error.localizedDescription)"
                self.isLoading = false
                return
            }
            
            if let document = document, document.exists, let data = document.data() {
                if let classes = data["apClasses"] as? [String] {
                    self.userClasses = classes
                    self.generateRecommendedSets(from: classes)
                } else {
                    self.errorMessage = "No classes found in user profile"
                    self.isLoading = false
                }
            } else {
                self.errorMessage = "User profile not found"
                self.isLoading = false
            }
        }
    }
    
    func generateRecommendedSets(from classes: [String]) {
        // Clear existing recommendations
        recommendedSets = []
        
        // Take up to 3 classes to generate recommendations for
        let classesToUse = Array(classes.prefix(3))
        
        if classesToUse.isEmpty {
            // If no classes selected, provide some generic recommendations
            recommendedSets = [
                RecommendedSet(title: "Study Techniques", description: "Effective methods for academic success", subject: "General", cardCount: 10),
                RecommendedSet(title: "Memory Enhancement", description: "Techniques to improve recall and retention", subject: "General", cardCount: 8),
                RecommendedSet(title: "Test Preparation", description: "Strategies for exam success", subject: "General", cardCount: 12)
            ]
            isLoading = false
            return
        }
        
        // Generate recommendations based on selected classes
        for classSubject in classesToUse {
            // Create initial placeholders that will be replaced by Gemini-generated content
            let subjectShort = classSubject.replacingOccurrences(of: "AP ", with: "")
            
            // Add 1-2 recommended sets per subject
            let mainSet = RecommendedSet(
                title: "Key Concepts: \(subjectShort)",
                description: "Essential concepts and terminology for \(classSubject)",
                subject: classSubject,
                cardCount: Int.random(in: 8...15)
            )
            recommendedSets.append(mainSet)
            
            if Bool.random() { // Add a second set for some subjects to vary the recommendations
                let topics = getTopicForSubject(classSubject)
                recommendedSets.append(RecommendedSet(
                    title: topics.0,
                    description: topics.1,
                    subject: classSubject,
                    cardCount: Int.random(in: 6...12)
                ))
            }
        }
        
        // In a real implementation, we would call Gemini API here to generate actual content
        // For now we'll simulate that these sets already have content
        isLoading = false
    }
    
    // Helper method to get specific topics based on subject
    private func getTopicForSubject(_ subject: String) -> (String, String) {
        switch subject {
        case "AP Biology":
            return ("Cell Structure & Function", "Understanding cellular components and processes")
        case "AP Chemistry":
            return ("Periodic Trends", "Properties and patterns in the periodic table")
        case "AP Physics 1", "AP Physics 2", "AP Physics C":
            return ("Forces & Motion", "Understanding Newton's laws and applications")
        case "AP Calculus AB", "AP Calculus BC":
            return ("Derivatives & Applications", "Mastering differentiation techniques and uses")
        case "AP Statistics":
            return ("Probability Distributions", "Understanding normal, binomial and other distributions")
        case "AP Computer Science A", "AP Computer Science Principles":
            return ("Data Structures", "Arrays, linked lists, and algorithm efficiency")
        case "AP U.S. History":
            return ("American Revolution", "Key events, figures, and impacts of the revolution")
        case "AP World History":
            return ("Industrial Revolution", "Global impacts of industrialization")
        case "AP English Language", "AP English Literature":
            return ("Rhetorical Strategies", "Understanding ethos, pathos, logos and rhetorical techniques")
        case "AP Government":
            return ("Constitutional Framework", "Structure and principles of the U.S. Constitution")
        case "AP Economics":
            return ("Supply & Demand", "Market forces and economic equilibrium")
        case "AP Psychology":
            return ("Brain & Behavior", "Neurological basis of psychological processes")
        default:
            return ("Important Concepts", "Key topics and terminology for your course")
        }
    }
    
    // This function would call the Gemini API to generate flashcards for a set
    func generateCardsForSet(_ setIndex: Int) async {
        guard setIndex < recommendedSets.count else { return }
        
        // Mark the set as loading
        DispatchQueue.main.async {
            self.recommendedSets[setIndex].isLoading = true
        }
        
        // Get the set details
        let set = recommendedSets[setIndex]
        
        // Prepare prompt for Gemini API
        let prompt = "Generate \(set.cardCount) flashcards for \(set.subject) on the topic of \(set.title). Include key terms and definitions appropriate for AP level study."
        
        do {
            // Call Gemini to generate cards
            let cards = try await GeminiService.shared.generateFlashcards(from: prompt, cardCount: set.cardCount)
            
            // In a real implementation, we would save these cards to Firestore
            // For now, we just simulate success
            DispatchQueue.main.async {
                self.recommendedSets[setIndex].isLoading = false
                self.recommendedSets[setIndex].isFavorite = true
            }
            
            // Save the set to user's collection - this would call DataManager
            await saveRecommendedSet(set: set, cards: cards)
            
        } catch {
            DispatchQueue.main.async {
                self.recommendedSets[setIndex].isLoading = false
                self.errorMessage = "Failed to generate cards: \(error.localizedDescription)"
            }
        }
    }
    
    // Save the generated set to the user's collection
    private func saveRecommendedSet(set: RecommendedSet, cards: [FlashCard]) async {
        guard let userID = AuthManager.shared.getUserID() else { return }
        
        let db = Firestore.firestore()
        let setRef = db.collection("Sets").document()
        
        // Create set data
        let setData: [String: Any] = [
            "title": set.title,
            "description": set.description ?? "",
            "cardCount": cards.count,
            "createdAt": Timestamp(date: Date()),
            "userID": userID,
            "isPublic": false,
            "subject": set.subject,
            "isRecommended": true
        ]
        
        do {
            // Save the set
            try await setRef.setData(setData)
            
            // Save each card
            for (index, card) in cards.enumerated() {
                let cardRef = setRef.collection("Cards").document()
                
                let cardData: [String: Any] = [
                    "term": card.term,
                    "definition": card.definition,
                    "position": index,
                    "createdAt": Timestamp(date: Date())
                ]
                
                try await cardRef.setData(cardData)
            }
            
            print("Successfully saved recommended set: \(set.title)")
        } catch {
            print("Error saving recommended set: \(error.localizedDescription)")
        }
    }
}

struct RecommendedSetsView: View {
    @StateObject private var viewModel = RecommendedSetsViewModel()
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Recommended Sets")
                    .font(.custom("Kiwi Maru Light", size: 25))
                    .foregroundColor(Color(.gray))
                
                Spacer()
                
                Button(action: {
                    viewModel.loadUserClasses()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#C97D60"))
                }
            }
            .padding(.leading, 30)
            .padding(.trailing, 30)
            .padding(.bottom, 10)
            
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                        .padding()
                    Spacer()
                }
            } else if viewModel.recommendedSets.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "lightbulb")
                            .font(.system(size: 30))
                            .foregroundColor(Color(hex: "#C97D60").opacity(0.7))
                        
                        Text("Add classes in your profile to get personalized set recommendations")
                            .font(.custom("Kiwi Maru Light", size: 16))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.vertical, 30)
                    Spacer()
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(Array(viewModel.recommendedSets.enumerated()), id: \.element.id) { index, set in
                            RecommendedSetCard(
                                set: set,
                                onAddToFavorites: {
                                    Task {
                                        await viewModel.generateCardsForSet(index)
                                        
                                        // Refresh sets after adding
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                            dataManager.fetchSets()
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 30)
                }
            }
            
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .font(.custom("Kiwi Maru Light", size: 14))
                    .foregroundColor(.red)
                    .padding(.horizontal, 30)
            }
        }
        .onAppear {
            viewModel.loadUserClasses()
        }
    }
}

struct RecommendedSetCard: View {
    let set: RecommendedSet
    let onAddToFavorites: () -> Void
    @EnvironmentObject var dataManager: DataManager
    @State private var navigateToDetail = false
    
    var body: some View {
        NavigationLink(destination: RecommendedSetDetailView(set: set, dataManager: dataManager), isActive: $navigateToDetail) {
            EmptyView()
        }
        .opacity(0)
        
        Button(action: {
            // Only navigate if the set is already saved or when tapping elsewhere
            if set.isFavorite {
                navigateToDetail = true
            }
        }) {
            VStack(alignment: .leading, spacing: 10) {
                // Subject indicator
                Text(set.subject.replacingOccurrences(of: "AP ", with: "AP: "))
                    .font(.custom("Kiwi Maru Light", size: 12))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#6082C9"))
                    .cornerRadius(10)
                    .padding(.horizontal, 10)
                    .padding(.top, 10)
                
                Spacer()
                
                // Set title
                Text(set.title)
                    .font(.custom("Kiwi Maru Regular", size: 16))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 10)
                
                // Description
                if let description = set.description {
                    Text(description)
                        .font(.custom("Kiwi Maru Light", size: 12))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 10)
                }
                
                // Card count & add button
                HStack {
                    Text("\(set.cardCount) cards")
                        .font(.custom("Kiwi Maru Light", size: 12))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    if set.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else if set.isFavorite {
                        // View button
                        Image(systemName: "eye.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 18))
                    } else {
                        // Add button (tap-area limited to button only)
                        Button(action: {
                            onAddToFavorites()
                            // Prevent card click-through
                            return
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 18))
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
            .frame(width: 180, height: 165)
            .background(Color(hex: "#C97D60"))
            .cornerRadius(15)
        }
    }
}

// Detailed view for a recommended set
struct RecommendedSetDetailView: View {
    let set: RecommendedSet
    let dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    @State private var cards: [FlashCard] = []
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
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
                            
                            Text(set.title)
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
                    Spacer()
                    VStack(spacing: 15) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Generating preview...")
                            .font(.custom("Kiwi Maru Light", size: 16))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else if cards.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Set info
                            VStack(alignment: .leading, spacing: 10) {
                                // Subject badge
                                Text(set.subject)
                                    .font(.custom("Kiwi Maru Regular", size: 14))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(hex: "#6082C9"))
                                    .cornerRadius(15)
                                
                                if let description = set.description {
                                    Text(description)
                                        .font(.custom("Kiwi Maru Light", size: 16))
                                        .foregroundColor(.gray)
                                        .padding(.top, 5)
                                }
                                
                                Text("\(cards.count) cards")
                                    .font(.custom("Kiwi Maru Regular", size: 14))
                                    .foregroundColor(Color(hex: "#C97D60"))
                                    .padding(.top, 5)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            Divider()
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                            
                            // Sample cards preview
                            Text("Sample Cards")
                                .font(.custom("Kiwi Maru Regular", size: 18))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                            
                            // Preview up to 3 cards
                            ForEach(cards.prefix(3)) { card in
                                previewCardView(card: card)
                            }
                            
                            // Add to my sets button
                            if !set.isFavorite {
                                Button(action: {
                                    // Save the set to user's library
                                    addToMyLibrary()
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 16))
                                        
                                        Text("Add to My Sets")
                                            .font(.custom("Kiwi Maru Regular", size: 16))
                                    }
                                    .foregroundColor(.white)
                                    .frame(width: 200, height: 45)
                                    .background(Color(hex: "#C97D60"))
                                    .cornerRadius(20)
                                    .padding(.top, 20)
                                    .padding(.bottom, 30)
                                }
                            } else {
                                Text("This set is in your library")
                                    .font(.custom("Kiwi Maru Light", size: 16))
                                    .foregroundColor(Color(hex: "#C97D60"))
                                    .padding(.top, 20)
                                    .padding(.bottom, 30)
                            }
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            generatePreviewCards()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundColor(Color(hex: "#C97D60"))
            
            Text("Ready to Generate")
                .font(.custom("Kiwi Maru Regular", size: 20))
                .foregroundColor(.black)
            
            Text("Add this set to your library to generate flashcards")
                .font(.custom("Kiwi Maru Light", size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Button(action: {
                addToMyLibrary()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    
                    Text("Add to My Sets")
                        .font(.custom("Kiwi Maru Regular", size: 16))
                }
                .foregroundColor(.white)
                .frame(width: 200, height: 45)
                .background(Color(hex: "#C97D60"))
                .cornerRadius(20)
                .padding(.top, 20)
            }
            
            Spacer()
        }
    }
    
    private func previewCardView(card: FlashCard) -> some View {
        VStack(spacing: 12) {
            // Term
            VStack(alignment: .leading) {
                Text("Term")
                    .font(.custom("Kiwi Maru Regular", size: 14))
                    .foregroundColor(Color.gray)
                    .padding(.leading, 5)
                
                Text(card.term)
                    .font(.custom("Kiwi Maru Regular", size: 16))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "#EFEFEF"))
                    .cornerRadius(12)
            }
            
            // Definition
            VStack(alignment: .leading) {
                Text("Definition")
                    .font(.custom("Kiwi Maru Regular", size: 14))
                    .foregroundColor(Color.gray)
                    .padding(.leading, 5)
                
                Text(card.definition)
                    .font(.custom("Kiwi Maru Regular", size: 16))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "#EFEFEF"))
                    .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 20)
        .padding(.vertical, 5)
    }
    
    // Generate sample flashcards for preview
    private func generatePreviewCards() {
        isLoading = true
        
        // For an already saved set, try to fetch its actual cards
        if set.isFavorite {
            // Attempt to find the actual set ID in the user's library
            Task {
                await fetchExistingCards()
            }
            return
        }
        
        // For non-saved sets, generate preview cards
        Task {
            do {
                // Generate sample cards using Gemini API
                let prompt = "Generate 3 sample flashcards for \(set.subject) on the topic of \(set.title)."
                let sampleCards = try await GeminiService.shared.generateFlashcards(from: prompt, cardCount: 3)
                
                DispatchQueue.main.async {
                    self.cards = sampleCards
                    self.isLoading = false
                }
            } catch {
                // Generate fallback cards if API fails
                let fallbackCards = generateFallbackCards(for: set.subject, title: set.title)
                
                DispatchQueue.main.async {
                    self.cards = fallbackCards
                    self.isLoading = false
                }
            }
        }
    }
    
    // Attempt to find and fetch cards for an existing set
    private func fetchExistingCards() async {
        // Search for a set with matching title and subject
        let db = Firestore.firestore()
        guard let userID = AuthManager.shared.getUserID() else {
            generateFallbackPreview()
            return
        }
        
        do {
            let snapshot = try await db.collection("Sets")
                .whereField("userID", isEqualTo: userID)
                .whereField("title", isEqualTo: set.title)
                .whereField("subject", isEqualTo: set.subject)
                .getDocuments()
            
            if let document = snapshot.documents.first {
                let setID = document.documentID
                
                // Fetch cards for this set
                let cardsSnapshot = try await db.collection("Sets").document(setID)
                    .collection("Cards").order(by: "position").limit(to: 3).getDocuments()
                
                var fetchedCards: [FlashCard] = []
                
                for cardDoc in cardsSnapshot.documents {
                    let data = cardDoc.data()
                    let term = data["term"] as? String ?? ""
                    let definition = data["definition"] as? String ?? ""
                    
                    fetchedCards.append(FlashCard(term: term, definition: definition))
                }
                
                if !fetchedCards.isEmpty {
                    DispatchQueue.main.async {
                        self.cards = fetchedCards
                        self.isLoading = false
                    }
                    return
                }
            }
            
            // If we couldn't find cards, generate fallbacks
            generateFallbackPreview()
        } catch {
            generateFallbackPreview()
        }
    }
    
    // Generate fallback preview if fetching fails
    private func generateFallbackPreview() {
        let fallbackCards = generateFallbackCards(for: set.subject, title: set.title)
        
        DispatchQueue.main.async {
            self.cards = fallbackCards
            self.isLoading = false
        }
    }
    
    // Create basic fallback cards based on subject and title
    private func generateFallbackCards(for subject: String, title: String) -> [FlashCard] {
        // Simple fallback cards based on subject
        switch subject {
        case "AP Biology":
            return [
                FlashCard(term: "Cell", definition: "The basic structural and functional unit of all living organisms."),
                FlashCard(term: "DNA", definition: "Deoxyribonucleic acid; carries genetic instructions for development and functioning of organisms."),
                FlashCard(term: "Natural Selection", definition: "Process whereby organisms with favorable traits survive and reproduce more successfully.")
            ]
        case "AP Chemistry":
            return [
                FlashCard(term: "Periodic Trend", definition: "Regular patterns in element properties as you move across periods or down groups."),
                FlashCard(term: "Equilibrium", definition: "State where forward and reverse reaction rates are equal; concentrations remain constant."),
                FlashCard(term: "Acid-Base Reaction", definition: "Transfer of protons (H+) from acid to base, forming conjugate pairs.")
            ]
        case "AP Physics":
            return [
                FlashCard(term: "Newton's First Law", definition: "Object at rest stays at rest, object in motion stays in motion unless acted upon by force."),
                FlashCard(term: "Momentum", definition: "Product of mass and velocity; conserved in closed systems."),
                FlashCard(term: "Work", definition: "Energy transferred when force moves an object; product of force and displacement.")
            ]
        default:
            // Generic cards for any other subject
            return [
                FlashCard(term: "Key Concept 1", definition: "Definition of first key concept related to \(title)."),
                FlashCard(term: "Key Concept 2", definition: "Definition of second key concept related to \(title)."),
                FlashCard(term: "Key Concept 3", definition: "Definition of third key concept related to \(title).")
            ]
        }
    }
    
    // Add this set to the user's library
    private func addToMyLibrary() {
        isLoading = true
        
        Task {
            do {
                // Generate full set of cards using Gemini API
                let prompt = "Generate \(set.cardCount) flashcards for \(set.subject) on the topic of \(set.title)."
                let fullCards = try await GeminiService.shared.generateFlashcards(from: prompt, cardCount: set.cardCount)
                
                // Save the set to the user's library
                dataManager.saveRecommendedSet(
                    title: set.title,
                    description: set.description,
                    subject: set.subject,
                    cards: fullCards
                ) { success in
                    DispatchQueue.main.async {
                        if success {
                            // Update the cards preview
                            self.cards = Array(fullCards.prefix(3))
                            self.isLoading = false
                            
                            // Update UI to show set is in library
                        } else {
                            self.isLoading = false
                        }
                    }
                }
            } catch {
                // If API fails, use generic cards
                let fallbackCards = generateFullSetOfFallbackCards(for: set.subject, title: set.title, count: set.cardCount)
                
                dataManager.saveRecommendedSet(
                    title: set.title,
                    description: set.description,
                    subject: set.subject,
                    cards: fallbackCards
                ) { success in
                    DispatchQueue.main.async {
                        if success {
                            // Update the cards preview
                            self.cards = Array(fallbackCards.prefix(3))
                            self.isLoading = false
                        } else {
                            self.isLoading = false
                        }
                    }
                }
            }
        }
    }
    
    // Generate a full set of fallback cards
    private func generateFullSetOfFallbackCards(for subject: String, title: String, count: Int) -> [FlashCard] {
        var cards: [FlashCard] = []
        
        // Add a few subject-specific cards first
        cards.append(contentsOf: generateFallbackCards(for: subject, title: title))
        
        // Add generic cards to reach the desired count
        for i in cards.count..<count {
            cards.append(FlashCard(
                term: "Term \(i+1)",
                definition: "Definition \(i+1) for \(subject) related to \(title)."
            ))
        }
        
        return cards
    }
}

#Preview {
    RecommendedSetsView()
        .environmentObject(DataManager())
}
