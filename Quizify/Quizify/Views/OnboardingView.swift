//
//  OnboardingView.swift
//  Quizify
//
//  Created on 3/28/25.
//

import SwiftUI
import PhotosUI
import FirebaseFirestore
import FirebaseAuth

struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager
    @Binding var goToHome: Bool
    
    // User data
    @State private var displayName: String = ""
    @State private var username: String = ""
    @State private var selectedClasses: [String] = []
    @State private var profileImage: UIImage? = nil
    @State private var selectedItem: PhotosPickerItem? = nil
    
    // UI state
    @State private var currentStep: Int = 1
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @Binding var dismissParent: Bool
    
    // In your init method:
    init(goToHome: Binding<Bool>, dismissParent: Binding<Bool> = .constant(false)) {
        self._goToHome = goToHome
        self._dismissParent = dismissParent
    }
    
   
    

    // Available AP classes
    let apClasses = [
        "AP English Literature",
        "AP English Language",
        "AP Calculus AB",
        "AP Calculus BC",
        "AP Statistics",
        "AP Computer Science A",
        "AP Computer Science Principles",
        "AP Biology",
        "AP Chemistry",
        "AP Physics 1",
        "AP Physics 2",
        "AP Physics C",
        "AP Environmental Science",
        "AP U.S. History",
        "AP World History",
        "AP European History",
        "AP Government",
        "AP Economics",
        "AP Psychology",
        "AP Spanish",
        "AP French",
        "AP Chinese",
        "AP Art History",
        "AP Studio Art"
    ]
    
    
    var body: some View {
        ZStack {
            // Background
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                ZStack {
                    Color(hex: "#C97D60").ignoresSafeArea(edges: .top)
                    
                    VStack {
                        // Progress bar
                        HStack(spacing: 5) {
                            ForEach(1...3, id: \.self) { step in
                                Capsule()
                                    .fill(step <= currentStep ? .white : .white.opacity(0.3))
                                    .frame(height: 5)
                            }
                        }
                        .padding(.horizontal, 50)
                        .padding(.top, 25)
                        
                        Text(headerTitle)
                            .font(.custom("Kiwi Maru Medium", size: 25))
                            .foregroundColor(.white)
                            .padding(.top, 10)
                            .padding(.bottom, 15)
                    }
                }
                .frame(height: 85)
                
                // Content based on current step
                ScrollView {
                    VStack(spacing: 30) {
                        switch currentStep {
                        case 1:
                            profileSetupView
                        case 2:
                            usernameSetupView
                        case 3:
                            classesSetupView
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.top, 30)
                    .padding(.bottom, 100)
                }
                
                // Navigation buttons
                bottomButtonsView
            }
            
            // Loading overlay
            if isLoading {
                loadingOverlay
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert(errorMessage, isPresented: $showError) {
            Button("OK", role: .cancel) { }
        }
    }
    
    // MARK: - Component Views
    
    private var profileSetupView: some View {
        VStack(spacing: 25) {
            Text("Let's set up your profile")
                .font(.custom("Kiwi Maru Regular", size: 20))
                .foregroundColor(.black)
            
            Text("Add a display name and profile picture")
                .font(.custom("Kiwi Maru Light", size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            // Profile picture selector
            VStack(spacing: 15) {
                if let profileImage = profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(hex: "#C97D60"), lineWidth: 3))
                } else {
                    Circle()
                        .fill(Color(hex: "#C97D60").opacity(0.2))
                        .frame(width: 150, height: 150)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Color(hex: "#C97D60"))
                        )
                        .overlay(Circle().stroke(Color(hex: "#C97D60"), lineWidth: 3))
                }
                
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack {
                        Image(systemName: "photo")
                            .font(.system(size: 16))
                        Text("Select Profile Picture")
                            .font(.custom("Kiwi Maru Regular", size: 16))
                    }
                    .foregroundColor(Color(hex: "#C97D60"))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(hex: "#C97D60").opacity(0.1))
                    .cornerRadius(15)
                }
                .onChange(of: selectedItem) { _ in
                    Task {
                        if let data = try? await selectedItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            profileImage = uiImage
                        }
                    }
                }
            }
            .padding(.vertical, 20)
            
            // Display name field
            VStack(alignment: .leading) {
                Text("Display Name")
                    .font(.custom("Kiwi Maru Regular", size: 16))
                    .foregroundColor(.black)
                    .padding(.leading, 10)
                
                TextField("Enter your name", text: $displayName)
                    .font(.custom("Kiwi Maru Regular", size: 18))
                    .frame(height: 52)
                    .padding(.horizontal)
                    .background(Color(hex: "#CECECE").opacity(0.2))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(hex: "#C97D60"), lineWidth: 3)
                    )
            }
            .padding(.horizontal, 30)
        }
        .padding(.horizontal)
    }
    
    private var usernameSetupView: some View {
        VStack(spacing: 25) {
            Text("Choose your username")
                .font(.custom("Kiwi Maru Regular", size: 20))
                .foregroundColor(.black)
            
            Text("Your username is unique and will be used to identify you.")
                .font(.custom("Kiwi Maru Light", size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            // Username field
            VStack(alignment: .leading) {
                Text("Username")
                    .font(.custom("Kiwi Maru Regular", size: 16))
                    .foregroundColor(.black)
                    .padding(.leading, 10)
                
                TextField("Enter username", text: $username)
                    .font(.custom("Kiwi Maru Regular", size: 18))
                    .frame(height: 52)
                    .padding(.horizontal)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .background(Color(hex: "#CECECE").opacity(0.2))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(hex: "#C97D60"), lineWidth: 3)
                    )
                
                // Username guidelines
                Text("Username can only contain letters, numbers, and underscores.")
                    .font(.custom("Kiwi Maru Light", size: 14))
                    .foregroundColor(.gray)
                    .padding(.leading, 10)
                    .padding(.top, 5)
            }
            .padding(.horizontal, 30)
            
            // Username preview
            VStack(spacing: 10) {
                Text("Preview:")
                    .font(.custom("Kiwi Maru Light", size: 14))
                    .foregroundColor(.gray)
                
                HStack {
                    Circle()
                        .fill(Color(hex: "#C97D60").opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Group {
                                if profileImage != nil {
                                    Image(uiImage: profileImage!)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                } else {
                                    Text(usernameInitial)
                                        .font(.custom("Kiwi Maru Regular", size: 18))
                                        .foregroundColor(Color(hex: "#C97D60"))
                                }
                            }
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(displayName.isEmpty ? "Your Name" : displayName)
                            .font(.custom("Kiwi Maru Regular", size: 16))
                            .foregroundColor(.black)
                        
                        Text("@\(username.isEmpty ? "username" : username)")
                            .font(.custom("Kiwi Maru Light", size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(hex: "#EFEFEF").opacity(0.5))
                .cornerRadius(15)
                .padding(.horizontal, 30)
            }
            .padding(.top, 20)
        }
        .padding(.horizontal)
    }
    
    private var classesSetupView: some View {
        VStack(spacing: 25) {
            Text("What classes are you taking?")
                .font(.custom("Kiwi Maru Regular", size: 20))
                .foregroundColor(.black)
            
            Text("Select the AP classes you're currently studying to find relevant sets.")
                .font(.custom("Kiwi Maru Light", size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            // AP Classes selection
            VStack(alignment: .leading, spacing: 5) {
                Text("AP Classes")
                    .font(.custom("Kiwi Maru Regular", size: 16))
                    .foregroundColor(.black)
                    .padding(.leading, 10)
                
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(apClasses, id: \.self) { className in
                            Button(action: {
                                toggleClass(className)
                            }) {
                                HStack {
                                    Text(className)
                                        .font(.custom("Kiwi Maru Regular", size: 16))
                                        .foregroundColor(.black)
                                    
                                    Spacer()
                                    
                                    if selectedClasses.contains(className) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color(hex: "#C97D60"))
                                            .font(.system(size: 20))
                                    } else {
                                        Circle()
                                            .stroke(Color.gray, lineWidth: 1)
                                            .frame(width: 20, height: 20)
                                    }
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 15)
                                .background(
                                    selectedClasses.contains(className) ?
                                    Color(hex: "#C97D60").opacity(0.1) : Color.white
                                )
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.vertical, 10)
                }
                .frame(height: 350)
                .padding(.horizontal, 10)
                .background(Color(hex: "#EFEFEF").opacity(0.5))
                .cornerRadius(15)
            }
            .padding(.horizontal, 30)
            
            Text("Selected: \(selectedClasses.count)/\(apClasses.count)")
                .font(.custom("Kiwi Maru Light", size: 14))
                .foregroundColor(Color(hex: "#C97D60"))
        }
        .padding(.horizontal)
    }
    
    private var bottomButtonsView: some View {
        HStack(spacing: 20) {
            // Back button (not shown on first step)
            if currentStep > 1 {
                Button(action: {
                    withAnimation {
                        currentStep -= 1
                    }
                }) {
                    Text("Back")
                        .font(.custom("Kiwi Maru Regular", size: 18))
                        .frame(width: 150, height: 43)
                        .background(Color(hex: "#CECECE").opacity(0.5))
                        .cornerRadius(20)
                        .foregroundColor(.black)
                }
            } else {
                // Skip button on first step only
                Button(action: {
                    // Skip onboarding and go to home
                    goToHome = true
                    dismiss()
                }) {
                    Text("Skip")
                        .font(.custom("Kiwi Maru Regular", size: 18))
                        .frame(width: 150, height: 43)
                        .background(Color(hex: "#CECECE").opacity(0.5))
                        .cornerRadius(20)
                        .foregroundColor(.black)
                }
            }
            
            // Next/Finish button
            Button(action: {
                handleActionButton()
            }) {
                Text(currentStep < 3 ? "Next" : "Finish")
                    .font(.custom("Kiwi Maru Regular", size: 18))
                    .frame(width: 150, height: 43)
                    .background(Color(hex: "#C97D60"))
                    .cornerRadius(20)
                    .foregroundColor(.white)
            }
            .disabled(isButtonDisabled)
        }
        .padding(.vertical, 20)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -5)
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            VStack {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Saving your profile...")
                    .font(.custom("Kiwi Maru Light", size: 16))
                    .foregroundColor(.white)
                    .padding(.top, 10)
            }
            .padding(30)
            .background(Color(hex: "#C97D60").opacity(0.8))
            .cornerRadius(15)
        }
    }
    
    // MARK: - Computed Properties
    
    private var headerTitle: String {
        switch currentStep {
        case 1:
            return "About You"
        case 2:
            return "Choose Username"
        case 3:
            return "Your Classes"
        default:
            return "Setup Your Profile"
        }
    }
    
    private var usernameInitial: String {
        if !username.isEmpty {
            return String(username.prefix(1).uppercased())
        } else if !displayName.isEmpty {
            return String(displayName.prefix(1).uppercased())
        } else {
            return "?"
        }
    }
    
    private var isButtonDisabled: Bool {
        switch currentStep {
        case 1:
            return displayName.isEmpty
        case 2:
            return username.isEmpty || !isValidUsername(username)
        case 3:
            return false // Classes are optional
        default:
            return false
        }
    }
    
    // MARK: - Helper Functions
    
    private func toggleClass(_ className: String) {
        if selectedClasses.contains(className) {
            selectedClasses.removeAll(where: { $0 == className })
        } else {
            selectedClasses.append(className)
        }
    }
    
    private func isValidUsername(_ username: String) -> Bool {
        // Check if username contains only letters, numbers, and underscores
        let usernameRegex = "^[a-zA-Z0-9_]+$"
        let regexPredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        return regexPredicate.evaluate(with: username)
    }
    
    private func checkUsernameAvailability() async -> Bool {
        let db = Firestore.firestore()
        
        do {
            let snapshot = try await db.collection("Users")
                .whereField("username", isEqualTo: username.lowercased())
                .getDocuments()
            
            return snapshot.documents.isEmpty
        } catch {
            print("Error checking username: \(error.localizedDescription)")
            return false
        }
    }
    
    private func handleActionButton() {
        if currentStep < 3 {
            // Handle next step
            if currentStep == 2 {
                // Check username before proceeding
                Task {
                    isLoading = true
                    if await checkUsernameAvailability() {
                        isLoading = false
                        withAnimation {
                            currentStep += 1
                        }
                    } else {
                        isLoading = false
                        errorMessage = "This username is already taken"
                        showError = true
                    }
                }
            } else {
                withAnimation {
                    currentStep += 1
                }
            }
        } else {
            // Finish onboarding
            saveUserProfile()
        }
    }
    
    private func saveUserProfile() {
        isLoading = true
        
        // Get user ID
        guard let userID = AuthManager.shared.getUserID() else {
            errorMessage = "Unable to save profile. Please try again."
            showError = true
            isLoading = false
            return
        }
        
        // Save user profile data to Firestore
        let db = Firestore.firestore()
        let userRef = db.collection("Users").document(userID)
        
        var userData: [String: Any] = [
            "displayName": displayName,
            "username": username.lowercased(),
            "apClasses": selectedClasses,
            "setCount": 0,
            "currentStreak": 0,
            "maxStreak": 0,
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date())
        ]
        
        // Get email
        if let email = Auth.auth().currentUser?.email {
            userData["email"] = email
        }
        
        // Update user data
        userRef.setData(userData, merge: true) { error in
            if let error = error {
                print("Error updating user profile: \(error.localizedDescription)")
                self.errorMessage = "Failed to save profile: \(error.localizedDescription)"
                self.showError = true
                self.isLoading = false
            } else {
                // Temporarily skip profile image upload until FirebaseStorage is properly linked
                
                // Note: We would normally upload profile image here, but since FirebaseStorage
                // is not properly linked, we'll skip that step for now
                print("Profile saved successfully, but profile image upload skipped.")
                
                // Navigate to home screen
                self.goToHome = true
                self.dismissParent = true // This will trigger the parent view to dismiss
                self.dismiss()
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(goToHome: .constant(false))
            .environmentObject(DataManager())
    }
}
