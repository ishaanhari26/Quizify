//
//  QuizRoomManager.swift
//  Quizify
//
//  Created for QuizRooms feature
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class QuizRoomManager: ObservableObject {
    // MARK: - Published Properties
    @Published var currentRoom: QuizRoom?
    @Published var players: [QuizPlayer] = []
    @Published var currentPlayer: QuizPlayer?
    @Published var gameState: QuizGameState = QuizGameState()
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    // Timer for question countdown
    @Published var timeRemaining: Int = 0
    @Published var isQuestionActive = false
    
    // MARK: - Private Properties
    private let db = Firestore.firestore()
    private var roomListener: ListenerRegistration?
    private var playersListener: ListenerRegistration?
    private var gameStateListener: ListenerRegistration?
    private var questionTimer: Timer?
    
    // MARK: - Enums
    enum ConnectionStatus {
        case connected
        case disconnected
        case reconnecting
    }
    
    // MARK: - Initialization
    init() {
        setupConnectionMonitoring()
    }
    
    deinit {
        // Clean up synchronously - these operations don't need MainActor
        roomListener?.remove()
        playersListener?.remove()
        gameStateListener?.remove()
        questionTimer?.invalidate()
        print("QuizRoomManager deallocated") // For debugging
    }
    
    // MARK: - Room Creation (Host)
    func createRoom(roomName: String, prompt: String) async throws -> String {
        guard let userID = AuthManager.shared.getUserID() else {
            throw QuizRoomError.notAuthenticated
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            // Generate unique room code
            let roomCode = generateRoomCode()
            
            // Verify room code is unique
            let existingRoom = try await checkRoomCodeExists(roomCode)
            if existingRoom {
                // If code exists, try again with a new code
                return try await createRoom(roomName: roomName, prompt: prompt)
            }
            
            // Generate questions using Gemini
            let questions = try await GeminiService.shared.generateQuizQuestions(from: prompt, questionCount: 4)
            
            // Create room object
            let room = QuizRoom(
                id: UUID().uuidString,
                hostID: userID,
                roomCode: roomCode,
                roomName: roomName,
                prompt: prompt,
                status: .waiting,
                questions: questions,
                createdAt: Date()
            )
            
            // Save room to Firestore
            let roomRef = db.collection("QuizRooms").document(room.id)
            try await roomRef.setData(room.toDictionary())
            
            // Get current user data
            guard let userData = try await getCurrentUserData() else {
                throw QuizRoomError.userDataNotFound
            }
            
            // Add host as first player
            let hostPlayer = QuizPlayer(
                id: userID,
                username: userData.username,
                displayName: userData.displayName,
                isHost: true,
                joinedAt: Date(),
                lastActiveAt: Date()
            )
            
            let playerRef = db.collection("QuizRooms").document(room.id)
                .collection("Players").document(userID)
            try await playerRef.setData(hostPlayer.toDictionary())
            
            // Set current room and start listening
            currentRoom = room
            currentPlayer = hostPlayer
            startListening(roomID: room.id)
            
            isLoading = false
            return roomCode
            
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Room Joining (Guest)
    func joinRoom(roomCode: String) async throws {
        guard let userID = AuthManager.shared.getUserID() else {
            throw QuizRoomError.notAuthenticated
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            // Find room by code
            let roomQuery = try await db.collection("QuizRooms")
                .whereField("roomCode", isEqualTo: roomCode.uppercased())
                .whereField("status", in: [QuizRoomStatus.waiting.rawValue, QuizRoomStatus.active.rawValue])
                .getDocuments()
            
            guard let roomDoc = roomQuery.documents.first,
                  let room = QuizRoom(document: roomDoc) else {
                throw QuizRoomError.roomNotFound
            }
            
            // Check if room is full
            let playersQuery = try await db.collection("QuizRooms").document(room.id)
                .collection("Players").getDocuments()
            
            if playersQuery.documents.count >= 5 {
                throw QuizRoomError.roomFull
            }
            
            // Check if user is already in room
            let existingPlayer = playersQuery.documents.first { $0.documentID == userID }
            if existingPlayer != nil {
                throw QuizRoomError.alreadyInRoom
            }
            
            // Get current user data
            guard let userData = try await getCurrentUserData() else {
                throw QuizRoomError.userDataNotFound
            }
            
            // Add player to room
            let player = QuizPlayer(
                id: userID,
                username: userData.username,
                displayName: userData.displayName,
                isHost: false,
                joinedAt: Date(),
                lastActiveAt: Date()
            )
            
            let playerRef = db.collection("QuizRooms").document(room.id)
                .collection("Players").document(userID)
            try await playerRef.setData(player.toDictionary())
            
            // Set current room and start listening
            currentRoom = room
            currentPlayer = player
            startListening(roomID: room.id)
            
            isLoading = false
            
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Game Control (Host only)
    func startGame() async throws {
        guard let room = currentRoom,
              let userID = AuthManager.shared.getUserID(),
              room.hostID == userID else {
            throw QuizRoomError.notHost
        }
        
        // Ensure we have questions
        guard !room.questions.isEmpty else {
            throw QuizRoomError.noQuestions
        }
        
        // Ensure we have at least 2 players
        guard players.count >= 2 else {
            throw QuizRoomError.notEnoughPlayers
        }
        
        do {
            // Update room status
            var updatedRoom = room
            updatedRoom.status = .active
            updatedRoom.startedAt = Date()
            updatedRoom.currentRound = 1
            
            let roomRef = db.collection("QuizRooms").document(room.id)
            try await roomRef.updateData([
                "status": QuizRoomStatus.active.rawValue,
                "startedAt": Timestamp(date: Date()),
                "currentRound": 1
            ])
            
            // Start first question
            try await startNextQuestion()
            
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func startNextQuestion() async throws {
        guard let room = currentRoom,
              let userID = AuthManager.shared.getUserID(),
              room.hostID == userID else {
            throw QuizRoomError.notHost
        }
        
        let roomRef = db.collection("QuizRooms").document(room.id)
        
        do {
            // Set question start time
            try await roomRef.updateData([
                "currentQuestionStartTime": Timestamp(date: Date())
            ])
            
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func moveToNextRound() async throws {
        guard let room = currentRoom,
              let userID = AuthManager.shared.getUserID(),
              room.hostID == userID else {
            throw QuizRoomError.notHost
        }
        
        let roomRef = db.collection("QuizRooms").document(room.id)
        
        do {
            if room.currentRound < room.maxRounds {
                // Move to next round
                let nextRound = room.currentRound + 1
                try await roomRef.updateData([
                    "currentRound": nextRound,
                    "currentQuestionStartTime": FieldValue.delete()
                ])
                
                // Start next question after brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                    Task {
                        try? await self?.startNextQuestion()
                    }
                }
            } else {
                // Game is finished
                try await roomRef.updateData([
                    "status": QuizRoomStatus.ended.rawValue,
                    "endedAt": Timestamp(date: Date()),
                    "currentQuestionStartTime": FieldValue.delete()
                ])
                
                // Calculate final scores and rankings
                // This could trigger a cloud function or be handled here
                if room.currentRound >= room.maxRounds {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                        Task {
                            try? await self?.moveToNextRound()
                        }
                    }
                }
            }
            
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Answer Submission
    func submitAnswer(answerIndex: Int) async throws {
        guard let room = currentRoom,
              let player = currentPlayer,
              let questionStartTime = room.currentQuestionStartTime else {
            throw QuizRoomError.invalidGameState
        }
        
        // Check if question is still active
        guard isQuestionActive else {
            throw QuizRoomError.questionExpired
        }
        
        let currentQuestionIndex = room.currentRound - 1
        guard currentQuestionIndex < room.questions.count else {
            throw QuizRoomError.invalidGameState
        }
        
        let question = room.questions[currentQuestionIndex]
        let responseTime = Date().timeIntervalSince(questionStartTime)
        let isCorrect = answerIndex == question.correctAnswerIndex
        let pointsAwarded = QuizResponse.calculatePoints(isCorrect: isCorrect, responseTime: responseTime)
        
        let response = QuizResponse(
            playerID: player.id,
            username: player.username,
            roomID: room.id,
            questionID: question.id,
            roundNumber: room.currentRound,
            selectedAnswerIndex: answerIndex,
            isCorrect: isCorrect,
            responseTime: responseTime,
            submittedAt: Date(),
            pointsAwarded: pointsAwarded
        )
        
        do {
            // Save response
            let responseRef = db.collection("QuizRooms").document(room.id)
                .collection("Responses").document()
            try await responseRef.setData([
                "playerID": response.playerID,
                "username": response.username,
                "roomID": response.roomID,
                "questionID": response.questionID.uuidString,
                "roundNumber": response.roundNumber,
                "selectedAnswerIndex": response.selectedAnswerIndex,
                "isCorrect": response.isCorrect,
                "responseTime": response.responseTime,
                "submittedAt": Timestamp(date: response.submittedAt),
                "pointsAwarded": response.pointsAwarded
            ])
            
            // Update player's total score
            let playerRef = db.collection("QuizRooms").document(room.id)
                .collection("Players").document(player.id)
            try await playerRef.updateData([
                "score": FieldValue.increment(Int64(pointsAwarded)),
                "lastActiveAt": Timestamp(date: Date())
            ])
            
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Leave Room
    func leaveRoom() async {
        guard let room = currentRoom,
              let player = currentPlayer else {
            cleanup()
            return
        }
        
        do {
            // Remove player from room
            let playerRef = db.collection("QuizRooms").document(room.id)
                .collection("Players").document(player.id)
            try await playerRef.delete()
            
            // If host is leaving and game hasn't started, delete the room
            if player.isHost && room.status == .waiting {
                let roomRef = db.collection("QuizRooms").document(room.id)
                try await roomRef.delete()
            }
            
            // Clean up properly
            await MainActor.run {
                cleanup()
            }
            
        } catch {
            print("Error leaving room: \(error.localizedDescription)")
            await MainActor.run {
                cleanup()
            }
        }
    }
    
    // MARK: - Real-time Listeners
    private func startListening(roomID: String) {
        // Listen to room changes
        roomListener = db.collection("QuizRooms").document(roomID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                Task { @MainActor in
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        return
                    }
                    
                    guard let snapshot = snapshot,
                          let room = QuizRoom(document: snapshot) else {
                        self.errorMessage = "Room no longer exists"
                        self.cleanup()
                        return
                    }
                    
                    self.currentRoom = room
                    
                    // Handle question timing
                    if room.status == .active {
                        self.handleQuestionTiming(room: room)
                    }
                }
            }
        
        // Listen to players changes
        playersListener = db.collection("QuizRooms").document(roomID)
            .collection("Players")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                Task { @MainActor in
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        return
                    }
                    
                    guard let snapshot = snapshot else { return }
                    
                    self.players = snapshot.documents.compactMap { QuizPlayer(document: $0) }
                        .sorted { $0.score > $1.score }
                    
                    // Update current player if score changed
                    if let currentPlayerID = self.currentPlayer?.id,
                       let updatedPlayer = self.players.first(where: { $0.id == currentPlayerID }) {
                        self.currentPlayer = updatedPlayer
                    }
                }
            }
        
        connectionStatus = .connected
    }
    
    private func handleQuestionTiming(room: QuizRoom) {
        guard let questionStartTime = room.currentQuestionStartTime else {
            isQuestionActive = false
            return
        }
        
        let elapsed = Date().timeIntervalSince(questionStartTime)
        let remaining = max(0, 15.0 - elapsed)
        
        if remaining > 0 {
            if !isQuestionActive {
                isQuestionActive = true
                startQuestionTimer(duration: remaining)
            }
        } else {
            isQuestionActive = false
            stopQuestionTimer()
        }
    }
    
    // MARK: - Timer Management
    private func startQuestionTimer(duration: TimeInterval) {
        stopQuestionTimer()
        timeRemaining = Int(duration)
        
        // Use weak self to prevent retain cycles
        questionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            Task { @MainActor in
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.stopQuestionTimer()
                    self.isQuestionActive = false
                    
                    // If host, move to next round after brief delay
                    if let room = self.currentRoom,
                       let userID = AuthManager.shared.getUserID(),
                       room.hostID == userID {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            Task {
                                try? await self.moveToNextRound()
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func stopQuestionTimer() {
        questionTimer?.invalidate()
        questionTimer = nil
    }
    
    // MARK: - Helper Methods
    private func generateRoomCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in characters.randomElement()! })
    }
    
    private func checkRoomCodeExists(_ code: String) async throws -> Bool {
        let snapshot = try await db.collection("QuizRooms")
            .whereField("roomCode", isEqualTo: code)
            .whereField("status", in: [QuizRoomStatus.waiting.rawValue, QuizRoomStatus.active.rawValue])
            .getDocuments()
        
        return !snapshot.documents.isEmpty
    }
    
    private func getCurrentUserData() async throws -> (username: String, displayName: String)? {
        guard let userID = AuthManager.shared.getUserID() else { return nil }
        
        let userDoc = try await db.collection("Users").document(userID).getDocument()
        guard let data = userDoc.data() else { return nil }
        
        let username = data["username"] as? String ?? "Unknown"
        let displayName = data["displayName"] as? String ?? username
        
        return (username: username, displayName: displayName)
    }
    
    private func setupConnectionMonitoring() {
        // Monitor network connectivity
        // This is a simplified version - in production you'd use Network framework
        connectionStatus = .connected
    }
    
    // MARK: - Cleanup Methods
    private func cleanup() {
        // This method can remain @MainActor for UI updates
        roomListener?.remove()
        playersListener?.remove()
        gameStateListener?.remove()
        stopQuestionTimer()
        
        // Clear references
        roomListener = nil
        playersListener = nil
        gameStateListener = nil
        
        currentRoom = nil
        currentPlayer = nil
        players = []
        gameState = QuizGameState()
        isQuestionActive = false
        connectionStatus = .disconnected
    }
    
    // Remove the nonisolated cleanup method that causes MainActor errors
    // The deinit and regular cleanup() method are sufficient
    
    // MARK: - Public Helper Methods
    func isHost() -> Bool {
        return currentPlayer?.isHost == true
    }
    
    func canStartGame() -> Bool {
        return isHost() && players.count >= 2 && currentRoom?.status == .waiting
    }
    
    func getCurrentQuestion() -> QuizQuestion? {
        guard let room = currentRoom,
              room.currentRound > 0,
              room.currentRound <= room.questions.count else {
            return nil
        }
        
        return room.questions[room.currentRound - 1]
    }
    
    func getPlayerRank(playerID: String) -> Int? {
        guard let index = players.firstIndex(where: { $0.id == playerID }) else {
            return nil
        }
        return index + 1
    }
    
    func getGameProgress() -> (current: Int, total: Int) {
        guard let room = currentRoom else {
            return (0, 4)
        }
        return (room.currentRound, room.maxRounds)
    }
}

// MARK: - Error Types
enum QuizRoomError: LocalizedError {
    case notAuthenticated
    case roomNotFound
    case roomFull
    case alreadyInRoom
    case notHost
    case noQuestions
    case notEnoughPlayers
    case invalidGameState
    case questionExpired
    case userDataNotFound
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to join a quiz room"
        case .roomNotFound:
            return "Quiz room not found or no longer available"
        case .roomFull:
            return "This quiz room is full (maximum 5 players)"
        case .alreadyInRoom:
            return "You are already in this quiz room"
        case .notHost:
            return "Only the host can perform this action"
        case .noQuestions:
            return "No questions available for this quiz"
        case .notEnoughPlayers:
            return "Need at least 2 players to start the game"
        case .invalidGameState:
            return "Invalid game state"
        case .questionExpired:
            return "Time has expired for this question"
        case .userDataNotFound:
            return "Could not load your user profile"
        case .networkError:
            return "Network connection error"
        }
    }
}
