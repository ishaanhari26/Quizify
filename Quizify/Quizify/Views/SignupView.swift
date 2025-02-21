//
//  SignupView.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 11/14/24.
//

import SwiftUI



@MainActor
final class SignInEmailViewModel : ObservableObject {
    
    @Published var email =  " "
    @Published var password = " "
    
    init() {
        
    }
    
    func signIn() {
        guard !email.isEmpty, !password.isEmpty else {
            print("No email or password found")
            return
        }
        
        
        Task{
            do{
                let returnedUserData =  try await AuthManager.shared.createUser(email: email, password: password)
                print("Success")
                print(returnedUserData)
            }catch{
                print("Error: \(error)")
            }
        }
    }
    
    
   
}

struct SignupView: View {
    
    @StateObject private var viewModel = SignInEmailViewModel()
    
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @FocusState private var isNameFocused: Bool
    @FocusState private var isEmailFocused: Bool
    @FocusState private var isPasswordFocused: Bool
    @State private var shouldShowHome = false

    
    
    
    
    var body: some View {
        NavigationView{
            ZStack {
                
                
                
                Image("Flipped Background")
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
                    
                    Text("Sign Up")
                        .font(.custom("Kiwi Maru Regular", size: 30))
                    
                    VStack(spacing: 30){
                        
                        
//                        TextField("What is your Name?", text: $name)
//                            .font(.custom("Kiwi Maru Regular", size: 18))
//                            .frame(width: 297, height: 52)
//                            .padding(.horizontal)
//                            .background(Color(hex: "#CECECE").opacity(0.2))
//                            .cornerRadius(20)
//                            .overlay(
//                                RoundedRectangle(cornerRadius: 20)
//                                    .stroke(Color(hex: "#C97D60"),
//                                            lineWidth: isNameFocused ? 7 : 3)
//                                    .animation(.easeInOut(duration: 0.2), value: isNameFocused)
//                            )
//                            .focused($isNameFocused)
                        
                        
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
                        
                        TextField("Password", text: $viewModel.password)
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
                
                    
                    Button {
                        viewModel.signIn()
                    } label: {
                        Text("Create Account")
                            .font(.custom("Kiwi Maru Regular", size: 18))
                            .frame(width: 233, height: 43)
                            .background(Color(hex: "#C97D60"))
                            .cornerRadius(20)
                            .foregroundColor(.white)
                        
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 35)
                    
        
            
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
        
            .ignoresSafeArea(.keyboard)
            .fullScreenCover(isPresented: $shouldShowHome) {
                HomeView()
            }
            .frame(maxHeight: 650)
        }
        
    }
}






#Preview {
    SignupView()
}
