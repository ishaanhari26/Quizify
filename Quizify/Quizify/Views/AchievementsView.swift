//
//  AchievementsView.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 3/29/25.
//


import SwiftUI

struct AchievementsView: View {
    @ObservedObject var achievementsManager = AchievementsManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory: AchievementCategory?
    @State private var showingUnlockedOnly = false
    
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
                            
                            Text("Achievements")
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
                
                // Filter options
                VStack(spacing: 15) {
                    // Category filter pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            CategoryFilterPill(
                                title: "All",
                                isSelected: selectedCategory == nil,
                                color: Color(hex: "#C97D60"),
                                action: { selectedCategory = nil }
                            )
                            
                            ForEach(AchievementCategory.allCases, id: \.self) { category in
                                CategoryFilterPill(
                                    title: category.displayName,
                                    isSelected: selectedCategory == category,
                                    color: category.color,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                    
                    // Unlocked toggle
                    Toggle("Show unlocked only", isOn: $showingUnlockedOnly)
                        .font(.custom("Kiwi Maru Light", size: 16))
                        .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#C97D60")))
                        .padding(.horizontal, 20)
                }
                
                // Stats summary
                achievementsSummary
                    .padding(.top, 10)
                
                // Achievement list
                if achievementsManager.isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    Text("Loading achievements...")
                        .font(.custom("Kiwi Maru Light", size: 16))
                        .foregroundColor(.gray)
                        .padding()
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(filteredAchievements) { achievement in
                                AchievementDetailCard(achievement: achievement)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                        .padding(.bottom, 30)
                    }
                }
                
                // Achievement unlock animation
                if achievementsManager.showUnlockAnimation,
                    let achievement = achievementsManager.currentUnlockedAchievement {
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()
                        .overlay(
                            AchievementUnlockView(achievement: achievement)
                        )
                        .transition(.opacity)
                        .onAppear {
                            // Automatically dismiss after a few seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation {
                                    achievementsManager.showUnlockAnimation = false
                                }
                            }
                        }
                        .onTapGesture {
                            withAnimation {
                                achievementsManager.showUnlockAnimation = false
                            }
                        }
                }
            }
        }
        .onAppear {
            // Refresh achievements when view appears
            achievementsManager.loadAchievements()
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // MARK: - Computed Properties
    
    var filteredAchievements: [Achievement] {
        var achievements = achievementsManager.achievements
        
        // Filter by category if selected
        if let category = selectedCategory {
            achievements = achievements.filter { $0.category == category }
        }
        
        // Filter by unlock status if requested
        if showingUnlockedOnly {
            achievements = achievements.filter { $0.isUnlocked }
        }
        
        return achievements
    }
    
    // MARK: - Components
    
    var achievementsSummary: some View {
        HStack(spacing: 15) {
            // Total achievements count
            VStack(alignment: .center, spacing: 5) {
                Text("\(achievementsManager.achievements.count)")
                    .font(.custom("Kiwi Maru Medium", size: 24))
                    .foregroundColor(.black)
                
                Text("Total")
                    .font(.custom("Kiwi Maru Light", size: 14))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color(hex: "#EFEFEF").opacity(0.5))
            .cornerRadius(15)
            
            // Unlocked achievements count
            let unlockedCount = achievementsManager.achievements.filter { $0.isUnlocked }.count
            VStack(alignment: .center, spacing: 5) {
                Text("\(unlockedCount)")
                    .font(.custom("Kiwi Maru Medium", size: 24))
                    .foregroundColor(.black)
                
                Text("Unlocked")
                    .font(.custom("Kiwi Maru Light", size: 14))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color(hex: "#EFEFEF").opacity(0.5))
            .cornerRadius(15)
            
            // Completion percentage
            let percentage = achievementsManager.achievements.isEmpty ? 0 :
            Int(Double(unlockedCount) / Double(achievementsManager.achievements.count) * 100)
            VStack(alignment: .center, spacing: 5) {
                Text("\(percentage)%")
                    .font(.custom("Kiwi Maru Medium", size: 24))
                    .foregroundColor(.black)
                
                Text("Complete")
                    .font(.custom("Kiwi Maru Light", size: 14))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color(hex: "#EFEFEF").opacity(0.5))
            .cornerRadius(15)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Supporting Views

struct CategoryFilterPill: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Kiwi Maru Regular", size: 14))
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(isSelected ? color : Color(hex: "#EFEFEF"))
                .foregroundColor(isSelected ? .white : .black)
                .cornerRadius(20)
        }
    }
}

