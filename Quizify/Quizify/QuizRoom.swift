//
//  QuizRoom.swift
//  Quizify
//
//  Created for QuizRooms feature
//

import Foundation
import FirebaseFirestore

// MARK: - QuizRoom Model
struct QuizRoom: Identifiable, Codable {
    var id: String
    var hostID: String
    var roomCode: String
    var roomName: String
    var prompt: String
    var status: QuizRoomStatus
    var maxPlayers: Int = 5
    var maxRounds: Int = 4
    var currentRound: Int = 0
    var questions: [QuizQuestion] = []
    var createdAt: Date
    var startedAt: Date?
    var endedAt: Date?
    var currentQuestionStartTime: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, hostID, roomCode, roomName, prompt, status
        case maxPlayers, maxRounds, currentRound, questions
        case createdAt, startedAt, endedAt, currentQuestionStartTime
    }
}

// MARK: - QuizRoomStatus
enum QuizRoomStatus: String, Codable, CaseIterable {
    case waiting = "waiting"
    case active = "active"
    case ended = "ended"
    
    var displayName: String {
        switch self {
        case .waiting:
            return "Waiting for players"
        case .active:
            return "Game in progress"
        case .ended:
            return "Game ended"
        }
    }
}

// MARK: - QuizQuestion Model
struct QuizQuestion: Identifiable, Codable {
    var id = UUID()
    var question: String
    var answers: [String] // 4 answers
    var correctAnswerIndex: Int // 0-3
    var roundNumber: Int
    
    var correctAnswer: String {
        guard correctAnswerIndex >= 0 && correctAnswerIndex < answers.count else {
            return answers.first ?? ""
        }
        return answers[correctAnswerIndex]
    }
    
    // Validate question has exactly 4 answers
    var isValid: Bool {
        return answers.count == 4 &&
        correctAnswerIndex >= 0 &&
        correctAnswerIndex < 4 &&
        !question.isEmpty &&
        answers.allSatisfy { !$0.isEmpty }
    }
}

// MARK: - QuizPlayer Model
struct QuizPlayer: Identifiable, Codable {
    var id: String // User ID
    var username: String
    var displayName: String
    var score: Int = 0
    var isHost: Bool = false
    var isConnected: Bool = true
    var joinedAt: Date
    var lastActiveAt: Date
    
    // Score for individual rounds
    var roundScores: [Int] = []
    
    mutating func addRoundScore(_ score: Int) {
        roundScores.append(score)
        self.score += score
    }
    
    mutating func updateLastActive() {
        lastActiveAt = Date()
    }
}

// MARK: - QuizResponse Model
struct QuizResponse: Identifiable, Codable {
    var id = UUID()
    var playerID: String
    var username: String
    var roomID: String
    var questionID: UUID
    var roundNumber: Int
    var selectedAnswerIndex: Int
    var isCorrect: Bool
    var responseTime: TimeInterval // Time taken to answer in seconds
    var submittedAt: Date
    var pointsAwarded: Int
    
    // Calculate points based on correctness and speed
    static func calculatePoints(isCorrect: Bool, responseTime: TimeInterval, maxTime: TimeInterval = 15.0) -> Int {
        guard isCorrect else { return 0 }
        
        let basePoints = 100
        let maxSpeedBonus = 50
        
        // Speed bonus: faster responses get more points
        let speedRatio = max(0, (maxTime - responseTime) / maxTime)
        let speedBonus = Int(Double(maxSpeedBonus) * speedRatio)
        
        return basePoints + speedBonus
    }
}

// MARK: - QuizGameState Model
struct QuizGameState: Codable {
    var currentQuestionIndex: Int = 0
    var questionStartTime: Date?
    var questionEndTime: Date?
    var isQuestionActive: Bool = false
    var roundScores: [String: Int] = [:] // PlayerID: Score for current round
    
    var timeRemaining: TimeInterval {
        guard let startTime = questionStartTime,
              let endTime = questionEndTime else {
            return 0
        }
        
        let now = Date()
        if now >= endTime {
            return 0
        }
        
        return endTime.timeIntervalSince(now)
    }
    
    mutating func startQuestion(at time: Date = Date(), duration: TimeInterval = 15.0) {
        questionStartTime = time
        questionEndTime = time.addingTimeInterval(duration)
        isQuestionActive = true
    }
    
    mutating func endQuestion() {
        isQuestionActive = false
        questionEndTime = Date()
    }
}

