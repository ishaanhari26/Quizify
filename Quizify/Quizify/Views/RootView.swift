//
//  RootView.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 2/21/25.
//

import SwiftUI

struct RootView: View {
    
    @State private var showHomeView: Bool = false
    
    var body: some View {
        ZStack {
            NavigationStack {
                HomeView(showHomeView: $showHomeView)
            }
        }
        .onAppear{
            let authUser = try? AuthManager.shared.getAuthenticatedUser()
            self.showHomeView = authUser == nil ? true : false
        }
        .fullScreenCover(isPresented: $showHomeView) {
            NavigationStack {
                GreetingView()
            }
        }
    }
}

#Preview {
    RootView()
}
