//
//  ProtectView.swift
//  Lucid2.0
//

import SwiftUI

struct ProtectView: View {
    var body: some View {
        VStack{
            Text("Protect")
            Text("sdfgfsgsf")
        }
        .frame( width: 100, height: 100)
        .glassEffect(.clear, in: .capsule)
        .background(Color.blue)
        .cornerRadius(100)
        
        
    }
}

#Preview {
    ProtectView()
}
