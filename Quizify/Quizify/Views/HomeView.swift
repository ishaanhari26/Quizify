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
    @State private var navigateToGreet = false
    @EnvironmentObject var dataManager: DataManager
    @State private var isLoading = true
    
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
                NavigationLink(destination: ProfileView()) {
                    HStack(spacing: 15) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "#C97D60"))
                        Text("Profile")
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
                
                NavigationLink(destination: Text("Settings View")) {
                    HStack(spacing: 15) {
                        Image(systemName: "gear")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "#C97D60"))
                        Text("Settings")
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
                            
                            VStack(alignment: .leading) {
                                Text("Achievements")
                                    .font(.custom("Kiwi Maru Light", size: 25))
                                    .foregroundColor(Color(.gray))
                                    .padding(.leading, 30)
                                
                                // Placeholder for achievements section
                                HStack {
                                    Spacer()
                                    Text("Coming soon!")
                                        .font(.custom("Kiwi Maru Light", size: 18))
                                        .foregroundColor(Color(.gray))
                                        .padding()
                                    Spacer()
                                }
                                .frame(height: 150)
                            }
                        }
                        .padding(.bottom, 50)
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

#Preview {
    HomeView(goToGreet: .constant(false))
        .environmentObject(DataManager())
}
