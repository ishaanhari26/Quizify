//
//  NewSetView.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 11/17/24.
//

import SwiftUI

struct NewSetView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(alignment: .center, spacing: 80){
                    VStack(spacing: 10){
                        Image(.cardIcons)
                            .resizable()
                            .frame(width: 95, height: 95)
                        
                        Text("Create new set")
                            .font(.custom("Kiwi Maru Medium", size: 25))
                            .foregroundColor(Color(.gray))
                    }
                    VStack(spacing: 50){
                        Button(action: {
                            // Scan functionality will be implemented later
                        }){
                            Text("Scan")
                                .foregroundStyle(.white)
                                .font(.custom("Kiwi Maru Light", size: 22))
                                .frame(width: 300, height: 50)
                                .background(Color(hex: "#C97D60"))
                                .cornerRadius(15)
                        }
                        
                        Button(action: {
                            // Generate functionality will be implemented later
                        }){
                            Text("Generate")
                                .foregroundStyle(.white)
                                .font(.custom("Kiwi Maru Light", size: 22))
                                .frame(width: 300, height: 50)
                                .background(Color(hex: "#C97D60"))
                                .cornerRadius(15)
                        }
                        
                        Button(action: {
                            // Upload file functionality will be implemented later
                        }){
                            Text("Upload file")
                                .foregroundStyle(.white)
                                .font(.custom("Kiwi Maru Light", size: 22))
                                .frame(width: 300, height: 50)
                                .background(Color(hex: "#C97D60"))
                                .cornerRadius(15)
                        }
                        
                        NavigationLink(destination: ManualCreateView().environmentObject(dataManager)) {
                            Text("Create manually")
                                .foregroundStyle(.white)
                                .font(.custom("Kiwi Maru Light", size: 22))
                                .frame(width: 300, height: 50)
                                .background(Color(hex: "#C97D60"))
                                .cornerRadius(15)
                        }
                    }
                    .shadow(color: Color(hex: "#C97D60").opacity(0.5), radius: 5, x: 0, y: 5)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 50)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color(hex: "#C97D60"))
                            .font(.system(size: 25))
                    }
                    .padding(.leading, 5)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NewSetView()
        .environmentObject(DataManager())
}
