//
//  PublicSetsManagerView.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 3/28/25.
//

//
//  PublicSetsManagerView.swift
//  Quizify
//
//  Created on 3/28/25.
//

import SwiftUI
import FirebaseFirestore

class PublicSetsViewModel: ObservableObject {
    @Published var sets: [Set] = []
    @Published var isLoading = true
    
    func loadUserSets() {
        guard let userID = AuthManager.shared.getUserID() else {
            self.isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        let ref = db.collection("Sets")
        
        // Query sets created by the current user
        ref.whereField("userID", isEqualTo: userID).getDocuments { snapshot, error in
            guard error == nil else {
                print(error!.localizedDescription)
                self.isLoading = false
                return
            }
            
            if let snapshot = snapshot {
                // Create a dispatch group to wait for all sets to be processed
                let group = DispatchGroup()
                
                var tempSets: [Set] = []
                
                for document in snapshot.documents {
                    let data = document.data()
                    
                    let id = document.documentID
                    let title = data["title"] as? String ?? ""
                    let description = data["description"] as? String
                    let cardCount = data["cardCount"] as? Int ?? 0
                    let timestamp = data["createdAt"] as? Timestamp ?? Timestamp(date: Date())
                    let isPublic = data["isPublic"] as? Bool ?? false
                    
                    // Create a set with visibility information
                    var newSet = Set(
                        id: id,
                        title: title,
                        description: description,
                        cardCount: cardCount,
                        createdAt: timestamp.dateValue()
                    )
                    
                    // Store public status in totalStudyTime temporarily
                    // This is a hack - in a real app you would extend the Set model
                    newSet.totalStudyTime = isPublic ? 1 : 0
                    
                    tempSets.append(newSet)
                }
                
                // Sort sets and update UI
                DispatchQueue.main.async {
                    // Sort by most recently created
                    self.sets = tempSets.sorted(by: { $0.createdAt > $1.createdAt })
                    self.isLoading = false
                }
            } else {
                self.isLoading = false
            }
        }
    }
    
    func toggleSetVisibility(setID: String, makePublic: Bool) {
        if let index = sets.firstIndex(where: { $0.id == setID }) {
            // Update in local array temporarily
            sets[index].totalStudyTime = makePublic ? 1 : 0
        }
        
        // Update in Firestore
        let db = Firestore.firestore()
        let setRef = db.collection("Sets").document(setID)
        
        setRef.updateData([
            "isPublic": makePublic
        ]) { error in
            if let error = error {
                print("Error updating visibility: \(error.localizedDescription)")
                // Reload data to get correct state
                self.loadUserSets()
            }
        }
    }
}

struct PublicSetsManagerView: View {
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var viewModel = PublicSetsViewModel()
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
                            
                            Text("Manage Public Sets")
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
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    Text("Loading sets...")
                        .font(.custom("Kiwi Maru Light", size: 16))
                        .foregroundColor(.gray)
                        .padding()
                    Spacer()
                } else if viewModel.sets.isEmpty {
                    Spacer()
                    Text("You don't have any sets yet")
                        .font(.custom("Kiwi Maru Regular", size: 18))
                        .foregroundColor(.gray)
                        .padding()
                    
                    NavigationLink(destination: NewSetView()) {
                        Text("Create a Set")
                            .font(.custom("Kiwi Maru Regular", size: 16))
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(Color(hex: "#C97D60"))
                            .cornerRadius(20)
                    }
                    .padding(.top, 20)
                    Spacer()
                } else {
                    // Information text
                    Text("Toggle sets to make them public or private. Public sets are visible to all Quizify users.")
                        .font(.custom("Kiwi Maru Light", size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(viewModel.sets) { set in
                                SetVisibilityRow(
                                    set: set,
                                    isPublic: set.totalStudyTime ?? 0 > 0,
                                    onToggle: { isPublic in
                                        viewModel.toggleSetVisibility(setID: set.id, makePublic: isPublic)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.loadUserSets()
        }
    }
}

struct SetVisibilityRow: View {
    let set: Set
    let isPublic: Bool
    let onToggle: (Bool) -> Void
    @State private var localIsPublic: Bool
    
    init(set: Set, isPublic: Bool, onToggle: @escaping (Bool) -> Void) {
        self.set = set
        self.isPublic = isPublic
        self.onToggle = onToggle
        self._localIsPublic = State(initialValue: isPublic)
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // Card count indicator
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(isPublic ? Color(hex: "#6082C9") : Color(hex: "#edae95"))
                    .frame(width: 60, height: 60)
                
                VStack(spacing: 2) {
                    Text("\(set.cardCount)")
                        .font(.custom("Kiwi Maru Medium", size: 18))
                        .foregroundColor(.white)
                    
                    Text("cards")
                        .font(.custom("Kiwi Maru Light", size: 12))
                        .foregroundColor(.white)
                }
            }
            
            // Set details
            VStack(alignment: .leading, spacing: 5) {
                Text(set.title)
                    .font(.custom("Kiwi Maru Regular", size: 16))
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                if let description = set.description, !description.isEmpty {
                    Text(description)
                        .font(.custom("Kiwi Maru Light", size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Created date
                Text(formattedDate(set.createdAt))
                    .font(.custom("Kiwi Maru Light", size: 12))
                    .foregroundColor(Color(hex: "#C97D60"))
            }
            
            Spacer()
            
            // Visibility toggle
            Toggle("", isOn: $localIsPublic)
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#6082C9")))
                .labelsHidden()
                .onChange(of: localIsPublic) { newValue in
                    onToggle(newValue)
                }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 15)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // Format the date for display
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    PublicSetsManagerView()
        .environmentObject(DataManager())
}
