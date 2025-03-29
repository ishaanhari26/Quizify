//
//  SetVisibilityToggle.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 3/28/25.
//

import SwiftUI
import FirebaseFirestore

struct SetVisibilityToggle: View {
    let setID: String
    @State private var isPublic: Bool = false
    @State private var isLoading: Bool = true
    @State private var showConfirmation: Bool = false
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Toggle(isOn: $isPublic) {
                    HStack {
                        Image(systemName: isPublic ? "globe" : "lock")
                            .foregroundColor(isPublic ? Color(hex: "#6082C9") : .gray)
                        
                        Text(isPublic ? "Public" : "Private")
                            .font(.custom("Kiwi Maru Regular", size: 14))
                            .foregroundColor(isPublic ? Color(hex: "#6082C9") : .gray)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#6082C9")))
                .onChange(of: isPublic) { newValue in
                    // Confirm the change before updating
                    showConfirmation = true
                }
            }
        }
        .onAppear {
            loadVisibilitySetting()
        }
        .alert(isOn: $showConfirmation) {
            Alert(
                title: Text(isPublic ? "Make Set Public?" : "Make Set Private?"),
                message: Text(isPublic ?
                              "This set will be visible to all Quizify users. Continue?" :
                                "This set will only be visible to you. Continue?"),
                primaryButton: .default(Text("Confirm")) {
                    updateVisibility()
                },
                secondaryButton: .cancel {
                    // Revert the toggle if canceled
                    isPublic.toggle()
                }
            )
        }
    }
    
    private func loadVisibilitySetting() {
        isLoading = true
        
        let db = Firestore.firestore()
        db.collection("Sets").document(setID).getDocument { document, error in
            if let document = document, document.exists {
                self.isPublic = document.data()?["isPublic"] as? Bool ?? false
            }
            
            self.isLoading = false
        }
    }
    
    private func updateVisibility() {
        dataManager.updateSetVisibility(setID: setID, isPublic: isPublic) { success in
            if success {
                // If set is being made public, update achievements
                if isPublic {
                    dataManager.updateAchievementsForPublicSet()
                }
            } else {
                // Revert the toggle if update failed
                isPublic.toggle()
            }
        }
    }
}

// Helper extension for creating alerts with binding
extension View {
    func alert(isOn: Binding<Bool>, builder: () -> Alert) -> some View {
        return self.alert(isPresented: isOn, content: builder)
    }
}

#Preview {
    SetVisibilityToggle(setID: "preview-id")
        .environmentObject(DataManager())
        .padding()
        .previewLayout(.sizeThatFits)
}
