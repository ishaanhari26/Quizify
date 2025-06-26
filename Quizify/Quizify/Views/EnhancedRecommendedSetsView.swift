//
//  EnhancedRecommendationsView.swift
//  Quizify
//
//  AI-powered personalized learning recommendations with insights
//

import SwiftUI

struct EnhancedRecommendationsView: View {
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var recommendationsManager: PersonalizedRecommendationsManager
    @State private var selectedInsightType: LearningInsight.InsightType?
    @State private var showingDetailedAnalysis = false
    
    init(dataManager: DataManager) {
        _recommendationsManager = StateObject(wrappedValue: PersonalizedRecommendationsManager(dataManager: dataManager))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with analysis status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Learning Coach")
                        .font(.custom("Kiwi Maru Medium", size: 24))
                        .foregroundColor(.black)
                    
                    if recommendationsManager.isAnalyzing {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Analyzing your learning patterns...")
                                .font(.custom("Kiwi Maru Light", size: 14))
                                .foregroundColor(.gray)
                        }
                    } else {
                        Text("Personalized insights ready")
                            .font(.custom("Kiwi Maru Light", size: 14))
                            .foregroundColor(Color(hex: "#4ECDC4"))
                    }
                }
                
                Spacer()
                
                Button(action: {
                    showingDetailedAnalysis = true
                }) {
                    Image(systemName: "chart.xyaxis.line")
                        .foregroundColor(Color(hex: "#6082C9"))
                        .font(.system(size: 20))
                }
            }
            .padding(.horizontal, 30)
            
            if !recommendationsManager.isAnalyzing {
                // Learning Insights Carousel
                if !recommendationsManager.insights.isEmpty {
                    learningInsightsSection
                }
                
                // Smart Recommendations
                if !recommendationsManager.recommendations.isEmpty {
                    smartRecommendationsSection
                }
                
                // Performance Summary Card
                if let pattern = recommendationsManager.learningPattern {
                    learningPatternSummary(pattern)
                }
            }
        }
        .onAppear {
            Task {
                await recommendationsManager.generatePersonalizedRecommendations()
            }
        }
        .sheet(isPresented: $showingDetailedAnalysis) {
            DetailedAnalysisView(manager: recommendationsManager)
        }
    }
    
    // MARK: - Learning Insights Section
    private var learningInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("💡 Learning Insights")
                .font(.custom("Kiwi Maru Regular", size: 18))
                .foregroundColor(.black)
                .padding(.horizontal, 30)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(recommendationsManager.getTopInsights(limit: 4)) { insight in
                        InsightCard(insight: insight) {
                            selectedInsightType = insight.type
                        }
                    }
                }
                .padding(.horizontal, 30)
            }
        }
    }
    
    // MARK: - Smart Recommendations Section
    private var smartRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🎯 Smart Recommendations")
                .font(.custom("Kiwi Maru Regular", size: 18))
                .foregroundColor(.black)
                .padding(.horizontal, 30)
            
            VStack(spacing: 12) {
                ForEach(recommendationsManager.getTopRecommendations(limit: 3)) { recommendation in
                    RecommendationCard(recommendation: recommendation) {
                        handleRecommendationTap(recommendation)
                    }
                }
            }
            .padding(.horizontal, 30)
        }
    }
    
    // MARK: - Learning Pattern Summary
    private func learningPatternSummary(_ pattern: LearningPattern) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📊 Your Learning Profile")
                .font(.custom("Kiwi Maru Regular", size: 18))
                .foregroundColor(.black)
                .padding(.horizontal, 30)
            
            HStack(spacing: 12) {
                // Optimal Time
                StatCard(
                    title: "Peak Time",
                    value: formatHour(pattern.optimalStudyHour),
                    icon: "clock.fill",
                    color: Color(hex: "#6082C9")
                )
                
                // Learning Speed
                StatCard(
                    title: "Speed",
                    value: "\(Int(pattern.learningVelocity)) cpm",
                    icon: "speedometer",
                    color: Color(hex: "#4ECDC4")
                )
                
                // Consistency
                StatCard(
                    title: "Consistency",
                    value: "\(Int(pattern.consistencyScore * 100))%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: Color(hex: "#96CEB4")
                )
            }
            .padding(.horizontal, 30)
        }
    }
    
    // MARK: - Helper Functions
    private func handleRecommendationTap(_ recommendation: PersonalizedRecommendation) {
        switch recommendation.recommendationType {
        case .review:
            if let setId = recommendation.setId {
                // Navigate to set detail view
                print("Navigate to set: \(setId)")
            }
        case .newTopic:
            // Navigate to create new set
            print("Navigate to create set")
        case .timing:
            // Show study timer or schedule
            print("Show study timer")
        case .difficulty:
            // Navigate to advanced sets
            print("Navigate to advanced sets")
        case .social:
            // Navigate to public sets
            print("Navigate to public sets")
        }
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date).lowercased()
    }
}