struct AchievementDetailCard: View {
    let achievement: Achievement
    
    var body: some View {
        HStack(spacing: 15) {
            // Achievement icon
            ZStack {
                Circle()
                    .fill(Color(hex: achievement.color).opacity(achievement.isUnlocked ? 0.2 : 0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 24))
                    .foregroundColor(achievement.isUnlocked ? Color(hex: achievement.color) : .gray)
                    .opacity(achievement.isUnlocked ? 1.0 : 0.6)
            }
            
            // Achievement details
            VStack(alignment: .leading, spacing: 5) {
                Text(achievement.title)
                    .font(.custom("Kiwi Maru Regular", size: 16))
                    .foregroundColor(achievement.isUnlocked ? .black : .gray)
                
                Text(achievement.description)
                    .font(.custom("Kiwi Maru Light", size: 14))
                    .foregroundColor(.gray)
                
                // Progress bar
                if !achievement.isUnlocked {
                    HStack(spacing: 10) {
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                Rectangle()
                                    .frame(width: geometry.size.width, height: 6)
                                    .opacity(0.1)
                                    .foregroundColor(Color(hex: achievement.color))
                                
                                // Progress
                                Rectangle()
                                    .frame(width: min(CGFloat(achievement.progress) / CGFloat(achievement.targetValue) * geometry.size.width, geometry.size.width), height: 6)
                                    .foregroundColor(Color(hex: achievement.color))
                            }
                            .cornerRadius(3)
                        }
                        .frame(height: 6)
                        
                        // Progress text
                        Text("\(achievement.progress)/\(achievement.targetValue)")
                            .font(.custom("Kiwi Maru Light", size: 12))
                            .foregroundColor(.gray)
                    }
                } else {
                    Text(achievement.formattedUnlockDate)
                        .font(.custom("Kiwi Maru Light", size: 12))
                        .foregroundColor(Color(hex: "#C97D60"))
                }
            }
            
            Spacer()
            
            // Unlock status
            if achievement.isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 24))
            } else {
                Image(systemName: "lock.fill")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
            }
        }
        .padding(15)
        .background(achievement.isUnlocked ? Color.white : Color(hex: "#F5F5F5"))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(achievement.isUnlocked ? 0.05 : 0.02), radius: 5, x: 0, y: 2)
    }
}

struct AchievementUnlockView: View {
    let achievement: Achievement
    @State private var animationComplete = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundColor(Color.yellow)
                .padding()
                .scaleEffect(animationComplete ? 1.0 : 0.5)
                .opacity(animationComplete ? 1.0 : 0.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: animationComplete)
            
            Text("Achievement Unlocked!")
                .font(.custom("Kiwi Maru Bold", size: 24))
                .foregroundColor(.white)
                .opacity(animationComplete ? 1.0 : 0.0)
                .animation(.easeIn(duration: 0.3).delay(0.3), value: animationComplete)
            
            ZStack {
                Circle()
                    .fill(Color(hex: achievement.color).opacity(0.3))
                    .frame(width: 80, height: 80)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 36))
                    .foregroundColor(Color(hex: achievement.color))
            }
            .scaleEffect(animationComplete ? 1.0 : 0.5)
            .opacity(animationComplete ? 1.0 : 0.0)
            .animation(.easeIn(duration: 0.3).delay(0.5), value: animationComplete)
            
            Text(achievement.title)
                .font(.custom("Kiwi Maru Medium", size: 20))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .opacity(animationComplete ? 1.0 : 0.0)
                .animation(.easeIn(duration: 0.3).delay(0.7), value: animationComplete)
            
            Text(achievement.description)
                .font(.custom("Kiwi Maru Light", size: 16))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .opacity(animationComplete ? 1.0 : 0.0)
                .animation(.easeIn(duration: 0.3).delay(0.9), value: animationComplete)
            
            Text("Tap anywhere to continue")
                .font(.custom("Kiwi Maru Light", size: 14))
                .foregroundColor(.white.opacity(0.7))
                .padding(.top, 30)
                .opacity(animationComplete ? 1.0 : 0.0)
                .animation(.easeIn(duration: 0.3).delay(1.1), value: animationComplete)
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.8))
        )
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        .padding(40)
        .onAppear {
            // Start animations
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animationComplete = true
            }
        }
    }
}

struct AchievementsView_Previews: PreviewProvider {
    static var previews: some View {
        AchievementsView()
    }
}
