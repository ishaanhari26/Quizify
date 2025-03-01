//
//  HomeView.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 11/14/24.
//

import SwiftUI

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
                NavigationLink(destination: Text("Profile View")) {
                    SideMenuItem(title: "Profile", icon: "person.fill") {}
                }
                
                NavigationLink(destination: Text("My Sets View")) {
                    SideMenuItem(title: "My Sets", icon: "folder.fill") {}
                }
                
                NavigationLink(destination: Text("Settings View")) {
                    SideMenuItem(title: "Settings", icon: "gear") {}
                }
                
                NavigationLink(destination: Text("Help View")) {
                    SideMenuItem(title: "Help", icon: "questionmark.circle.fill") {}
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
                        goToGreet = true  // This will dismiss the HomeView and show the GreetingView
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
                            
                            Text("Sets")
                                .font(.custom("Kiwi Maru Light", size: 25))
                                .foregroundColor(Color(.gray))
                                .padding(.leading, 30)
                                .padding(.bottom, 10)
                            
                            
                            //Make half to show this is a scroll element
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
                                .padding(.horizontal, 5)
                            }
                            .scrollIndicators(.hidden)
                            
                            Spacer().frame(height: 30)
                            
                            VStack() {
                                Text("Achievements")
                                    .font(.custom("Kiwi Maru Light", size: 25))
                                    .foregroundColor(Color(.gray))
                                    .padding(.leading, 30)
                            }
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
                        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 5)
                        .padding(.horizontal)
                    }
                    .frame(height: 100)
                }
            }
            .offset(x: showMenu ? 270 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea()
        .preferredColorScheme(.light)
    }
}

#Preview {
    HomeView(goToGreet: .constant(false))
}
