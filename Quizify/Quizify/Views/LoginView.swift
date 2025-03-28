//
//  LoginView.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 11/12/24.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

import GoogleSignIn
import GoogleSignInSwift


struct GoogleSignInResultModel {
    let idToken: String
    let accessToken: String
}

@MainActor
final class LoginEmailViewModel : ObservableObject {
    
    @Published var email = ""
    @Published var password = ""
    @Published var isAuthenticated = false
    @Published var errorMessage = ""
    
    init() {
        
    }
    
    func logIn() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password cannot be empty"
            return
        }
        
        do {
            let returnedUserData = try await AuthManager.shared.loginUser(email: email, password: password)
            isAuthenticated = true
            print("Logged in successfully")
            print(returnedUserData)
        } catch {
            isAuthenticated = false
            errorMessage = error.localizedDescription
            print("Error: \(error)")
        }
    }
    
    func googleAuth() async throws {
        guard let topVC = Utilities.shared.topViewController() else {
            throw URLError(.cannotFindHost)
        }
        
        let gidResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)
        
        guard let idToken = gidResult.user.idToken?.tokenString else {
            throw URLError(.badServerResponse)
        }
        
        let accessToken = gidResult.user.accessToken.tokenString
        
        let tokens = GoogleSignInResultModel(idToken: idToken, accessToken: accessToken)
        
        do{
            try await AuthManager.shared.signInWithGoogle(tokens: tokens)
            isAuthenticated = true
        } catch{
            isAuthenticated = false
            errorMessage = error.localizedDescription
            print("Error: \(error)")
        }
        
    }
}

struct LoginView: View {
    
    @StateObject private var viewModel = LoginEmailViewModel()
    
    @Environment(\.dismiss) var dismiss
    @FocusState private var isEmailFocused: Bool
    @FocusState private var isPasswordFocused: Bool
    @State private var navigateToHome = false
    @Binding var goToHome: Bool
    
    var body: some View {
        ZStack {
            Image("Background")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .offset(y: 35)
                .clipped()
            
            VStack(alignment: .center) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.up")
                        .foregroundColor(.gray)
                        .font(.system(size: 30))
                }
                .padding(.top, 80)
                
                // Title and Logo
                Spacer().frame(height: 40)
                
                Image(.quzifyLogo)
                    .resizable()
                    .frame(width: 125, height: 120)
                
                Spacer().frame(height: 20)
                
                Text("Login")
                    .font(.custom("Kiwi Maru Regular", size: 30))
                
                VStack(spacing: 30) {
                    TextField("Email", text: $viewModel.email)
                        .textInputAutocapitalization(.never)
                        .font(.custom("Kiwi Maru Regular", size: 18))
                        .frame(width: 297, height: 52)
                        .padding(.horizontal)
                        .background(Color(hex: "#CECECE").opacity(0.2))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(hex: "#C97D60"),
                                        lineWidth: isEmailFocused ? 7 : 3)
                                .animation(.easeInOut(duration: 0.2), value: isEmailFocused)
                        )
                        .focused($isEmailFocused)
                    
                    SecureField("Password", text: $viewModel.password)
                        .font(.custom("Kiwi Maru Regular", size: 18))
                        .frame(width: 297, height: 52)
                        .padding(.horizontal)
                        .background(Color(hex: "#CECECE").opacity(0.2))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(hex: "#C97D60"),
                                        lineWidth: isPasswordFocused ? 7 : 3)
                                .animation(.easeInOut(duration: 0.2), value: isPasswordFocused)
                        )
                        .focused($isPasswordFocused)
                }
                
                Button(action: {
                    Task {
                        await viewModel.logIn()
                        if viewModel.isAuthenticated {
                            // Set the binding to true and dismiss the sheet
                            goToHome = true
                            dismiss()
                        }
                    }
                }) {
                    Text("Login")
                        .font(.custom("Kiwi Maru Regular", size: 18))
                        .frame(width: 233, height: 43)
                        .background(Color(hex: "#C97D60"))
                        .cornerRadius(20)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 27)
                
                Spacer().frame(height: 25)
                
                HStack{
                    Rectangle()
                        .frame(width: 135, height: 1)
                        .foregroundColor(.black)
                    
                    Text("or")
                        .font(.custom("Kiwi Maru Regular", size: 20))
                    
                    Rectangle()
                        .frame(width: 135, height: 1)
                        .foregroundColor(.black)
                }
                
                Button(action: {
                    Task {
                        
                        try await viewModel.googleAuth()
                        
                        if viewModel.isAuthenticated {
                            goToHome = true
                            dismiss()
                        }
                    }
                }) {
                    Image(.googleSymbol)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .background(Color(hex: "#D9D9D9"))
                        .modifier(CircularImageModifier())

                }
                    
                
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .font(.custom("Kiwi Maru Regular", size: 14))
                        .padding(.top, 10)
                }
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .ignoresSafeArea(.keyboard)
        .frame(maxHeight: 650)
    }
}

// Add an initializer with a default value for goToHome
extension LoginView {
    init(goToHome: Binding<Bool> = .constant(false)) {
        self._goToHome = goToHome
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let rgbValue = UInt32(hex, radix: 16)
        let r = Double((rgbValue! & 0xFF0000) >> 16) / 255
        let g = Double((rgbValue! & 0x00FF00) >> 8) / 255
        let b = Double(rgbValue! & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}


struct CircularImageModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .clipShape(Circle())
            .contentShape(Circle())
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    LoginView()
}
