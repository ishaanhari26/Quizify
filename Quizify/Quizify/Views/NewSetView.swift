//
//  NewSetView.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 11/17/24.
//

import SwiftUI

struct NewSetView: View {
    var body: some View {
        NavigationView {
            ZStack {
                VStack(alignment: .center, spacing: 70){
                    VStack(spacing: 10){
                        Image(.cardIcons)
                            .resizable()
                            .frame(width: 75, height: 72)

                        Text("Create new set")
                            .font(.custom("Kiwi Maru Light", size: 25))
                            .foregroundColor(Color(.gray))
                    }
                    VStack(spacing: 26){
                        Text("Scan")
                            .foregroundStyle(.white)
                            .font(.largeTitle)
                            .frame(width: 300, height: 50)
                            .background(Color(hex: "#C97D60"))
                            .cornerRadius(15)
                        
                        Text("Generate")
                            .foregroundStyle(.white)
                            .font(.largeTitle)
                            .frame(width: 300, height: 50)
                            .background(Color(hex: "#C97D60"))
                            .cornerRadius(15)
                        
                        Text("Upload file")
                            .foregroundStyle(.white)
                            .font(.largeTitle)
                            .frame(width: 300, height: 50)
                            .background(Color(hex: "#C97D60"))
                            .cornerRadius(15)
                        
                        Text("Create manually")
                            .foregroundStyle(.white)
                            .font(.largeTitle)
                            .frame(width: 300, height: 50)
                            .background(Color(hex: "#C97D60"))
                            .cornerRadius(15)
                        
                        
                    }
                }
            }
        }
        Text("")
    }
}

#Preview {
    NewSetView()
}
