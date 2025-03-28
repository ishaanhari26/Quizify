//
//  OtherUserProfileView.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 3/28/25.
//


import SwiftUI
import FirebaseFirestore

// Model for user profile data
struct OtherUserProfile {
    var id: String
    var username: String
    var displayName: String
    var email: String
    var studyStreak: Int
    var maxStreak: Int
    var totalStudyTime: TimeInterval
    var publicSets: [Set]
    var joinDate: Date
    
    // Format the total study time
    var formattedTotalStudyTime: String {
        formatTimeInterval(totalStudyTime)
    }
    
    // Format join date
    var formattedJoinDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return "Joined \(formatter.string(from: joinDate))"
    }
}

class OtherUserProfileViewModel: ObservableObject {
    @Published var userProfile: OtherUserProfile?
    @Published var isLoading = true
    @Published var errorMessage = ""
    @Published var analyticsData: [DailyStudyData] = []
    @Published var maxDailyMinutes: Double = 60
    
    func loadUserProfile(userId: String) {
        isLoading = true
        errorMessage = ""
        
        let db = Firestore.firestore()
        
        // Get user data
        db.collection("Users").document(userId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = "Error loading profile: \(error.localizedDescription)"
                self.isLoading = false
                return
            }
            
            guard let document = document, document.exists, let userData = document.data() else {
                self.errorMessage = "User profile not found"
                self.isLoading = false
                return
            }
            
            // Extract user info
            let email = userData["email"] as? String ?? "Unknown"
            let username = userData["username"] as? String ?? "Unknown"
            let displayName = userData["displayName"] as? String ?? username
            let currentStreak = userData["currentStreak"] as? Int ?? 0
            let maxStreak = userData["maxStreak"] as? Int ?? 0
            let joinTimestamp = userData["createdAt"] as? Timestamp ?? Timestamp(date: Date())
            
            // Get sets for this user
            self.loadUserSets(userId: userId) { sets, totalStudyTime in
                // Load user analytics
                self.loadUserAnalytics(userId: userId) { dailyData in
                    // Create user profile object
                    let profile = OtherUserProfile(
                        id: userId,
                        username: username,
                        displayName: displayName,
                        email: email,
                        studyStreak: currentStreak,
                        maxStreak: maxStreak,
                        totalStudyTime: totalStudyTime,
                        publicSets: sets,
                        joinDate: joinTimestamp.dateValue()
                    )
                    
                    DispatchQueue.main.async {
                        self.userProfile = profile
                        self.analyticsData = dailyData
                        
                        // Find the maximum daily minutes for chart scaling
                        if let maxDaily = dailyData.max(by: { $0.minutesStudied < $1.minutesStudied }) {
                            self.maxDailyMinutes = max(60, maxDaily.minutesStudied + 10)
                        }
                        
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    private func loadUserSets(userId: String, completion: @escaping ([Set], TimeInterval) -> Void) {
        let db = Firestore.firestore()
        let ref = db.collection("Sets")
        
        // Query only the public sets created by the user
        ref.whereField("userID", isEqualTo: userId)
            .whereField("isPublic", isEqualTo: true)
            .getDocuments { snapshot, error in
                guard error == nil else {
                    completion([], 0)
                    return
                }
                
                if let snapshot = snapshot {
                    // Create a dispatch group to wait for all sets to be processed
                    let group = DispatchGroup()
                    
                    var tempSets: [Set] = []
                    var totalStudyTime: TimeInterval = 0
                    
                    for document in snapshot.documents {
                        let data = document.data()
                        
                        let id = document.documentID
                        let title = data["title"] as? String ?? ""
                        let description = data["description"] as? String
                        let cardCount = data["cardCount"] as? Int ?? 0
                        let timestamp = data["createdAt"] as? Timestamp ?? Timestamp(date: Date())
                        
                        // Create a set without study time initially
                        var newSet = Set(
                            id: id,
                            title: title,
                            description: description,
                            cardCount: cardCount,
                            createdAt: timestamp.dateValue()
                        )
                        
                        // Enter the dispatch group to fetch study time
                        group.enter()
                        
                        // Fetch study time for this set
                        self.getSetStudyTime(userId: userId, setID: id) { studyTime in
                            newSet.totalStudyTime = studyTime
                            totalStudyTime += studyTime
                            
                            tempSets.append(newSet)
                            group.leave()
                        }
                    }
                    
                    // When all sets have been processed, sort and return
                    group.notify(queue: .main) {
                        // Sort by most recently created
                        let sortedSets = tempSets.sorted(by: { $0.createdAt > $1.createdAt })
                        completion(sortedSets, totalStudyTime)
                    }
                } else {
                    completion([], 0)
                }
            }
    }
    
    private func getSetStudyTime(userId: String, setID: String, completion: @escaping (TimeInterval) -> Void) {
        let db = Firestore.firestore()
        
        let studyTimesRef = db.collection("StudyTimes")
            .whereField("setID", isEqualTo: setID)
            .whereField("userID", isEqualTo: userId)
        
        studyTimesRef.getDocuments { snapshot, error in
            guard error == nil else {
                completion(0)
                return
            }
            
            var totalTime: TimeInterval = 0
            
            if let snapshot = snapshot {
                for document in snapshot.documents {
                    let data = document.data()
                    
                    if let duration = data["duration"] as? TimeInterval {
                        totalTime += duration
                    }
                }
                
                completion(totalTime)
            } else {
                completion(0)
            }
        }
    }
    
    private func loadUserAnalytics(userId: String, completion: @escaping ([DailyStudyData]) -> Void) {
        let db = Firestore.firestore()
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var dailyData: [DailyStudyData] = []
        let today = Date()
        
        // Create a dispatch group to wait for all days to be processed
        let group = DispatchGroup()
        
        // Get data for the last 7 days
        for day in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -day, to: today) {
                let dateString = dateFormatter.string(from: date)
                
                // Enter the dispatch group
                group.enter()
                
                // The document ID is a combination of user ID and date
                let documentID = "\(userId)_\(dateString)"
                
                // Fetch study data for this day
                let dailyRef = db.collection("DailyStudy").document(documentID)
                dailyRef.getDocument { document, error in
                    if let document = document, document.exists, let data = document.data() {
                        if let totalTime = data["totalTime"] as? TimeInterval {
                            let minutesStudied = totalTime / 60 // Convert to minutes
                            
                            let dailyItem = DailyStudyData(
                                date: date,
                                minutesStudied: minutesStudied
                            )
                            
                            dailyData.append(dailyItem)
                        }
                    } else {
                        // No data for this day, record zero
                        let dailyItem = DailyStudyData(
                            date: date,
                            minutesStudied: 0
                        )
                        
                        dailyData.append(dailyItem)
                    }
                    
                    group.leave()
                }
            }
        }
        
        // When all days have been processed, sort and return the data
        group.notify(queue: .main) {
            let sortedData = dailyData.sorted(by: { $0.date < $1.date })
            completion(sortedData)
        }
    }
}

struct OtherUserProfileView: View {
    let userId: String
    @StateObject private var viewModel = OtherUserProfileViewModel()
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager
    
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
                            
                            Text("User Profile")
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
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading profile...")
                        .font(.custom("Kiwi Maru Light", size: 16))
                        .foregroundColor(.gray)
                        .padding()
                    Spacer()
                } else if !viewModel.errorMessage.isEmpty {
                    Spacer()
                    Text(viewModel.errorMessage)
                        .font(.custom("Kiwi Maru Regular", size: 16))
                        .foregroundColor(.red)
                        .padding()
                    Spacer()
                } else if let profile = viewModel.userProfile {
                    ScrollView {
                        VStack(spacing: 20) {
                            // User header
                            userHeader(profile: profile)
                            
                            // Stats cards
                            statsCards(profile: profile)
                            
                            // Study trend
                            studyTrendSection
                            
                            // User's sets
                            setsSection(profile: profile)
                            
                            Spacer(minLength: 50)
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.loadUserProfile(userId: userId)
        }
    }
    
    // MARK: - Component Views
    
    private func userHeader(profile: OtherUserProfile) -> some View {
        VStack(spacing: 15) {
            // Profile picture
            Circle()
                .fill(Color(hex: "#C97D60").opacity(0.2))
                .frame(width: 100, height: 100)
                .overlay(
                    Text(String(profile.username.prefix(1)).uppercased())
                        .font(.system(size: 36))
                        .foregroundColor(Color(hex: "#C97D60"))
                )
                .padding(.top, 20)
            
            // Name and username
            Text(profile.displayName)
                .font(.custom("Kiwi Maru Regular", size: 22))
                .foregroundColor(.black)
            
            Text("@\(profile.username)")
                .font(.custom("Kiwi Maru Light", size: 16))
                .foregroundColor(.gray)
            
            // Email
            Text(profile.email)
                .font(.custom("Kiwi Maru Light", size: 14))
                .foregroundColor(.gray)
            
            // Join date
            Text(profile.formattedJoinDate)
                .font(.custom("Kiwi Maru Light", size: 14))
                .foregroundColor(.gray)
                .padding(.top, 5)
            
            // Streak badge
            if profile.studyStreak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(Color(hex: "#C97D60"))
                        .font(.system(size: 16))
                    
                    Text("\(profile.studyStreak) day streak")
                        .font(.custom("Kiwi Maru Medium", size: 16))
                        .foregroundColor(Color(hex: "#C97D60"))
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 5)
                .background(Color(hex: "#C97D60").opacity(0.1))
                .cornerRadius(15)
            }
        }
    }
    private func statsCards(profile: OtherUserProfile) -> some View {
        HStack(spacing: 15) {
            // Study time card
            VStack(alignment: .center, spacing: 8) {
                Image(systemName: "clock.fill")
                    .foregroundColor(Color(hex: "#C97D60"))
                    .font(.system(size: 22))
                
                Text(profile.formattedTotalStudyTime)
                    .font(.custom("Kiwi Maru Medium", size: 18))
                    .foregroundColor(.black)
                
                Text("Total Study Time")
                    .font(.custom("Kiwi Maru Light", size: 14))
                    .foregroundColor(Color.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color(hex: "#C97D60").opacity(0.1))
            .cornerRadius(15)
            
            // Sets count card
            VStack(alignment: .center, spacing: 8) {
                Image(systemName: "folder.fill")
                    .foregroundColor(Color(hex: "#6082C9"))
                    .font(.system(size: 22))
                
                Text("\(profile.publicSets.count)")
                    .font(.custom("Kiwi Maru Medium", size: 18))
                    .foregroundColor(.black)
                
                Text("Public Sets")
                    .font(.custom("Kiwi Maru Light", size: 14))
                    .foregroundColor(Color.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color(hex: "#6082C9").opacity(0.1))
            .cornerRadius(15)
            
            // Best streak card
            VStack(alignment: .center, spacing: 8) {
                Image(systemName: "trophy.fill")
                    .foregroundColor(Color(hex: "#60C9A7"))
                    .font(.system(size: 22))
                
                Text("\(profile.maxStreak)")
                    .font(.custom("Kiwi Maru Medium", size: 18))
                    .foregroundColor(.black)
                
                Text("Best Streak")
                    .font(.custom("Kiwi Maru Light", size: 14))
                    .foregroundColor(Color.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color(hex: "#60C9A7").opacity(0.1))
            .cornerRadius(15)
        }
        .padding(.horizontal, 20)
    }
    
    private var studyTrendSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Study Activity (Last 7 Days)")
                .font(.custom("Kiwi Maru Regular", size: 18))
                .foregroundColor(.black)
                .padding(.horizontal, 20)
            
            // Simple bar chart representation
            HStack(alignment: .bottom, spacing: 5) {
                ForEach(viewModel.analyticsData) { day in
                    VStack(spacing: 5) {
                        // Bar
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color(hex: "#C97D60"))
                            .frame(width: 30, height: day.minutesStudied > 0 ? CGFloat(day.minutesStudied / viewModel.maxDailyMinutes * 100) : 5)
                        
                        // Day label
                        let weekday = Calendar.current.component(.weekday, from: day.date) - 1
                        let dayName = Calendar.current.shortWeekdaySymbols[weekday == 0 ? 6 : weekday - 1]
                        
                        Text(dayName)
                            .font(.custom("Kiwi Maru Light", size: 12))
                            .foregroundColor(.gray)
                    }
                    .frame(height: 120, alignment: .bottom)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 20)
            .background(Color(hex: "#EFEFEF").opacity(0.5))
            .cornerRadius(15)
            .padding(.horizontal, 20)
        }
    }
    
    private func setsSection(profile: OtherUserProfile) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Public Sets")
                .font(.custom("Kiwi Maru Regular", size: 18))
                .foregroundColor(.black)
                .padding(.horizontal, 20)
            
            if profile.publicSets.isEmpty {
                Text("No public sets available")
                    .font(.custom("Kiwi Maru Light", size: 16))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            } else {
                VStack(spacing: 15) {
                    ForEach(profile.publicSets) { set in
                        NavigationLink(destination: SetDetailView(setID: set.id, setTitle: set.title)) {
                            PublicSetRow(set: set)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct PublicSetRow: View {
    let set: Set
    
    var body: some View {
        HStack(spacing: 15) {
            // Card count indicator
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(hex: "#edae95"))
                    .frame(width: 60, height: 60)
                
                VStack(spacing: 2) {
                    Text("\(set.cardCount)")
                        .font(.custom("Kiwi Maru Medium", size: 18))
                        .foregroundColor(.white)
                    
                    Text("cards")
                        .font(.custom("Kiwi Maru Light", size: 12))
                        .foregroundColor(.white)
                }
            }
            
            // Set details
            VStack(alignment: .leading, spacing: 5) {
                Text(set.title)
                    .font(.custom("Kiwi Maru Regular", size: 16))
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                if let description = set.description, !description.isEmpty {
                    Text(description)
                        .font(.custom("Kiwi Maru Light", size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Study time
                if let totalTime = set.totalStudyTime, totalTime > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "#C97D60"))
                        
                        Text(set.formattedStudyTime)
                            .font(.custom("Kiwi Maru Light", size: 12))
                            .foregroundColor(Color(hex: "#C97D60"))
                    }
                }
            }
            .padding(.vertical, 5)
            
            Spacer()
            
            // Study button
            Button(action: {
                // No action needed - NavigationLink handles navigation
            }) {
                Text("Study")
                    .font(.custom("Kiwi Maru Regular", size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#C97D60"))
                    .cornerRadius(15)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 15)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct DailyStudyData: Identifiable {
    let id = UUID()
    let date: Date
    let minutesStudied: Double
}

#Preview {
    OtherUserProfileView(userId: "preview-id")
        .environmentObject(DataManager())
}
