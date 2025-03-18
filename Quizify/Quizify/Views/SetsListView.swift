//
//  SetsListView.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 3/18/25.
//

import SwiftUI

struct SetsListView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showPopup = false
    
    var body: some View {
        NavigationView{
            List(dataManager.cards, id: \.id) { card in
                Text(card.term)
            }
            .navigationTitle("Cards")
            .navigationBarItems(trailing: Button(action: {
                showPopup.toggle()
            }, label: {
                Image(systemName: "plus")
            }))
            .sheet(isPresented: $showPopup){
               TestAddView()
            }
        }
    }
}

#Preview {
    SetsListView()
        .environmentObject(DataManager())
}
