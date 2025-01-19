//
//  HomeView.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 11/14/24.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Scrolling content
                ScrollView(.vertical) {
                    VStack(alignment: .leading) {
                        // Spacer to push content below header
                        Spacer()
                            .frame(height: 150)
                        
                        Text("Sets")
                            .font(.custom("Kiwi Maru Light", size: 25))
                            .foregroundColor(Color(.gray))
                            .padding(.leading, 30)
                        
                        ScrollView(.horizontal) {
                            HStack(spacing: 20) {
                                ForEach(0..<10) {
                                    Text("Item \($0)")
                                        .foregroundStyle(.white)
                                        .font(.largeTitle)
                                        .frame(width: 190, height: 145)
                                        .background(Color(hex: "#C97D60"))
                                        .cornerRadius(15)
                                }
                            }
                        }
                        .padding(.leading, 10)
                        .scrollIndicators(.hidden)
                        
                        Spacer().frame(height: 30)
                        
                        VStack() {
                            Text("Achievements")
                                .font(.custom("Kiwi Maru Light", size: 25))
                                .foregroundColor(Color(.gray))
                        }
                    }
                }
                
                // Floating header with blur effect and enhanced shadow
                HStack {
                    Image(systemName: "text.justify")
                        .foregroundColor(.black)
                        .font(.system(size: 20))
                    
                    Spacer().frame(width: 50)
                    
                
                    HStack(spacing: -10) {
                        Text("Quizify")
                            .font(.custom("Kiwi Maru Light", size: 30))
                            .foregroundColor(Color(.black))
                        
                        Image(.quzifyLogo)
                            .resizable()
                            .frame(width: 70, height: 70)
                    }
                    
                    Spacer().frame(width: 50)
                    
                    NavigationLink(destination: NewSetView()) {
                        Image(systemName: "plus")
                            .foregroundColor(.black)
                            .font(.system(size: 25))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .background(
                    ZStack {
                        Color.white.opacity(0.7)
                        
                        // Blur effect
                        Rectangle()
                            .fill(.white)
                            .opacity(0.7)
                            .background(.ultraThinMaterial)
                            .blur(radius: 3)
                    }
                        .cornerRadius(30)
                )
                .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 5) // Enhanced shadow
                .padding(.horizontal)
                .padding(.top, 60)
                
                
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea()
            .preferredColorScheme(.light)
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    HomeView()
}
