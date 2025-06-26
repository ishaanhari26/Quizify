//
//  HomeView.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 11/14/24.
//

import SwiftUI

import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

@MainActor
final class SettingsViewModel : ObservableObject {
    func logOut() throws {
        try AuthManager.shared.signOut()
    }
}

struct HomeView: View {
    @State private var showMenu = false
    @StateObject private var viewModel = SettingsViewModel()
    @Binding var goToGreet: Bool
    @State private var navigateToGreet = false
    @EnvironmentObject var dataManager: DataManager
    @State private var isLoading = true
    @State private var analyticsData: AnalyticsSummary? = nil
    @State private var isLoadingAnalytics = true
    
    // MARK: - Side Menu Item View
    private struct SideMenuItem: View {
        let title: String
        let icon: String
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack(spacing: 15) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "#C97D60"))
                    Text(title)
                        .font(.custom("Kiwi Maru Light", size: 16))
                        .foregroundColor(.black)
                }
            }
        }
    }
    
    // MARK: - Side Menu Content
    private var sideMenuContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(.quzifyLogo)
                    .resizable()
                    .frame(width: 50, height: 50)
                Text("Quizify")
                    .font(.custom("Kiwi Maru Medium", size: 24))
                    .foregroundColor(Color(hex: "#C97D60"))
            }
            .padding(.top, 50)
            .padding(.horizontal)
            
            Divider()
                .padding(.top)
            
            
            
            VStack(alignment: .leading, spacing: 20) {
                
                
                NavigationLink(destination: ProfileView().environmentObject(dataManager)) {
                    HStack(spacing: 15) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "#C97D60"))
                        Text("Profile")
                            .font(.custom("Kiwi Maru Light", size: 16))
                            .foregroundColor(.black)
                    }
                }
                
                NavigationLink(destination: UserDiscoveryView()) {
                    HStack(spacing: 15) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "#C97D60"))
                        Text("Find Users")
                            .font(.custom("Kiwi Maru Light", size: 16))
                            .foregroundColor(.black)
                    }
                }
                
                NavigationLink(destination: SetsListView()) {
                    HStack(spacing: 15) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "#C97D60"))
                        Text("My Sets")
                            .font(.custom("Kiwi Maru Light", size: 16))
                            .foregroundColor(.black)
                    }
                }
                
                NavigationLink(destination: AchievementsView()) {
                    HStack(spacing: 15) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "#C97D60"))
                        Text("Achievements")
                            .font(.custom("Kiwi Maru Light", size: 16))
                            .foregroundColor(.black)
                    }
                }
                
                
                NavigationLink(destination: StudyAnalyticsView().environmentObject(dataManager)) {
                    HStack(spacing: 15) {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "#C97D60"))
                        Text("Analytics")
                            .font(.custom("Kiwi Maru Light", size: 16))
                            .foregroundColor(.black)
                    }
                }
            }
            .padding(.top, 40)
            .padding(.horizontal)
            Spacer()
            
            Divider()
            SideMenuItem(title: "Sign Out", icon: "arrow.right.square.fill") {
                Task {
                    do {
                        try viewModel.logOut()
                        navigateToGreet = true  // Navigate to GreetingView instead of dismissing
                    } catch {
                        print(error)
                    }
                }
            }
            .padding()
            .padding(.bottom, 15)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.white)
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Side Menu
            GeometryReader { _ in
                sideMenuContent
                    .frame(width: 270)
                    .offset(x: showMenu ? 0 : -270)
                    .background(showMenu ? Color.white : Color.clear)
            }
            .background(Color.clear)
            
            // Main content
            NavigationView {
                ZStack(alignment: .top) {
                    // Scrolling content
                    ScrollView(.vertical) {
                        VStack(alignment: .leading) {
                            Spacer()
                                .frame(height: 100)
                            
                            HStack {
                                Text("Sets")
                                    .font(.custom("Kiwi Maru Light", size: 25))
                                    .foregroundColor(Color(.gray))
                                
                                Spacer()
                                
                                NavigationLink(destination: SetsListView()) {
                                    Text("See All")
                                        .font(.custom("Kiwi Maru Light", size: 16))
                                        .foregroundColor(Color(hex: "#C97D60"))
                                }
                            }
                            .padding(.leading, 30)
                            .padding(.trailing, 30)
                            .padding(.bottom, 10)
                            
                            if isLoading {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .scaleEffect(1.2)
                                        .padding()
                                    Spacer()
                                }
                            } else if dataManager.sets.isEmpty {
                                emptySetView
                            } else {
                                // Display sets in horizontal scroll
                                ScrollView(.horizontal) {
                                    HStack(spacing: 20) {
                                        ForEach(dataManager.sets) { set in
                                            NavigationLink(destination: SetDetailView(setID: set.id, setTitle: set.title)) {
                                                SetTileView(set: set)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 30)
                                }
                                .scrollIndicators(.hidden)
                            }
                            
                            Spacer().frame(height: 30)
                            
                            // Analytics Section
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("Study Activity")
                                        .font(.custom("Kiwi Maru Light", size: 25))
                                        .foregroundColor(Color(.gray))
                                    
                                    Spacer()
                                    
                                    NavigationLink(destination: StudyAnalyticsView().environmentObject(dataManager)) {
                                        Text("See All")
                                            .font(.custom("Kiwi Maru Light", size: 16))
                                            .foregroundColor(Color(hex: "#C97D60"))
                                    }
                                }
                                .padding(.leading, 30)
                                .padding(.trailing, 30)
                                .padding(.bottom, 10)
                                
                                if isLoadingAnalytics {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                            .scaleEffect(1.2)
                                            .padding()
                                        Spacer()
                                    }
                                    .frame(height: 200)
                                } else if let data = analyticsData {
                                    studyAnalyticsView(data: data)
                                } else {
                                    Text("Empty Analytics")
                                }
                            }
                            

                            
                            Spacer().frame(height: 30)
                            
                        
                            
                            // Enhanced AI Learning Coach Section
                            EnhancedRecommendationsView(dataManager: dataManager)
                                .environmentObject(dataManager)
                            
                            // Optional: Keep original recommended sets as fallback or additional content
                            Spacer().frame(height: 20)
                            
                            // Traditional Recommended Sets (Optional - can be removed)
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("Curated Sets")
                                        .font(.custom("Kiwi Maru Light", size: 20))
                                        .foregroundColor(Color(.gray))
                                    
                                    Spacer()
                                    
                                    NavigationLink(destination: EnhancedRecommendationsView(dataManager: dataManager).environmentObject(dataManager)) {
                                        Text("See All")
                                            .font(.custom("Kiwi Maru Light", size: 16))
                                            .foregroundColor(Color(hex: "#C97D60"))
                                    }
                                }
                                .padding(.horizontal, 30)
                                
                                // Compact version of traditional recommendations
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(0..<3) { index in
                                            CompactRecommendedSetCard(index: index)
                                        }
                                    }
                                    .padding(.horizontal, 30)
                                }
                            }

                            
                            Spacer().frame(height: 30)
                            
                            VStack(alignment: .leading) {
                                

                                AchievementsSectionView()
                                   
                            }

                            
                            
                        }
                        .padding(.bottom, 50)
                        .onAppear {
                            isLoading = true
                            dataManager.fetchSets()
                            // Add a small delay to show loading indicator
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isLoading = false
                            }
                            
                            // Load analytics data
                            isLoadingAnalytics = true
                            loadAnalyticsSummary()
                        }
                    }
                    
                    // Floating header with GeometryReader
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            // Menu Button
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showMenu.toggle()
                                }
                            }) {
                                Image(systemName: "text.justify")
                                    .foregroundColor(.black)
                                    .font(.system(size: 20))
                                    .frame(width: 40)
                                    .contentShape(Rectangle())
                            }
                            
                            Spacer()
                            
                            // Quizify logo and text
                            HStack(spacing: 0) {
                                Text("Quizify")
                                    .font(.custom("Kiwi Maru Light", size: 30))
                                    .foregroundColor(Color(.black))
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                                
                                Image(.quzifyLogo)
                                    .resizable()
                                    .frame(width: 70, height: 70)
                                    .padding(.leading, -5)
                            }
                            .frame(maxWidth: geometry.size.width * 0.5)
                            
                            Spacer()
                            
                            // Plus button
                            NavigationLink(destination: NewSetView()) {
                                Image(systemName: "plus")
                                    .foregroundColor(.black)
                                    .font(.system(size: 25))
                                    .frame(width: 40)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                        .background(
                            ZStack {
                                Color.white.opacity(0.6)
                                Rectangle()
                                    .fill(.white)
                                    .opacity(0.6)
                                    .background(.ultraThinMaterial)
                                    .blur(radius: 8)
                            }
                                .cornerRadius(30)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 5)
                        .padding(.horizontal)
                    }
                    .frame(height: 100)
                }
                .navigationDestination(isPresented: $navigateToGreet) {
                    GreetingView()
                        .navigationBarBackButtonHidden(true)
                }
                .onAppear {
                    isLoading = true
                    dataManager.fetchSets()
                    // Add a small delay to show loading indicator
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isLoading = false
                    }
                }
            }
            .offset(x: showMenu ? 270 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea()
        .preferredColorScheme(.light)
    }
    
    
    
    
    
    private func studyAnalyticsView(data: AnalyticsSummary) -> some View {
        VStack(spacing: 15) {
            // Study streak and total time
            HStack(spacing: 20) {
                // Streak card
                VStack(alignment: .center, spacing: 8) {
                    HStack(spacing: 5) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(Color(hex: "#C97D60"))
                            .font(.system(size: 18))
                        
                        Text("Streak")
                            .font(.custom("Kiwi Maru Light", size: 14))
                            .foregroundColor(Color.gray)
                    }
                    
                    Text("\(data.currentStreak)")
                        .font(.custom("Kiwi Maru Medium", size: 28))
                        .foregroundColor(.black)
                    
                    Text("days")
                        .font(.custom("Kiwi Maru Light", size: 14))
                        .foregroundColor(Color.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                
                // Total study time
                VStack(alignment: .center, spacing: 8) {
                    HStack(spacing: 5) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(Color(hex: "#C97D60"))
                            .font(.system(size: 18))
                        
                        Text("Study Time")
                            .font(.custom("Kiwi Maru Light", size: 14))
                            .foregroundColor(Color.gray)
                    }
                    
                    Text(data.formattedTotalTime)
                        .font(.custom("Kiwi Maru Medium", size: 28))
                        .foregroundColor(.black)
                    
                    Text("total")
                        .font(.custom("Kiwi Maru Light", size: 14))
                        .foregroundColor(Color.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
            }
            .padding(.horizontal, 30)
            
            // Weekly study trend
            if !data.dailyData.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("This Week")
                        .font(.custom("Kiwi Maru Light", size: 16))
                        .foregroundColor(Color.gray)
                        .padding(.leading, 30)
                    
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(data.dailyData) { day in
                            VStack(spacing: 5) {
                                // Activity bar
                                ZStack(alignment: .bottom) {
                                    // Background bar
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(hex: "#EFEFEF"))
                                        .frame(width: 25, height: 100)
                                    
                                    // Activity bar (scaled to max height of 100)
                                    if day.minutes > 0 {
                                        let height = min(100, max(5, day.minutes / data.maxMinutes * 100))
                                        
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color(hex: "#C97D60"))
                                            .frame(width: 25, height: height)
                                    }
                                }
                                
                                // Day label
                                Text(day.shortName)
                                    .font(.custom("Kiwi Maru Light", size: 12))
                                    .foregroundColor(Color.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 15)
                    .padding(.bottom, 5)
                }
                .padding(.vertical, 15)
                .background(Color.white)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                .padding(.horizontal, 30)
                .padding(.top, 5)
            }
        }
    }
    
    // Function to load analytics summary
    private func loadAnalyticsSummary() {
        // Get streak information
        dataManager.getStudyStreak { currentStreak, maxStreak, lastStudyDate in
            // Get daily study data
            dataManager.getDailyStudyData(days: 7) { dailyData in
                // Calculate total study time
                let totalTime = self.dataManager.sets.reduce(0) { $0 + ($1.totalStudyTime ?? 0) }
                
                // Create daily activity data
                let calendar = Calendar.current
                let weekdaySymbols = calendar.shortWeekdaySymbols // ["Sun", "Mon", "Tue", ...]
                
                var activityData: [DayActivity] = []
                var maxMinutes: Double = 1 // Avoid division by zero
                
                // Process the daily data
                for item in dailyData {
                    let minutes = item.minutesStudied
                    if minutes > maxMinutes {
                        maxMinutes = minutes
                    }
                    
                    let weekday = calendar.component(.weekday, from: item.date) - 1 // 0-based index
                    let shortName = weekdaySymbols[weekday]
                    
                    activityData.append(DayActivity(
                        id: shortName,
                        shortName: shortName,
                        minutes: minutes
                    ))
                }
                
                // Create the analytics summary
                self.analyticsData = AnalyticsSummary(
                    currentStreak: currentStreak,
                    maxStreak: maxStreak,
                    totalStudyTime: totalTime,
                    formattedTotalTime: formatTimeInterval(totalTime),
                    dailyData: activityData,
                    maxMinutes: maxMinutes
                )
                
                self.isLoadingAnalytics = false
            }
        }
    }
    
    
    
    
    // Empty state view when no sets are available
    private var emptySetView: some View {
        HStack {
            Spacer()
            VStack(spacing: 15) {
                Image(systemName: "square.stack.3d.up.slash")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: "#C97D60").opacity(0.7))
                
                Text("No sets yet")
                    .font(.custom("Kiwi Maru Regular", size: 18))
                    .foregroundColor(Color.gray)
                
                NavigationLink(destination: NewSetView()) {
                    Text("Create your first set")
                        .font(.custom("Kiwi Maru Regular", size: 16))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color(hex: "#C97D60"))
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
            }
            .padding(.vertical, 30)
            Spacer()
        }
        .frame(height: 170)
    }
}

