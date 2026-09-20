//
//  SetUpAppBlocking.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import SwiftUI

public struct SetUpAppBlocking: View {
    public var viewModel: AppBlockingViewModel?

    public init(viewModel: AppBlockingViewModel? = nil) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Image(systemName: "person.fill.checkmark")

                Text("Complete Your Setup")
                    .font(.callout)
                    .bold()
            }
            .foregroundStyle(Color.orange)

            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Image("SnapchatLogo")
                        .resizable()
                        .cornerRadius(12)
                        .frame(width: 40, height: 40)
                        .padding(.trailing, 30)
                        .padding(.bottom, 30)

                    Image("YoutubeLogo")
                        .resizable()
                        .cornerRadius(12)
                        .frame(width: 40, height: 40)

                    Image("InstagramLogo")
                        .resizable()
                        .cornerRadius(12)
                        .frame(width: 40, height: 40)
                        .padding([.top, .leading], 30)
                }
                .frame(width: 80, height: 80)
                .padding(.top, 10)

                VStack(alignment: .leading) {
                    Text("Set your Apps to be blocked").bold()

                    Text("Access to these apps will be limited to protect you from digital eye strain")
                        .font(.footnote)
                }

                Button {
                    viewModel?.openNewBlock()
                } label: {
                    Text("Set up")
                }
                .buttonStyle(.glass)
                .padding(16)
            }
        }
        .padding([.leading, .top, .bottom], 16)
        .background {
            LinearGradient(
                colors: [Color.clear, Color.orange.opacity(0.15), Color.orange.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .glassEffect(.clear, in: .rect)
        .cornerRadius(16)
        .padding(8)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        SetUpAppBlocking()
            .padding()
    }
}
