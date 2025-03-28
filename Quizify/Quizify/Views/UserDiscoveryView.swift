//
//  UserDiscoveryView.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 3/28/25.
//

import SwiftUI
import FirebaseFirestore

struct UserProfilePreview: Identifiable {
    var id: String
    var username: String
    var displayName: String
    var email: String
    var setCount: Int
    var studyStreak: Int
}

class UserDiscoveryViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var users: [UserProfilePreview] = []
    @Published var isSearching = false
    @Published var errorMessage = ""
    
    func searchUsers() {
        guard !searchText.isEmpty else {
            users = []
            return
        }
        
        isSearching = true
        errorMessage = ""
        
        let db = Firestore.firestore()
        
        // Search by username (most likely what users will want to search by)
        db.collection("Users")
            .whereField("username", isGreaterThanOrEqualTo: searchText.lowercased())
            .whereField("username", isLessThanOrEqualTo: searchText.lowercased() + "\u{f8ff}")
            .limit(to: 20)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "Error searching users: \(error.localizedDescription)"
                    self.isSearching = false
                    return
                }
                
                var foundUsers: [UserProfilePreview] = []
                
                if let documents = snapshot?.documents, !documents.isEmpty {
                    for doc in documents {
                        let data = doc.data()
                        let userId = doc.documentID
                        let email = data["email"] as? String ?? "Unknown"
                        let username = data["username"] as? String ?? "Unknown"
                        let displayName = data["displayName"] as? String ?? username
                        let setCount = data["setCount"] as? Int ?? 0
                        let currentStreak = data["currentStreak"] as? Int ?? 0
                        
                        foundUsers.append(UserProfilePreview(
                            id: userId,
                            username: username,
                            displayName: displayName,
                            email: email,
                            setCount: setCount,
                            studyStreak: currentStreak
                        ))
                    }
                    
                    self.users = foundUsers
                    self.isSearching = false
                } else {
                    // If no users found by username, try searching by email
                    db.collection("Users")
                        .whereField("email", isGreaterThanOrEqualTo: self.searchText)
                        .whereField("email", isLessThanOrEqualTo: self.searchText + "\u{f8ff}")
                        .limit(to: 20)
                        .getDocuments { snapshot, error in
                            if let error = error {
                                self.errorMessage = "Error searching users: \(error.localizedDescription)"
                                self.isSearching = false
                                return
                            }
                            
                            var foundUsers: [UserProfilePreview] = []
                            
                            if let documents = snapshot?.documents, !documents.isEmpty {
                                for doc in documents {
                                    let data = doc.data()
                                    let userId = doc.documentID
                                    let email = data["email"] as? String ?? "Unknown"
                                    let username = data["username"] as? String ?? "Unknown"
                                    let displayName = data["displayName"] as? String ?? username
                                    let setCount = data["setCount"] as? Int ?? 0
                                    let currentStreak = data["currentStreak"] as? Int ?? 0
                                    
                                    foundUsers.append(UserProfilePreview(
                                        id: userId,
                                        username: username,
                                        displayName: displayName,
                                        email: email,
                                        setCount: setCount,
                                        studyStreak: currentStreak
                                    ))
                                }
                            }
                            
                            DispatchQueue.main.async {
                                self.users = foundUsers
                                self.isSearching = false
                            }
                        }
                }
            }
    }
    
    func loadTopUsers() {
        isSearching = true
        
        let db = Firestore.firestore()
        
        // Find users with highest streaks
        db.collection("Users")
            .order(by: "maxStreak", descending: true)
            .limit(to: 10)
            .getDocuments { snapshot, error in
                if let error = error {
                    self.errorMessage = "Error loading top users: \(error.localizedDescription)"
                    self.isSearching = false
                    return
                }
                
                var topUsers: [UserProfilePreview] = []
                
                if let documents = snapshot?.documents, !documents.isEmpty {
                    for doc in documents {
                        let data = doc.data()
                        let userId = doc.documentID
                        let email = data["email"] as? String ?? "Unknown"
                        let username = data["username"] as? String ?? "Unknown"
                        let displayName = data["displayName"] as? String ?? username
                        let setCount = data["setCount"] as? Int ?? 0
                        let currentStreak = data["currentStreak"] as? Int ?? 0
                        
                        topUsers.append(UserProfilePreview(
                            id: userId,
                            username: username,
                            displayName: displayName,
                            email: email,
                            setCount: setCount,
                            studyStreak: currentStreak
                        ))
                    }
                }
                
                DispatchQueue.main.async {
                    self.users = topUsers
                    self.isSearching = false
                }
            }
    }
}

