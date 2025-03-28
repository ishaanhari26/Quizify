//
//  StudyAnalyticsView.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 3/27/25.
//

// StudyAnalyticsView.swift
import SwiftUI
import Charts

struct StudyAnalyticsView: View {
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var viewModel = StudyAnalyticsViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                if viewModel.isLoading {
                    loadingView
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Summary cards
                            HStack(spacing: 15) {
                                summaryCard(
                                    title: "Total Study Time",
                                    value: viewModel.formattedTotalStudyTime,
                                    icon: "clock.fill",
                                    color: Color(hex: "#C97D60")
                                )
                                
                                summaryCard(
                                    title: "Sets Studied",
                                    value: "\(viewModel.setsStudied)",
                                    icon: "book.fill",
                                    color: Color(hex: "#6082C9")
                                )
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)
                            
                            // Study time by set chart
                            studyTimeBySetChart
                            
                            // Study trend chart
                            studyTrendChart
                            
                            // Study habits insights
                            studyHabitsSection
                            
                            // Most studied sets
                            mostStudiedSetsSection
                        }
                        .padding(.bottom, 50)
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadAnalytics(dataManager: dataManager)
        }
        .navigationBarBackButtonHidden(true)
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
                    
                    Text("Study Analytics")
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
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            Text("Loading analytics...")
                .font(.custom("Kiwi Maru Light", size: 16))
                .foregroundColor(.gray)
                .padding()
            Spacer()
        }
    }
    
    private func summaryCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18))
                
                Text(title)
                    .font(.custom("Kiwi Maru Light", size: 14))
                    .foregroundColor(.gray)
            }
            
            Text(value)
                .font(.custom("Kiwi Maru Medium", size: 28))
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(16)
    }
    
    private var studyTimeBySetChart: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Study Time by Set")
                .font(.custom("Kiwi Maru Regular", size: 18))
                .foregroundColor(.black)
                .padding(.horizontal)
            
            if viewModel.setStudyData.isEmpty {
                emptyChartView(message: "No study data yet")
            } else {
                Chart {
                    ForEach(viewModel.setStudyData) { item in
                        BarMark(
                            x: .value("Study Time", item.timeInMinutes),
                            y: .value("Set", item.title)
                        )
                        .foregroundStyle(Color(hex: "#C97D60"))
                        .annotation(position: .trailing) {
                            Text(item.formattedTime)
                                .font(.custom("Kiwi Maru Light", size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .frame(height: min(CGFloat(viewModel.setStudyData.count * 50), 300))
                .padding()
                .background(Color(hex: "#EFEFEF").opacity(0.5))
                .cornerRadius(16)
                .padding(.horizontal)
            }
        }
    }
    
    private var studyTrendChart: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Study Trend (Last 7 Days)")
                .font(.custom("Kiwi Maru Regular", size: 18))
                .foregroundColor(.black)
                .padding(.horizontal)
            
            if viewModel.dailyStudyData.isEmpty {
                emptyChartView(message: "No trend data yet")
            } else {
                Chart {
                    ForEach(viewModel.dailyStudyData) { item in
                        LineMark(
                            x: .value("Date", item.date, unit: .day),
                            y: .value("Minutes", item.minutesStudied)
                        )
                        .foregroundStyle(Color(hex: "#6082C9"))
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("Date", item.date, unit: .day),
                            y: .value("Minutes", item.minutesStudied)
                        )
                        .foregroundStyle(
                            .linearGradient(
                                colors: [Color(hex: "#6082C9").opacity(0.3), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                        
                        PointMark(
                            x: .value("Date", item.date, unit: .day),
                            y: .value("Minutes", item.minutesStudied)
                        )
                        .foregroundStyle(Color(hex: "#6082C9"))
                    }
                }
                .frame(height: 200)
                .chartYScale(domain: 0...(viewModel.maxDailyMinutes + 10))
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                }
                .padding()
                .background(Color(hex: "#EFEFEF").opacity(0.5))
                .cornerRadius(16)
                .padding(.horizontal)
            }
        }
    }
    
    private var studyHabitsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Study Habits")
                .font(.custom("Kiwi Maru Regular", size: 18))
                .foregroundColor(.black)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Image(systemName: "star.fill")
                        .foregroundColor(Color(hex: "#C97D60"))
                        .font(.system(size: 18))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Average Study Time")
                            .font(.custom("Kiwi Maru Regular", size: 16))
                            .foregroundColor(.black)
                        
                        Text(viewModel.averageStudyTimePerSession)
                            .font(.custom("Kiwi Maru Light", size: 14))
                            .foregroundColor(.gray)
                    }
                }
                
                HStack(alignment: .top) {
                    Image(systemName: "calendar")
                        .foregroundColor(Color(hex: "#C97D60"))
                        .font(.system(size: 18))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Most Active Day")
                            .font(.custom("Kiwi Maru Regular", size: 16))
                            .foregroundColor(.black)
                        
                        Text(viewModel.mostActiveDay)
                            .font(.custom("Kiwi Maru Light", size: 14))
                            .foregroundColor(.gray)
                    }
                }
                
                HStack(alignment: .top) {
                    Image(systemName: "arrow.up.forward")
                        .foregroundColor(Color(hex: "#C97D60"))
                        .font(.system(size: 18))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Study Streak")
                            .font(.custom("Kiwi Maru Regular", size: 16))
                            .foregroundColor(.black)
                        
                        Text(viewModel.currentStreak)
                            .font(.custom("Kiwi Maru Light", size: 14))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color(hex: "#EFEFEF").opacity(0.5))
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
    
    private var mostStudiedSetsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Most Studied Sets")
                .font(.custom("Kiwi Maru Regular", size: 18))
                .foregroundColor(.black)
                .padding(.horizontal)
            
            if viewModel.topSets.isEmpty {
                emptyChartView(message: "No sets studied yet")
            } else {
                VStack(spacing: 15) {
                    ForEach(viewModel.topSets) { set in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(set.title)
                                    .font(.custom("Kiwi Maru Regular", size: 16))
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                                
                                Text("\(set.cardCount) cards")
                                    .font(.custom("Kiwi Maru Light", size: 12))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Text(set.formattedStudyTime)
                                .font(.custom("Kiwi Maru Medium", size: 16))
                                .foregroundColor(Color(hex: "#C97D60"))
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func emptyChartView(message: String) -> some View {
        VStack {
            Text(message)
                .font(.custom("Kiwi Maru Light", size: 16))
                .foregroundColor(.gray)
                .padding()
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#EFEFEF").opacity(0.5))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// View Model for Analytics
class StudyAnalyticsViewModel: ObservableObject {
    @Published var isLoading = true
    @Published var totalStudyTime: TimeInterval = 0
    @Published var setsStudied = 0
    @Published var setStudyData: [SetStudyData] = []
    @Published var dailyStudyData: [DailyStudyData] = []
    @Published var topSets: [Set] = []
    @Published var maxDailyMinutes: Double = 60 // Default max for chart
    
    // Formatted strings for display
    var formattedTotalStudyTime: String {
        formatTimeInterval(totalStudyTime)
    }
    
    var averageStudyTimePerSession: String {
        if setsStudied == 0 {
            return "No data yet"
        }
        let averageTime = totalStudyTime / Double(setsStudied)
        return "Average \(formatTimeInterval(averageTime)) per session"
    }
    
    var mostActiveDay: String {
        if dailyStudyData.isEmpty {
            return "No data yet"
        }
        
        if let mostActive = dailyStudyData.max(by: { $0.minutesStudied < $1.minutesStudied }) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return "\(formatter.string(from: mostActive.date)) with \(Int(mostActive.minutesStudied)) minutes"
        }
        
        return "No data yet"
    }
    
    var currentStreak: String {
        // This would require more complex logic and date tracking
        // For now, return a placeholder
        return "Current streak: 0 days"
    }
    
    // Models for charts
    struct SetStudyData: Identifiable {
        let id = UUID()
        let setID: String
        let title: String
        let studyTime: TimeInterval
        
        var timeInMinutes: Double {
            studyTime / 60
        }
        
        var formattedTime: String {
            formatTimeInterval(studyTime)
        }
    }
    
    struct DailyStudyData: Identifiable {
        let id = UUID()
        let date: Date
        let minutesStudied: Double
    }
    
    func loadAnalytics(dataManager: DataManager) {
        isLoading = true
        
        // This would typically be fetched from Firestore
        // For now, we'll generate sample data based on the sets
        
        // 1. Get all sets from DataManager
        let studiedSets = dataManager.sets.filter { $0.totalStudyTime != nil && $0.totalStudyTime! > 0 }
        
        // 2. Calculate total study time
        totalStudyTime = studiedSets.reduce(0) { $0 + ($1.totalStudyTime ?? 0) }
        
        // 3. Count sets studied
        setsStudied = studiedSets.count
        
        // 4. Create set study data for chart
        setStudyData = studiedSets.map { set in
            SetStudyData(
                setID: set.id,
                title: set.title,
                studyTime: set.totalStudyTime ?? 0
            )
        }
        .sorted(by: { $0.studyTime > $1.studyTime })
        
        // 5. Create daily study data (sample data for now)
        generateSampleDailyData()
        
        // 6. Get top sets
        topSets = Array(studiedSets.sorted(by: { ($0.totalStudyTime ?? 0) > ($1.totalStudyTime ?? 0) }).prefix(3))
        
        isLoading = false
    }
    
    // Generate sample daily data for the chart
    private func generateSampleDailyData() {
        let calendar = Calendar.current
        let today = Date()
        
        // Create data for the last 7 days
        var dailyData: [DailyStudyData] = []
        var maxMinutes = 0.0
        
        for day in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -day, to: today) {
                // Generate random study time between 0 and 120 minutes
                // In a real app, this would come from Firestore
                let minutes = Double.random(in: 0...120)
                if minutes > maxMinutes {
                    maxMinutes = minutes
                }
                
                dailyData.append(DailyStudyData(
                    date: date,
                    minutesStudied: minutes
                ))
            }
        }
        
        // Sort by date
        dailyStudyData = dailyData.sorted(by: { $0.date < $1.date })
        maxDailyMinutes = maxMinutes
    }
}

// Helper function to format time intervals
func formatTimeInterval(_ interval: TimeInterval) -> String {
    let hours = Int(interval) / 3600
    let minutes = (Int(interval) % 3600) / 60
    
    if hours > 0 {
        return "\(hours)h \(minutes)m"
    } else {
        return "\(minutes)m"
    }
}

#Preview {
    StudyAnalyticsView()
}
