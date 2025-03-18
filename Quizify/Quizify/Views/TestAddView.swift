//
//  TestAddView.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 3/18/25.
//

import SwiftUI

struct TestAddView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var newTerm = ""
    var body: some View {
        VStack {
            TextField("Term", text: $newTerm)
            
            Button{
                dataManager.addCard(term: newTerm)  
            } label : {
                Text("Save")
            }
            
        }
        .padding()
        
        
    }
}

#Preview {
    TestAddView()
}
