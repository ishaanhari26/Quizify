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
                VStack(alignment: .center, spacing: 80){
                    VStack(spacing: 10){
                        Image(.cardIcons)
                            .resizable()
                            .frame(width: 75, height: 72)

                        Text("Create new set")
                            .font(.custom("Kiwi Maru Medium", size: 25))
                            .foregroundColor(Color(.gray))
                    }
                    VStack(spacing: 26){
                        Button(action: {
                            
                        }){
                            Text("Scan")
                                .foregroundStyle(.white)
                                .font(.custom("Kiwi Maru Light", size: 22))
                                .frame(width: 300, height: 50)
                                .background(Color(hex: "#C97D60"))
                                .cornerRadius(15)
                        }
                        
                        Button(action: {
                            
                        }){
                            Text("Generate")
                                .foregroundStyle(.white)
                                .font(.custom("Kiwi Maru Light", size: 22))
                                .frame(width: 300, height: 50)
                                .background(Color(hex: "#C97D60"))
                                .cornerRadius(15)
                        }
                        
                        Button(action: {
                            
                        }){
                            Text("Upload file")
                                .foregroundStyle(.white)
                                .font(.custom("Kiwi Maru Light", size: 22))
                                .frame(width: 300, height: 50)
                                .background(Color(hex: "#C97D60"))
                                .cornerRadius(15)
                        }
                        
                        Button(action: {
                            
                        }){
                            Text("Create manually")
                                .foregroundStyle(.white)
                                .font(.custom("Kiwi Maru Light", size: 22))
                                .frame(width: 300, height: 50)
                                .background(Color(hex: "#C97D60"))
                                .cornerRadius(15)
                        }
                        
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 70)
        }
        Text("")
    }
}

#Preview {
    NewSetView()
}