// MARK: - Insight Card Component
struct InsightCard: View {
    let insight: LearningInsight
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: insight.type.icon)
                        .foregroundColor(insight.type.color)
                        .font(.system(size: 18))
                    
                    Spacer()
                    
                    // Confidence indicator
                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Circle()
                                .fill(index < Int(insight.confidence * 5) ? insight.type.color : Color.gray.opacity(0.3))
                                .frame(width: 4, height: 4)
                        }
                    }
                }
                
                Text(insight.title)
                    .font(.custom("Kiwi Maru Medium", size: 14))
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                Text(insight.description)
                    .font(.custom("Kiwi Maru Light", size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                Spacer()
                
                // Action hint
                Text(insight.actionable)
                    .font(.custom("Kiwi Maru Regular", size: 10))
                    .foregroundColor(insight.type.color)
                    .lineLimit(2)
                    .padding(.top, 4)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(insight.type.color.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(12)
            .frame(width: 160, height: 140)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: insight.type.color.opacity(0.2), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(insight.type.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Recommendation Card Component
struct RecommendationCard: View {
    let recommendation: PersonalizedRecommendation
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon with confidence ring
                ZStack {
                    Circle()
                        .stroke(recommendation.recommendationType.color.opacity(0.3), lineWidth: 2)
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .trim(from: 0, to: recommendation.confidence)
                        .stroke(recommendation.recommendationType.color, lineWidth: 2)
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-90))
                    
                    Image(systemName: recommendation.recommendationType.icon)
                        .foregroundColor(recommendation.recommendationType.color)
                        .font(.system(size: 16))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.title)
                        .font(.custom("Kiwi Maru Medium", size: 14))
                        .foregroundColor(.black)
                        .lineLimit(1)
                    
                    Text(recommendation.description)
                        .font(.custom("Kiwi Maru Light", size: 12))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    Text(recommendation.estimatedBenefit)
                        .font(.custom("Kiwi Maru Regular", size: 10))
                        .foregroundColor(recommendation.recommendationType.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(recommendation.recommendationType.color.opacity(0.1))
                        .cornerRadius(6)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(recommendation.recommendationType.color)
                    .font(.system(size: 12))
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(recommendation.recommendationType.color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 16))
            
            Text(value)
                .font(.custom("Kiwi Maru Medium", size: 16))
                .foregroundColor(.black)
            
            Text(title)
                .font(.custom("Kiwi Maru Light", size: 10))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Detailed Analysis View
struct DetailedAnalysisView: View {
    let manager: PersonalizedRecommendationsManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let pattern = manager.learningPattern {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Learning Pattern Analysis")
                                .font(.custom("Kiwi Maru Medium", size: 20))
                                .foregroundColor(.black)
                            
                            // Detailed metrics
                            MetricRow(title: "Optimal Study Hour", value: "\(pattern.optimalStudyHour):00", description: "Your peak learning time")
                            MetricRow(title: "Average Session", value: "\(Int(pattern.averageSessionLength/60)) min", description: "Typical study duration")
                            MetricRow(title: "Learning Velocity", value: "\(String(format: "%.1f", pattern.learningVelocity)) cpm", description: "Cards mastered per minute")
                            MetricRow(title: "Retention Rate", value: "\(Int(pattern.retentionRate * 100))%", description: "Knowledge retention score")
                            MetricRow(title: "Consistency Score", value: "\(Int(pattern.consistencyScore * 100))%", description: "Study regularity")
                        }
                        .padding()
                        .background(Color(hex: "#F8F9FA"))
                        .cornerRadius(12)
                    }
                    
                    // All insights
                    VStack(alignment: .leading, spacing: 12) {
                        Text("All Learning Insights")
                            .font(.custom("Kiwi Maru Medium", size: 18))
                            .foregroundColor(.black)
                        
                        ForEach(manager.insights) { insight in
                            DetailedInsightRow(insight: insight)
                        }
                    }
                    
                    // All recommendations
                    VStack(alignment: .leading, spacing: 12) {
                        Text("All Recommendations")
                            .font(.custom("Kiwi Maru Medium", size: 18))
                            .foregroundColor(.black)
                        
                        ForEach(manager.recommendations) { recommendation in
                            DetailedRecommendationRow(recommendation: recommendation)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Learning Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    let description: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Kiwi Maru Regular", size: 14))
                    .foregroundColor(.black)
                Text(description)
                    .font(.custom("Kiwi Maru Light", size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(value)
                .font(.custom("Kiwi Maru Medium", size: 16))
                .foregroundColor(Color(hex: "#6082C9"))
        }
        .padding(.vertical, 4)
    }
}

struct DetailedInsightRow: View {
    let insight: LearningInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: insight.type.icon)
                    .foregroundColor(insight.type.color)
                
                Text(insight.title)
                    .font(.custom("Kiwi Maru Medium", size: 14))
                    .foregroundColor(.black)
                
                Spacer()
                
                Text("\(Int(insight.confidence * 100))%")
                    .font(.custom("Kiwi Maru Light", size: 12))
                    .foregroundColor(.gray)
            }
            
            Text(insight.description)
                .font(.custom("Kiwi Maru Light", size: 12))
                .foregroundColor(.gray)
            
            Text("💡 \(insight.actionable)")
                .font(.custom("Kiwi Maru Regular", size: 12))
                .foregroundColor(insight.type.color)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct DetailedRecommendationRow: View {
    let recommendation: PersonalizedRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: recommendation.recommendationType.icon)
                    .foregroundColor(recommendation.recommendationType.color)
                
                Text(recommendation.title)
                    .font(.custom("Kiwi Maru Medium", size: 14))
                    .foregroundColor(.black)
                
                Spacer()
                
                Text("\(Int(recommendation.confidence * 100))%")
                    .font(.custom("Kiwi Maru Light", size: 12))
                    .foregroundColor(.gray)
            }
            
            Text(recommendation.description)
                .font(.custom("Kiwi Maru Light", size: 12))
                .foregroundColor(.gray)
            
            Text("🎯 \(recommendation.reasoning)")
                .font(.custom("Kiwi Maru Regular", size: 12))
                .foregroundColor(recommendation.recommendationType.color)
            
            Text("📈 \(recommendation.estimatedBenefit)")
                .font(.custom("Kiwi Maru Light", size: 11))
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    EnhancedRecommendationsView(dataManager: DataManager())
}
