import Foundation
import GoogleGenerativeAI

actor GeminiService {
    static let shared = GeminiService()
    private var model: GenerativeModel?
    
    private init() {
        setupGemini()
    }
    
    private func setupGemini() {
        // Config
        let config = GenerationConfig(
            temperature: 0.7,
            topP: 0.95,
            topK: 40,
            maxOutputTokens: 8192,
            responseMIMEType: "text/plain"
        )
        
        // Hardcoded api key
        let apiKey = "AIzaSyA9PlU3V3tJ3ljhsa-oM4qn9cn2WFvodRc"
        
        // init model
        model = GenerativeModel(
            name: "gemini-2.0-flash",
            apiKey: apiKey,
            generationConfig: config
        )
    }
    
    /// Generate flashcards from a given prompt
    /// - Parameters:
    ///   - prompt: The user's prompt or topic
    ///   - cardCount: The desired number of flashcards
    /// - Returns: An array of FlashCard objects
    func generateFlashcards(from prompt: String, cardCount: Int = 10) async throws -> [FlashCard] {
        // If model is nil, use mock data
        guard let model = model else {
            return generateMockFlashcards(for: prompt, count: cardCount)
        }
        
        do {
            // create a chat instance
            let chat = model.startChat()
            
            //Prompt fed to Gemini
            let systemPrompt = """
            Generate \(cardCount) flashcards for studying the topic: "\(prompt)".
            
            Format the response as a JSON array of objects with 'term' and 'definition' fields.
            
            Each flashcard should have:
            1. A clear, concise term (1-5 words if possible)
            2. A comprehensive but concise definition, that is brief (1-2 Short Sentences)
            
            Example format:
            [
              {
                "term": "Photosynthesis",
                "definition": "The process by which green plants and some other organisms use sunlight to synthesize nutrients from carbon dioxide and water."
              },
              {
                "term": "Term 2",
                "definition": "Definition 2"
              }
            ]
            
            Focus on essential concepts that would be most beneficial for studying this topic.
            """
            
            // Sends prompt to gemini
            let response = try await chat.sendMessage(systemPrompt)
            
            // parse JSON
            guard let responseText = response.text else {
                return generateMockFlashcards(for: prompt, count: cardCount)
            }
            
            // Clean the response text to ensure it's valid JSON
            let cleanedResponse = cleanResponseText(responseText)
            
            // convert into flashcards
            do {
                return try parseFlashcardsFromJSON(cleanedResponse)
            } catch {
                // If parsing fails, return mock data
                return generateMockFlashcards(for: prompt, count: cardCount)
            }
        } catch {
            // If API call fails, return mock data
            return generateMockFlashcards(for: prompt, count: cardCount)
        }
    }
    
    // Clean the response text to extract valid JSON
    private func cleanResponseText(_ text: String) -> String {
        // Find any JSON array in the response
        if let startIndex = text.firstIndex(of: "["),
           let endIndex = text.lastIndex(of: "]") {
            let jsonSubstring = text[startIndex...endIndex]
            return String(jsonSubstring)
        }
        return text
    }
    
    //Parse JSON response into flashcards
    private func parseFlashcardsFromJSON(_ jsonString: String) throws -> [FlashCard] {
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw NSError(domain: "GeminiService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to convert response to data"])
        }
        
        // Decode the JSON
        struct FlashcardDTO: Codable {
            let term: String
            let definition: String
        }
        
        let flashcardDTOs = try JSONDecoder().decode([FlashcardDTO].self, from: jsonData)
        
        // Convert DTOs to FlashCard model
        return flashcardDTOs.map { dto in
            FlashCard(term: dto.term, definition: dto.definition)
        }
    }
    
    /// Generate mock flashcards for testing when API is unavailable
    /// - Parameters:
    ///   - prompt: The topic for the flashcards
    ///   - count: Number of flashcards to generate
    /// - Returns: Array of mock FlashCard objects
    private func generateMockFlashcards(for prompt: String, count: Int) -> [FlashCard] {
        // Create sample flashcards based on the prompt
        var cards: [FlashCard] = []
        
        // Add a set of generic flashcards
        let topics = [
            ("Definition", "The meaning or explanation of \(prompt)"),
            ("History", "The origin and development of \(prompt)"),
            ("Examples", "Common instances or cases of \(prompt)"),
            ("Applications", "How \(prompt) is used in practical scenarios"),
            ("Key Features", "The distinguishing characteristics of \(prompt)"),
            ("Related Concepts", "Ideas and terms connected to \(prompt)"),
            ("Benefits", "Advantages and positive aspects of \(prompt)"),
            ("Limitations", "Constraints or drawbacks of \(prompt)"),
            ("Components", "The essential parts that make up \(prompt)"),
            ("Future Developments", "Upcoming trends or changes related to \(prompt)")
        ]
        
        // Add as many cards as requested, up to the available topics
        for i in 0..<min(count, topics.count) {
            cards.append(FlashCard(term: topics[i].0, definition: topics[i].1))
        }
        
        // If more cards are needed, add generic numbered cards
        if count > topics.count {
            for i in topics.count..<count {
                cards.append(FlashCard(
                    term: "Aspect \(i+1) of \(prompt)",
                    definition: "This is a placeholder definition for aspect \(i+1) of \(prompt). In a real implementation, this would be generated by the AI."
                ))
            }
        }
        
        return cards
    }
}