// MARK: - Compact Recommended Set Card
struct CompactRecommendedSetCard: View {
    let index: Int
    
    // Sample data - replace with actual recommended sets
    private let sampleSets = [
        ("AP Biology Basics", "Cell Structure & Function", "Biology", 12),
        ("Chemistry Essentials", "Periodic Trends", "Chemistry", 15),
        ("Physics Fundamentals", "Forces & Motion", "Physics", 10)
    ]
    
    var body: some View {
        let set = sampleSets[index % sampleSets.count]
        
        VStack(alignment: .leading, spacing: 8) {
            // Subject badge
            Text(set.2)
                .font(.custom("Kiwi Maru Light", size: 10))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color(hex: "#6082C9"))
                .cornerRadius(8)
            
            Spacer()
            
            // Set title
            Text(set.0)
                .font(.custom("Kiwi Maru Regular", size: 12))
                .foregroundColor(.white)
                .lineLimit(2)
            
            // Description
            Text(set.1)
                .font(.custom("Kiwi Maru Light", size: 10))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
            
            // Card count
            HStack {
                Text("\(set.3) cards")
                    .font(.custom("Kiwi Maru Light", size: 10))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 14))
            }
        }
        .padding(10)
        .frame(width: 120, height: 100)
        .background(Color(hex: "#C97D60"))
        .cornerRadius(10)
    }
}

