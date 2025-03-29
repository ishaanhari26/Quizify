//
//  AchievementsSectionView.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 3/29/25.
//


import SwiftUI

struct AchievementsSectionView: View {
    @ObservedObject var achievementsManager = AchievementsManager.shared
    @State private var showAllAchievements = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Achievements")
                    .font(.custom("Kiwi Maru Light", size: 25))
                    .foregroundColor(Color(.gray))
                
                Spacer()
                
                NavigationLink(destination: AchievementsView()) {
                    Text("See All")
                        .font(.custom("Kiwi Maru Light", size: 16))
                        .foregroundColor(Color(hex: "#C97D60"))
                }
            }
            .padding(.leading, 30)
            .padding(.trailing, 30)
            .padding(.bottom, 10)
            
            if achievementsManager.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                        .padding()
                    Spacer()
                }
                .frame(height: 150)
            } else if achievementsManager.achievements.isEmpty {
                emptyAchievementsView
            } else {
                achievementsContent
            }
        }
    }
    
    private var emptyAchievementsView: some View {
        HStack {
            Spacer()
            VStack(spacing: 10) {
                Image(systemName: "trophy")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: "#C97D60").opacity(0.7))
                
                Text("No achievements yet")
                    .font(.custom("Kiwi Maru Regular", size: 18))
                    .foregroundColor(.gray)
                
                Text("Keep learning to unlock achievements!")
                    .font(.custom("Kiwi Maru Light", size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 30)
            Spacer()
        }
        .frame(height: 150)
    }
    
    private var achievementsContent: some View {
        VStack(spacing: 15) {
            // Recent unlocks section (if any)
            if !achievementsManager.recentlyUnlocked.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Recently Unlocked")
                        .font(.custom("Kiwi Maru Regular", size: 16))
                        .foregroundColor(.gray)
                        .padding(.leading, 30)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(achievementsManager.recentlyUnlocked) { achievement in
                                RecentAchievementCard(achievement: achievement)
                            }
                        }
                        .padding(.horizontal, 30)
                    }
                }
            }
            
            // Progress section - show some achievements in progress
            VStack(alignment: .leading, spacing: 10) {
                Text("In Progress")
                    .font(.custom("Kiwi Maru Regular", size: 16))
                    .foregroundColor(.gray)
                    .padding(.leading, 30)
                
                let inProgressAchievements = achievementsManager.achievements
                    .filter { !$0.isUnlocked && $0.progress > 0 }
                    .prefix(3)
                
                if inProgressAchievements.isEmpty {
                    HStack {
                        Spacer()
                        Text("Keep studying to make progress!")
                            .font(.custom("Kiwi Maru Light", size: 14))
                            .foregroundColor(.gray)
                            .padding()
                        Spacer()
                    }
                } else {
                    VStack(spacing: 12) {
                        ForEach(Array(inProgressAchievements)) { achievement in
                            AchievementProgressRow(achievement: achievement)
                        }
                    }
                    .padding(.horizontal, 30)
                }
            }
        }
    }
}

// Card for recently unlocked achievements
struct RecentAchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color(hex: achievement.color).opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 30))
                    .foregroundColor(Color(hex: achievement.color))
            }
            
            Text(achievement.title)
                .font(.custom("Kiwi Maru Regular", size: 14))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 120)
            
            Text("NEW!")
                .font(.custom("Kiwi Maru Bold", size: 12))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(hex: "#C97D60"))
                .cornerRadius(10)
        }
        .frame(width: 120, height: 150)
        .padding(10)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// Row for in-progress achievements
struct AchievementProgressRow: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: achievement.icon)
                    .foregroundColor(Color(hex: achievement.color))
                    .font(.system(size: 18))
                
                Text(achievement.title)
                    .font(.custom("Kiwi Maru Regular", size: 16))
                    .foregroundColor(.black)
                
                Spacer()
                
                Text("\(achievement.progress)/\(achievement.targetValue)")
                    .font(.custom("Kiwi Maru Light", size: 14))
                    .foregroundColor(.gray)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .frame(width: geometry.size.width, height: 8)
                        .opacity(0.1)
                        .foregroundColor(Color(hex: achievement.color))
                    
                    // Progress
                    Rectangle()
                        .frame(width: min(CGFloat(achievement.progress) / CGFloat(achievement.targetValue) * geometry.size.width, geometry.size.width), height: 8)
                        .foregroundColor(Color(hex: achievement.color))
                }
                .cornerRadius(4)
            }
            .frame(height: 8)
            
            Text(achievement.description)
                .font(.custom("Kiwi Maru Light", size: 12))
                .foregroundColor(.gray)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct AchievementsSectionView_Previews: PreviewProvider {
    static var previews: some View {
        AchievementsSectionView()
    }
}