// Add these helper functions to GeminiService.swift to handle recommended set generation

extension GeminiService {
    
    /// Generate recommended flashcards for a specific AP subject
    /// - Parameters:
    ///   - subject: The AP subject to generate cards for
    ///   - topic: Optional specific topic within the subject
    ///   - cardCount: The desired number of flashcards
    /// - Returns: An array of FlashCard objects
    func generateRecommendedFlashcards(subject: String, topic: String? = nil, cardCount: Int = 10) async throws -> [FlashCard] {
        // Build prompt based on subject and optional topic
        let specificTopic = topic ?? "key concepts"
        
        let prompt = """
        Generate \(cardCount) flashcards for \(subject) covering \(specificTopic).
        
        Each flashcard should have:
        1. A clear, concise term (key concept, person, event, formula, etc.)
        2. A comprehensive but concise definition suitable for AP exam preparation
        
        Focus on terms that AP students are likely to encounter on the exam. 
        Each definition should be about 1-2 sentences and factually accurate.
        """
        
        // Call the standard flashcards generation method
        return try await generateFlashcards(from: prompt, cardCount: cardCount)
    }
    
    /// Generate recommended sets for multiple subjects
    /// - Parameter subjects: Array of AP subjects the user is studying
    /// - Returns: Dictionary mapping subjects to arrays of recommended set topics
    func generateRecommendedTopics(for subjects: [String]) async throws -> [String: [(String, String)]] {
        // Early exit for empty subjects
        if subjects.isEmpty {
            return [:]
        }
        
        // Take only the first 3 subjects to generate recommendations for
        let subjectsToUse = Array(subjects.prefix(3))
        
        // Build prompt for Gemini to generate topics
        let subjectsList = subjectsToUse.joined(separator: ", ")
        let prompt = """
        For each of these AP subjects: \(subjectsList)
        
        Generate 2 important topics that AP students should study, with each topic having:
        1. A brief title (3-5 words)
        2. A short description (under 10 words)
        
        Format as JSON like:
        {
          "AP Biology": [
            {"title": "Cell Division", "description": "Mitosis and meiosis processes"},
            {"title": "Biochemical Pathways", "description": "Enzyme functions and metabolic processes"}
          ],
          "AP Chemistry": [
            {"title": "Periodic Trends", "description": "Properties across the periodic table"},
            {"title": "Chemical Equilibrium", "description": "Understanding Le Chatelier's principle"}
          ]
        }
        
        Focus on essential topics that would be most useful for AP exam preparation.
        """
        
        // Use predefined topics if Gemini API fails
        // In a real app, you would handle this more robustly
        let predefinedTopics: [String: [(String, String)]] = [
            "AP Biology": [
                ("Cell Structure & Function", "Understanding cellular components"),
                ("Genetics & Heredity", "DNA, RNA, and inheritance patterns")
            ],
            "AP Chemistry": [
                ("Periodic Trends", "Properties across the periodic table"),
                ("Acid-Base Reactions", "Understanding pH and neutralization")
            ],
            "AP Physics 1": [
                ("Newton's Laws", "Fundamental principles of motion"),
                ("Work & Energy", "Conservation principles in mechanics")
            ],
            "AP Calculus AB": [
                ("Derivatives & Applications", "Differentiation techniques"),
                ("Integration Techniques", "Finding antiderivatives")
            ],
            "AP Literature": [
                ("Literary Devices", "Techniques authors use for effect"),
                ("Analysis Frameworks", "Critical approaches to text")
            ],
            "AP World History": [
                ("Industrial Revolution", "Global economic transformation"),
                ("Cold War", "Tension between superpowers")
            ],
            "AP Psychology": [
                ("Brain Structure", "Anatomy and neural functions"),
                ("Development Theories", "Life stages and cognition")
            ]
        ]
        
        // In a real implementation, you would use Gemini API to generate topics
        // For now, return predefined topics
        var result: [String: [(String, String)]] = [:]
        
        for subject in subjectsToUse {
            if let topics = predefinedTopics[subject] {
                result[subject] = topics
            } else {
                // For subjects without predefined topics, provide generic ones
                result[subject] = [
                    ("Key Concepts", "Essential principles and terminology"),
                    ("Common Questions", "Frequently tested material")
                ]
            }
        }
        
        return result
    }
}
