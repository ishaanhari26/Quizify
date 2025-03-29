//
//  AuthManager.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 2/21/25.
//

import Foundation
import FirebaseAuth

import FirebaseCore
import FirebaseFirestore
import GoogleSignIn


struct AuthDataResultModel {
    let uid: String
    let email: String?
    let photoURL: String?
    
    init(user: User){
        self.uid = user.uid
        self.email = user.email
        self.photoURL = user.photoURL?.absoluteString
    }
}

final class AuthManager {
    
    static let shared = AuthManager()
    private init() { }
    
    func getAuthenticatedUser () throws -> AuthDataResultModel{
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badServerResponse)
        }
        
        return AuthDataResultModel(user: user)
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
}


// MARK: - Create and Login User
extension AuthManager {
    func createUser(email: String, password: String) async throws -> AuthDataResultModel{
        let authDataResult = try await Auth.auth().createUser(withEmail: email, password: password)
        return AuthDataResultModel(user: authDataResult.user)
    }
    
    func loginUser(email: String, password: String) async throws -> AuthDataResultModel{
        let authDataResult = try await Auth.auth().signIn(withEmail: email, password: password)
        return AuthDataResultModel(user: authDataResult.user)
    }
}


// MARK: - Sign in With Google Extension
extension AuthManager {
    @discardableResult
    func signInWithGoogle(tokens: GoogleSignInResultModel) async throws -> AuthDataResultModel {
        let credential = GoogleAuthProvider.credential(withIDToken: tokens.idToken, accessToken: tokens.accessToken)
        return try await signIn(credential: credential)
    }
    
    func signIn(credential: AuthCredential) async throws -> AuthDataResultModel {
        let authDataResult = try await Auth.auth().signIn(with: credential)
        return AuthDataResultModel(user: authDataResult.user)
    }
}


// MARK: - 2 Factor Auth Extension
extension AuthManager {
    
    enum TwoFactorError: Error {
        case phoneNumberRequired
        case invalidPhoneNumber
        case verificationFailed
        case userNotFound
        
        var localizedDescription: String {
            switch self {
            case .phoneNumberRequired:
                return "Phone number is required for two-factor authentication"
            case .invalidPhoneNumber:
                return "Please enter a valid phone number"
            case .verificationFailed:
                return "Failed to send verification code"
            case .userNotFound:
                return "User not authenticated. Please log in first"
            }
        }
    }
    
    // Sends verification code to user
    func startTwoFactorAuthentication(phoneNumber: String) async throws -> String {
        guard !phoneNumber.isEmpty else {
            throw TwoFactorError.phoneNumberRequired
        }
        
        let cleanedNumber = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanedNumber.count >= 10 else {
            throw TwoFactorError.invalidPhoneNumber
        }
        
        // checks if user is already there
        guard Auth.auth().currentUser != nil else {
            throw TwoFactorError.userNotFound
        }
        
        // stores verification ID to firebase
        var verificationIDResult = ""
        var errorDetails = ""
        
        let semaphore = DispatchSemaphore(value: 0)
        
        // Requests verification code
        PhoneAuthProvider.provider().verifyPhoneNumber(cleanedNumber, uiDelegate: nil) { verificationID, error in
            if let error = error {
                errorDetails = error.localizedDescription
                print("Error sending verification code: \(error.localizedDescription)")
                print("Detailed error: \(error)")
                semaphore.signal()
                return
            }
            
            if let verificationID = verificationID {
                verificationIDResult = verificationID
                print("Successfully sent verification code to \(cleanedNumber)")
            }
            
            semaphore.signal()
        }
        
        // Wait for the callback to complete
        _ = semaphore.wait(timeout: .now() + 30.0)
        
        if verificationIDResult.isEmpty {
            throw NSError(domain: "PhoneAuth", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to send verification code: \(errorDetails)"])
        }
        
        return verificationIDResult
    }
    
    // Checks if 2FA is enabled
    func isPhoneNumberVerified() -> Bool {
        guard let currentUser = Auth.auth().currentUser else {
            return false
        }
        
        // Check if user has a phone number
        return currentUser.phoneNumber != nil
    }
    
    // Get the verified phone number (masked for privacy)
    func getVerifiedPhoneNumber() -> String? {
        guard let currentUser = Auth.auth().currentUser,
              let phoneNumber = currentUser.phoneNumber else {
            return nil
        }
        
        // Mask the phone number for privacy
        let suffix = String(phoneNumber.suffix(4))
        return "••••••\(suffix)"
    }
    
    // Verify the received code
    func verifyCode(verificationID: String, verificationCode: String) async throws -> AuthDataResultModel {
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: verificationCode
        )
        
        // Link the credential to the current user
        if let currentUser = Auth.auth().currentUser {
            let result = try await currentUser.link(with: credential)
            return AuthDataResultModel(user: result.user)
        } else {
            // If there's no current user, sign in with the credential
            let authResult = try await Auth.auth().signIn(with: credential)
            return AuthDataResultModel(user: authResult.user)
        }
    }
    
    // Resend the verification code
    func resendVerificationCode(phoneNumber: String) async throws -> String {
        return try await startTwoFactorAuthentication(phoneNumber: phoneNumber)
    }
}

// Add to AuthManager.swift
extension AuthManager {
    func getUserID() -> String? {
        return Auth.auth().currentUser?.uid
    }
}

extension AuthManager {
    // Check if the current user has a completed profile
    func userHasCompletedProfile() async -> Bool {
        guard let userID = getUserID() else {
            return false
        }
        
        let db = Firestore.firestore()
        
        do {
            let document = try await db.collection("Users").document(userID).getDocument()
            
            if let data = document.data(),
               let username = data["username"] as? String,
               !username.isEmpty,
               let displayName = data["displayName"] as? String,
               !displayName.isEmpty {
                
                return true
            }
            return false
        } catch {
            print("Error checking user profile: \(error.localizedDescription)")
            return false
        }
    }
}

