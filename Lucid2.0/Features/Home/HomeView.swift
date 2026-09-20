//
//  HomeView.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import SwiftUI

public struct HomeView: View {
    @State private var blockingVM = AppBlockingViewModel()

    public init() {}

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Zone A: Only show Setup OR Manage, never both simultaneously
                if blockingVM.blocks.isEmpty {
                    SetUpAppBlocking(viewModel: blockingVM)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    ManageAppBlocking(viewModel: blockingVM)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }
            .padding(.vertical, 8)
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: blockingVM.blocks.isEmpty)
        }
        .sheet(isPresented: $blockingVM.showPopup) {
            AppBlockingPopupView(viewModel: blockingVM)
        }
        .onAppear {
            blockingVM.loadBlocks()
        }
    }
}

#Preview("HomeView - Initial Setup State") {
    ZStack {
        Color.black.ignoresSafeArea()
        HomeView()
    }
}

#Preview("HomeView - Manage State") {
    struct PreviewHost: View {
        @State private var vm = AppBlockingViewModel()
        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    ManageAppBlocking(viewModel: vm)
                }
            }
            .onAppear {
                vm.blocks = [ScheduledBlock.defaultBlock]
            }
        }
    }
    return PreviewHost()
}