// MARK: - Extensions for Firebase
extension QuizRoom {
    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let hostID = data["hostID"] as? String,
              let roomCode = data["roomCode"] as? String,
              let roomName = data["roomName"] as? String,
              let prompt = data["prompt"] as? String,
              let statusString = data["status"] as? String,
              let status = QuizRoomStatus(rawValue: statusString),
              let createdAtTimestamp = data["createdAt"] as? Timestamp else {
            return nil
        }
        
        self.id = document.documentID
        self.hostID = hostID
        self.roomCode = roomCode
        self.roomName = roomName
        self.prompt = prompt
        self.status = status
        self.maxPlayers = data["maxPlayers"] as? Int ?? 5
        self.maxRounds = data["maxRounds"] as? Int ?? 4
        self.currentRound = data["currentRound"] as? Int ?? 0
        self.createdAt = createdAtTimestamp.dateValue()
        
        // Handle optional timestamps
        if let startedAtTimestamp = data["startedAt"] as? Timestamp {
            self.startedAt = startedAtTimestamp.dateValue()
        }
        
        if let endedAtTimestamp = data["endedAt"] as? Timestamp {
            self.endedAt = endedAtTimestamp.dateValue()
        }
        
        if let questionStartTimestamp = data["currentQuestionStartTime"] as? Timestamp {
            self.currentQuestionStartTime = questionStartTimestamp.dateValue()
        }
        
        // Parse questions if they exist
        if let questionsData = data["questions"] as? [[String: Any]] {
            self.questions = questionsData.compactMap { QuizQuestion(dictionary: $0) }
        } else {
            self.questions = []
        }
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "hostID": hostID,
            "roomCode": roomCode,
            "roomName": roomName,
            "prompt": prompt,
            "status": status.rawValue,
            "maxPlayers": maxPlayers,
            "maxRounds": maxRounds,
            "currentRound": currentRound,
            "createdAt": Timestamp(date: createdAt),
            "questions": questions.map { $0.toDictionary() }
        ]
        
        if let startedAt = startedAt {
            dict["startedAt"] = Timestamp(date: startedAt)
        }
        
        if let endedAt = endedAt {
            dict["endedAt"] = Timestamp(date: endedAt)
        }
        
        if let currentQuestionStartTime = currentQuestionStartTime {
            dict["currentQuestionStartTime"] = Timestamp(date: currentQuestionStartTime)
        }
        
        return dict
    }
}

extension QuizQuestion {
    init?(dictionary: [String: Any]) {
        guard let question = dictionary["question"] as? String,
              let answers = dictionary["answers"] as? [String],
              let correctAnswerIndex = dictionary["correctAnswerIndex"] as? Int,
              let roundNumber = dictionary["roundNumber"] as? Int,
              answers.count == 4 else {
            return nil
        }
        
        if let idString = dictionary["id"] as? String,
           let uuid = UUID(uuidString: idString) {
            self.id = uuid
        } else {
            self.id = UUID()
        }
        
        self.question = question
        self.answers = answers
        self.correctAnswerIndex = correctAnswerIndex
        self.roundNumber = roundNumber
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "question": question,
            "answers": answers,
            "correctAnswerIndex": correctAnswerIndex,
            "roundNumber": roundNumber
        ]
    }
}

extension QuizPlayer {
    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let username = data["username"] as? String,
              let displayName = data["displayName"] as? String,
              let joinedAtTimestamp = data["joinedAt"] as? Timestamp,
              let lastActiveAtTimestamp = data["lastActiveAt"] as? Timestamp else {
            return nil
        }
        
        self.id = document.documentID
        self.username = username
        self.displayName = displayName
        self.score = data["score"] as? Int ?? 0
        self.isHost = data["isHost"] as? Bool ?? false
        self.isConnected = data["isConnected"] as? Bool ?? true
        self.joinedAt = joinedAtTimestamp.dateValue()
        self.lastActiveAt = lastActiveAtTimestamp.dateValue()
        self.roundScores = data["roundScores"] as? [Int] ?? []
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "username": username,
            "displayName": displayName,
            "score": score,
            "isHost": isHost,
            "isConnected": isConnected,
            "joinedAt": Timestamp(date: joinedAt),
            "lastActiveAt": Timestamp(date: lastActiveAt),
            "roundScores": roundScores
        ]
    }
}
