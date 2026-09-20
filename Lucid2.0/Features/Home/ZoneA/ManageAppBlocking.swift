//
//  ManageAppBlocking.swift
//  Lucid2.0
//
//  Created by Abhinav Barthwal on 09/09/26.
//

import SwiftUI
import FamilyControls

public struct ManageAppBlocking: View {
    public var viewModel: AppBlockingViewModel?

    public init(viewModel: AppBlockingViewModel? = nil) {
        self.viewModel = viewModel
    }

    private var activeBlock: ScheduledBlock? {
        viewModel?.blocks.first
    }

    private var categoryText: String {
        if let sel = viewModel?.primaryBlockSelection, !sel.categoryTokens.isEmpty {
            return "\(sel.categoryTokens.count) Categories Blocked"
        } else if let sel = viewModel?.primaryBlockSelection, !sel.applicationTokens.isEmpty {
            return "\(sel.applicationTokens.count) Apps Protected"
        }
        return "Social & Entertainment"
    }

    private var timeFrameText: String {
        if let block = activeBlock {
            return "\(block.fromTimeFormatted) – \(block.toTimeFormatted)"
        }
        return "6:00 PM – 6:45 PM"
    }

    private var daysText: String {
        if let block = activeBlock {
            return block.daysSummary
        }
        return "Weekdays"
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "person.badge.shield.checkmark.fill")
                    .font(.system(size: 15, weight: .bold))

                Text("Manage App Blocking")
                    .font(.callout)
                    .bold()

                Spacer()

                if let block = activeBlock, viewModel?.isBlockActiveNow(block) == true {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("Active Now")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.green.opacity(0.12)))
                    .glassEffect(.clear, in: .capsule)
                }
            }
            .foregroundStyle(Color.orange)

            HStack(alignment: .center, spacing: 12) {
                // Top 1 to 3 blocked apps with their logos
                ZStack {
                    Image("SnapchatLogo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 38, height: 38)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: Color.black.opacity(0.3), radius: 4)
                        .padding(.trailing, 26)
                        .padding(.bottom, 26)

                    Image("YoutubeLogo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 38, height: 38)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: Color.black.opacity(0.3), radius: 4)

                    Image("InstagramLogo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 38, height: 38)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: Color.black.opacity(0.3), radius: 4)
                        .padding([.top, .leading], 26)
                }
                .frame(width: 76, height: 76)

                // Category, Time Frame, and Dates Information
                VStack(alignment: .leading, spacing: 5) {
                    // Category information
                    HStack(spacing: 5) {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.orange)

                        Text(categoryText)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }

                    // Time frame
                    HStack(spacing: 5) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(red: 52/255, green: 211/255, blue: 153/255))

                        Text(timeFrameText)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(red: 52/255, green: 211/255, blue: 153/255))
                    }

                    // Dates / Days active
                    HStack(spacing: 5) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.65))

                        Text(daysText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.70))
                    }
                }

                Spacer()

                // Manage / Edit action button
                Button {
                    if let firstBlock = viewModel?.blocks.first {
                        viewModel?.openEditBlock(firstBlock)
                    } else {
                        viewModel?.openNewBlock()
                    }
                } label: {
                    Image(systemName: "arrow.forward")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.glass)
                .padding(.trailing, 4)
            }
        }
        .padding([.leading, .top, .bottom], 16)
        .padding(.trailing, 12)
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

#Preview("ManageAppBlocking - Standard") {
    struct PreviewHost: View {
        @State private var vm = AppBlockingViewModel()
        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                ManageAppBlocking(viewModel: vm)
                    .padding()
            }
            .onAppear {
                vm.blocks = [
                    ScheduledBlock(
                        name: "Evening Winddown",
                        fromHour: 18,
                        fromMinute: 0,
                        toHour: 18,
                        toMinute: 45,
                        days: [.mon, .tue, .wed, .thu, .fri],
                        hardMode: true
                    )
                ]
            }
        }
    }
    return PreviewHost()
}

#Preview("ManageAppBlocking - Empty Fallback") {
    ZStack {
        Color.black.ignoresSafeArea()
        ManageAppBlocking()
            .padding()
    }
}
