//
//  ContentView.swift
//  Lucid2.0
//
//  Created by Abhinav Barthwal on 07/09/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack{
                HomeView().navigationTitle("Home")
                    
            }
            
                
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            ProtectView()
                .tabItem {
                    Label("Protect", systemImage: "shield")
                }
            
            TrainView()
                .tabItem {
                    Label("Train", systemImage: "eye")
                }
        }
    }
}

#Preview {
    ContentView()
}
