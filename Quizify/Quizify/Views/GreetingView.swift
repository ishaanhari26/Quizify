//
//  GreetingView.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 11/12/24.
//

import SwiftUI

//Fade Settings
struct TextFader: View {
    let texts: [String]
    @State private var currentIndex = 0
    @State private var opacity = 1.0
    
    // Customizable timing values
    let fadeOutDuration: Double = 0.5
    let fadeInDuration: Double = 0.5
    let displayDuration: Double = 2.5
    
    var body: some View {
        Text(texts[currentIndex])
            .opacity(opacity)
            .onAppear {
                startFadeSequence()
            }
    }
    
    private func startFadeSequence() {
        // Create a continuous animation sequence
        Timer.scheduledTimer(withTimeInterval: displayDuration + fadeOutDuration + fadeInDuration, repeats: true) { _ in
            fadeToNextText()
        }
    }
    
    private func fadeToNextText() {
        // Fade out current text
        withAnimation(.easeOut(duration: fadeOutDuration)) {
            opacity = 0
        }
        
        // After fade out, change text and fade in
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeOutDuration) {
            currentIndex = (currentIndex + 1) % texts.count
            
            withAnimation(.easeIn(duration: fadeInDuration)) {
                opacity = 1
            }
        }
    }
}

struct GreetingView: View {
    let textArray = [
        "Wisdom is not a product of schooling but of the lifelong attempt to acquire it.\n — Albert Einstein",
        "Wisdom comes not from age, but from education and learning. \n― Anton Chekhov",
        "Learning never exhausts the mind.\n ― Leonardo da Vinci",
        "For the best return on your money, pour your purse into your head. \n― Benjamin Franklin"
    ]
    
    @State private var showLoginSheet = false
    @State private var showSignupSheet = false
    @State private var navigateToHomeView = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Clean orange background
                    Color(hex: "#C97D60")
                        .ignoresSafeArea()
                    
                    // Subtle floating background elements
                    SubtleFloatingElements()
                    
                    VStack(spacing: 0) {
                        // Header section with logo
                        VStack(spacing: 20) {
                            Spacer().frame(height: 60)
                            
                            // Modern logo section
                            HStack(alignment: .center, spacing: 12) {
                                Image(.quizifyLogoWhite)
                                    .resizable()
                                    .frame(width: 80, height: 80)
                                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                
                                Text("Quizify")
                                    .font(.custom("Kiwi Maru Medium", size: 48))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer()
                        
                        // Quote section with modern card design
                        VStack(spacing: 30) {
                            VStack(spacing: 15) {
                                Image(systemName: "quote.bubble.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                TextFader(texts: textArray)
                                    .font(.custom("Kiwi Maru Light", size: 20))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                                    .frame(minHeight: 120)
                            }
                            .padding(.horizontal, 30)
                            .padding(.vertical, 30)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.white.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 8)
                        }
                        .padding(.horizontal, 25)
                        
                        Spacer()
                        
                        // Modern button section
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                // Login button
                                Button(action: {
                                    showLoginSheet = true
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 18))
                                        Text("Login")
                                            .font(.custom("Kiwi Maru Medium", size: 18))
                                    }
                                    .foregroundColor(Color(hex: "#C97D60"))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.white)
                                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                                    )
                                }
                                .pressAnimation()
                                .sheet(isPresented: $showLoginSheet) {
                                    LoginView(goToHome: $navigateToHomeView)
                                        .presentationDetents([.height(745)])
                                        .presentationBackgroundInteraction(.enabled)
                                        .presentationCornerRadius(40)
                                }
                                
                                // Sign Up button
                                Button(action: {
                                    showSignupSheet = true
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "person.badge.plus.fill")
                                            .font(.system(size: 18))
                                        Text("Sign Up")
                                            .font(.custom("Kiwi Maru Medium", size: 18))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.clear)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(.white, lineWidth: 2)
                                            )
                                    )
                                }
                                .pressAnimation()
                                .sheet(isPresented: $showSignupSheet) {
                                    SignupView(goToHome: $navigateToHomeView)
                                        .presentationDetents([.height(745)])
                                        .presentationBackgroundInteraction(.enabled)
                                        .presentationCornerRadius(40)
                                }
                            }
                            .padding(.horizontal, 25)
                            

                        }
                        .padding(.bottom, 50)
                    }
                }
            }
            .preferredColorScheme(.light)
            .navigationDestination(isPresented: $navigateToHomeView) {
                HomeView(goToGreet: $navigateToHomeView)
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
}

// Subtle floating background elements for minimal visual depth
struct SubtleFloatingElements: View {
    @State private var animate1 = false
    @State private var animate2 = false
    
    var body: some View {
        ZStack {
            // Very subtle floating circles
            Circle()
                .fill(.white.opacity(0.02))
                .frame(width: 180, height: 180)
                .offset(x: animate1 ? 15 : -15, y: animate1 ? -20 : 20)
                .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animate1)
                .position(x: 80, y: 200)
            
            Circle()
                .fill(.white.opacity(0.015))
                .frame(width: 140, height: 140)
                .offset(x: animate2 ? -20 : 20, y: animate2 ? 15 : -15)
                .animation(.easeInOut(duration: 10).repeatForever(autoreverses: true), value: animate2)
                .position(x: UIScreen.main.bounds.width - 60, y: UIScreen.main.bounds.height - 250)
        }
        .onAppear {
            animate1 = true
            animate2 = true
        }
    }
}

// Button press animation extension
extension View {
    func pressAnimation() -> some View {
        self.scaleEffect(1.0)
            .animation(.easeInOut(duration: 0.1), value: UUID())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.1)) {
                    // Animation handled by the button action
                }
            }
    }
}



#Preview {
    GreetingView()
}
