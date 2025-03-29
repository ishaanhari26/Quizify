//
//  NewSetView.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 11/17/24.
//

import SwiftUI

struct NewSetView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedOption: CreationOption? = nil
    @State private var animateOptions = false
    
    enum CreationOption {
        case generate, manual
    }
    
    var body: some View {
        ZStack {
            // Background
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
                            
                            Text("Create New Set")
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
                
                // Content
                ScrollView {
                    VStack(spacing: 40) {
                        // App logo and intro
                        VStack(spacing: 20) {
                            Image(.quzifyLogo)
                                .resizable()
                                .frame(width: 100, height: 100)
                                .padding(.top, 30)
                            
                            Text("How would you like to create your set?")
                                .font(.custom("Kiwi Maru Regular", size: 22))
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        
                        // Option cards
                        VStack(spacing: 25) {
                            // Generate option
                            NavigationLink(destination: GenerateSetView().environmentObject(dataManager)) {
                                CreationOptionCard(
                                    title: "Generate",
                                    icon: "sparkles",
                                    description: "Let AI generate flashcards based on your topic",
                                    color: Color(hex: "#6082C9"),
                                    isSelected: selectedOption == .generate
                                )
                                .scaleEffect(animateOptions ? 1.0 : 0.9)
                                .opacity(animateOptions ? 1.0 : 0.6)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Manual creation option
                            NavigationLink(destination: ManualCreateView().environmentObject(dataManager)) {
                                CreationOptionCard(
                                    title: "Create Manually",
                                    icon: "pencil",
                                    description: "Create your own flashcards from scratch",
                                    color: Color(hex: "#C97D60"),
                                    isSelected: selectedOption == .manual
                                )
                                .scaleEffect(animateOptions ? 1.0 : 0.9)
                                .opacity(animateOptions ? 1.0 : 0.6)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 50)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Animate the options appearing
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animateOptions = true
            }
        }
    }
}

struct CreationOptionCard: View {
    let title: String
    let icon: String
    let description: String
    let color: Color
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.custom("Kiwi Maru Regular", size: 18))
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.custom("Kiwi Maru Light", size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Arrow indicator
            Image(systemName: "chevron.right")
                .foregroundColor(color)
                .font(.system(size: 18))
                .padding(.trailing, 10)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 15)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: color.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? color : Color.clear, lineWidth: 2)
        )
    }
}

struct NewSetView_Previews: PreviewProvider {
    static var previews: some View {
        NewSetView()
            .environmentObject(DataManager())
    }
}
