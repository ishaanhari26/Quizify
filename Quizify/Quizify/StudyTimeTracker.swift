//
//  StudyTimeTracker.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 3/27/25.
//

import Foundation
import FirebaseFirestore

class StudyTimeTracker: ObservableObject {
    @Published var isTracking = false
    @Published var elapsedTime: TimeInterval = 0
    
    private var startTime: Date?
    private var timer: Timer?
    private var setID: String?
    
    func startTracking(setID: String) {
        self.setID = setID
        startTime = Date()
        isTracking = true
        elapsedTime = 0
        
        // Start timer to update elapsed time
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else { return }
            self.elapsedTime = Date().timeIntervalSince(startTime)
        }
    }
    
    func stopTracking(dataManager: DataManager) {
        guard let setID = setID, let startTime = startTime else { return }
        
        // Calculate total time spent
        let totalTime = Date().timeIntervalSince(startTime)
        
        // Save study time to Firestore
        dataManager.recordStudyTime(setID: setID, duration: totalTime)
        
        // Reset state
        timer?.invalidate()
        timer = nil
        self.startTime = nil
        self.setID = nil
        isTracking = false
        elapsedTime = 0
    }
    
    func formattedTime(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