// Update SetTileView in HomeView.swift or SetsListView.swift
struct SetTileView: View {
    let set: Set
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Card count indicator
            HStack {
                Text("\(set.cardCount)")
                    .font(.custom("Kiwi Maru Medium", size: 18))
                    .foregroundColor(.white)
                
                Text("cards")
                    .font(.custom("Kiwi Maru Light", size: 12))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Add study time indicator if available
                if let _ = set.totalStudyTime, let totalTime = set.totalStudyTime, totalTime > 0 {
                    Image(systemName: "clock")
                        .foregroundColor(.white)
                        .font(.system(size: 12))
                }
            }
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
            
            // Add study time if available and greater than zero
            if let totalTime = set.totalStudyTime, totalTime > 0 {
                Text(set.formattedStudyTime)
                    .font(.custom("Kiwi Maru Light", size: 12))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 10)
                    .padding(.bottom, 5)
            } else {
                Spacer().frame(height: 5)
            }
            
            // Bottom padding if no study time
            if set.totalStudyTime == nil || set.totalStudyTime == 0 {
                Spacer().frame(height: 10)
            }
        }
        .frame(width: 160, height: 145)
        .background(Color(hex: "#C97D60"))
        .cornerRadius(15)
    }
}

// Data models for analytics summary
struct AnalyticsSummary {
    let currentStreak: Int
    let maxStreak: Int
    let totalStudyTime: TimeInterval
    let formattedTotalTime: String
    let dailyData: [DayActivity]
    let maxMinutes: Double
}

struct DayActivity: Identifiable {
    let id: String
    let shortName: String
    let minutes: Double
}

#Preview {
    HomeView(goToGreet: .constant(false))
        .environmentObject(DataManager())
}