struct UserDiscoveryView: View {
    @StateObject private var viewModel = UserDiscoveryViewModel()
    @Environment(\.dismiss) var dismiss
    
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
                            
                            Text("Find Users")
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
                
                // Search bar
                HStack {
                    TextField("Search by email", text: $viewModel.searchText)
                        .font(.custom("Kiwi Maru Regular", size: 16))
                        .padding(10)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.leading, 20)
                    
                    Button(action: {
                        viewModel.searchUsers()
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color(hex: "#C97D60"))
                            .cornerRadius(10)
                    }
                    .padding(.trailing, 20)
                    .disabled(viewModel.searchText.isEmpty)
                }
                .padding(.vertical, 15)
                
                if viewModel.isSearching {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    Text("Searching...")
                        .font(.custom("Kiwi Maru Light", size: 16))
                        .foregroundColor(.gray)
                    Spacer()
                } else if !viewModel.errorMessage.isEmpty {
                    Spacer()
                    Text(viewModel.errorMessage)
                        .font(.custom("Kiwi Maru Regular", size: 16))
                        .foregroundColor(.red)
                        .padding()
                    Spacer()
                } else if viewModel.users.isEmpty && viewModel.searchText.isEmpty {
                    // Show suggested users
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Top Users")
                            .font(.custom("Kiwi Maru Regular", size: 20))
                            .foregroundColor(.black)
                            .padding(.leading, 20)
                        
                        Button(action: {
                            viewModel.loadTopUsers()
                        }) {
                            HStack {
                                Text("Discover popular users")
                                    .font(.custom("Kiwi Maru Regular", size: 16))
                                    .foregroundColor(Color(hex: "#C97D60"))
                                
                                Spacer()
                                
                                Image(systemName: "person.3.fill")
                                    .foregroundColor(Color(hex: "#C97D60"))
                            }
                            .padding()
                            .background(Color(hex: "#C97D60").opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                } else if viewModel.users.isEmpty && !viewModel.searchText.isEmpty {
                    Spacer()
                    Text("No users found")
                        .font(.custom("Kiwi Maru Regular", size: 18))
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    // Show search results
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(viewModel.users) { user in
                                NavigationLink(destination: OtherUserProfileView(userId: user.id)) {
                                    UserRow(user: user)
                                }
                            }
                        }
                        .padding(.vertical, 15)
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct UserRow: View {
    let user: UserProfilePreview
    
    var body: some View {
        HStack {
            // Profile picture placeholder
            Circle()
                .fill(Color(hex: "#C97D60").opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(user.username.prefix(1)).uppercased())
                        .font(.custom("Kiwi Maru Regular", size: 20))
                        .foregroundColor(Color(hex: "#C97D60"))
                )
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(user.displayName)
                        .font(.custom("Kiwi Maru Regular", size: 16))
                        .foregroundColor(.black)
                    
                    Text("@\(user.username)")
                        .font(.custom("Kiwi Maru Light", size: 14))
                        .foregroundColor(.gray)
                }
                
                Text(user.email)
                    .font(.custom("Kiwi Maru Light", size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // User stats
            HStack(spacing: 15) {
                VStack(spacing: 2) {
                    Text("\(user.setCount)")
                        .font(.custom("Kiwi Maru Medium", size: 16))
                        .foregroundColor(Color(hex: "#C97D60"))
                    
                    Text("sets")
                        .font(.custom("Kiwi Maru Light", size: 12))
                        .foregroundColor(.gray)
                }
                
                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(Color(hex: "#C97D60"))
                            .font(.system(size: 12))
                        
                        Text("\(user.studyStreak)")
                            .font(.custom("Kiwi Maru Medium", size: 16))
                            .foregroundColor(Color(hex: "#C97D60"))
                    }
                    
                    Text("streak")
                        .font(.custom("Kiwi Maru Light", size: 12))
                        .foregroundColor(.gray)
                }
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(Color(hex: "#C97D60"))
                .font(.system(size: 14))
                .padding(.leading, 5)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    UserDiscoveryView()
}
