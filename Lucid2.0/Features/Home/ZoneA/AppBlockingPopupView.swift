//
//  AppBlockingPopupView.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import SwiftUI
import FamilyControls

public struct AppBlockingPopupView: View {
    @Bindable var viewModel: AppBlockingViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Completion Animation States
    @State private var isShowingCompletionOverlay: Bool = false
    @State private var checkmarkAnimatedIn: Bool = false
    @State private var isFirstSetup: Bool = true

    private enum ActiveTimePicker {
        case none
        case from
        case to
    }
    @State private var activeTimePicker: ActiveTimePicker = .none

    private let mintColor = Color(red: 52/255, green: 211/255, blue: 153/255)

    public init(viewModel: AppBlockingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            // Translucent glass base layer
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.11, blue: 0.14).opacity(0.88),
                    Color(red: 0.05, green: 0.07, blue: 0.09).opacity(0.94),
                    Color.black.opacity(0.98)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .glassEffect(.clear, in: .rect)
            .ignoresSafeArea()

            // Ambient background glows
            VStack {
                Spacer()

                RadialGradient(
                    colors: [mintColor.opacity(0.18), Color.clear],
                    center: .bottom,
                    startRadius: 0,
                    endRadius: 280
                )
                .frame(height: 220)
                .ignoresSafeArea()
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Main Layout
            VStack(spacing: 0) {
                // MARK: - Header (Edit button removed as requested)
                headerView
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                // Divider line and grabber bar
                VStack(spacing: 8) {
                    Divider()
                        .background(Color.white.opacity(0.12))

                    Capsule()
                        .fill(Color.white.opacity(0.22))
                        .glassEffect(.clear, in: .capsule)
                        .frame(width: 36, height: 4)
                        .padding(.top, 2)
                }
                .padding(.bottom, 12)

                // MARK: - Scrollable Form Content
                ZStack(alignment: .bottom) {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Section 1: During this time
                            duringThisTimeSection

                            // Section 2: On these days
                            onTheseDaysSection

                            // Section 3: Apps are blocked
                            appsAreBlockedSection

                            // Section 4: Hard Mode
                            hardModeSection

                            // Buffer space so content never gets obscured by sticky button
                            Spacer()
                                .frame(height: 96)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                    }

                    // MARK: - Sticky Floating Button (Hovering over everything else, never scrolls)
                    stickyBottomBar
                }
            }

            // MARK: - Completion Animation Overlay
            if isShowingCompletionOverlay {
                completionOverlayView
            }
        }
        .presentationDetents([.fraction(0.88), .large])
        .presentationCornerRadius(32)
        .presentationDragIndicator(.hidden)
        .presentationBackground {
            ZStack {
                Color(red: 0.06, green: 0.08, blue: 0.10).opacity(0.82)
                Rectangle().fill(.ultraThinMaterial)
            }
            .glassEffect(.clear, in: .rect)
        }
        // Family Activity Picker sheet
        .familyActivityPicker(
            isPresented: $viewModel.showAppPicker,
            selection: $viewModel.draftSelection
        )
        .onChange(of: viewModel.draftFromDate) { _, newFrom in
            // Enforce ending time cannot precede starting time
            if viewModel.draftToDate <= newFrom {
                viewModel.draftToDate = newFrom.addingTimeInterval(45 * 60)
            }
        }
        .onChange(of: viewModel.draftToDate) { _, newTo in
            // Enforce ending time cannot precede starting time
            if newTo <= viewModel.draftFromDate {
                viewModel.draftToDate = viewModel.draftFromDate.addingTimeInterval(45 * 60)
            }
        }
    }

    // MARK: - Header (Clean title and close button, edit button removed)

    private var headerView: some View {
        HStack {
            // Dismiss button
            Button {
                viewModel.showPopup = false
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 38, height: 38)
                        .glassEffect(.clear, in: .circle)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                        )
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.88))
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // Block Name
            Text(viewModel.draftName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            // Balances the close button on the leading side
            Color.clear
                .frame(width: 38, height: 38)
        }
    }

    // MARK: - Sticky Bottom Bar

    private var stickyBottomBar: some View {
        VStack(spacing: 0) {
            // Subtle gradient scrim fading upwards
            LinearGradient(
                colors: [
                    Color.clear,
                    Color(red: 0.06, green: 0.08, blue: 0.10).opacity(0.85),
                    Color(red: 0.05, green: 0.07, blue: 0.09).opacity(0.98)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)
            .allowsHitTesting(false)

            // Hold to Commit / Save button container
            VStack(spacing: 8) {
                let buttonTitle = viewModel.isEditing ? "Hold to Save" : "Hold to Commit"

                HoldToCommitButton(title: buttonTitle) {
                    triggerCommitWithAnimation()
                }
                .shadow(color: mintColor.opacity(0.35), radius: 18, x: 0, y: 6)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 16)
            
            .background {
                Color(red: 0.05, green: 0.07, blue: 0.09)
                    .opacity(0.4)
                    
                    .ignoresSafeArea(edges: .bottom)
            }
        }
    }

    // MARK: - Section 1: During this time

    private func toggleFromPicker() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            activeTimePicker = (activeTimePicker == .from) ? .none : .from
        }
    }

    private func toggleToPicker() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            activeTimePicker = (activeTimePicker == .to) ? .none : .to
        }
    }

    private var duringThisTimeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("During this time:")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.leading, 4)

            VStack(spacing: 0) {
                // FROM ROW
                HStack {
                    Text("From")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.white)

                    Spacer()

                    // Time display button (clickable)
                    Button(action: toggleFromPicker) {
                        Text(viewModel.draftFromFormatted)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(activeTimePicker == .from ? mintColor : .white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(activeTimePicker == .from ? mintColor.opacity(0.16) : Color.white.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)

                    // Dedicated Upward/Downward Arrow Button to toggle inline picker
                    Button(action: toggleFromPicker) {
                        Image(systemName: activeTimePicker == .from ? "chevron.up" : "chevron.down")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(activeTimePicker == .from ? mintColor : .white.opacity(0.6))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(activeTimePicker == .from ? mintColor.opacity(0.15) : Color.white.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Toggle start time picker")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                // Inline From DatePicker
                if activeTimePicker == .from {
                    VStack(spacing: 8) {
                        DatePicker(
                            "",
                            selection: $viewModel.draftFromDate,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .colorScheme(.dark)
                        .frame(height: 150)
                        .clipped()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Divider()
                    .background(Color.white.opacity(0.10))
                    .padding(.horizontal, 16)

                // TO ROW
                HStack {
                    Text("To")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.white)

                    Spacer()

                    // Time display button (clickable)
                    Button(action: toggleToPicker) {
                        Text(viewModel.draftToFormatted)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(activeTimePicker == .to ? mintColor : .white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(activeTimePicker == .to ? mintColor.opacity(0.16) : Color.white.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)

                    // Dedicated Upward/Downward Arrow Button to toggle inline picker
                    Button(action: toggleToPicker) {
                        Image(systemName: activeTimePicker == .to ? "chevron.up" : "chevron.down")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(activeTimePicker == .to ? mintColor : .white.opacity(0.6))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(activeTimePicker == .to ? mintColor.opacity(0.15) : Color.white.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Toggle end time picker")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                // Inline To DatePicker
                if activeTimePicker == .to {
                    VStack(spacing: 8) {
                        DatePicker(
                            "",
                            selection: $viewModel.draftToDate,
                            in: viewModel.draftFromDate.addingTimeInterval(60)...,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .colorScheme(.dark)
                        .frame(height: 150)
                        .clipped()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            }
            .glassEffect(.clear, in: .rect)
            .cornerRadius(16)
        }
    }

    // MARK: - Section 2: On these days

    private var onTheseDaysSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("On these days:")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()

                Text(viewModel.selectedDaysSummary)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(mintColor)
            }
            .padding(.leading, 4)

            HStack(spacing: 0) {
                ForEach([Weekday.sun, .mon, .tue, .wed, .thu, .fri, .sat], id: \.self) { day in
                    let isSelected = viewModel.draftDays.contains(day)

                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            viewModel.toggleDay(day)
                        }
                    } label: {
                        ZStack {
                            if isSelected {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 38, height: 38)
                                    .glassEffect(.clear, in: .circle)
                                    .shadow(color: Color.white.opacity(0.35), radius: 6)
                                Text(day.symbol)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color.black)
                            } else {
                                Circle()
                                    .fill(Color.white.opacity(0.05))
                                    .frame(width: 38, height: 38)
                                    .glassEffect(.clear, in: .circle)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.24), lineWidth: 1)
                                    )
                                Text(day.symbol)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.75))
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    if day != .sat {
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Section 3: Apps are blocked

    private var appsAreBlockedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.65))
                Text("Apps are blocked")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.leading, 4)

            Button {
                viewModel.showAppPicker = true
            } label: {
                HStack {
                    Text("Selected Apps & Categories")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.white)

                    Spacer()

                    Text(viewModel.selectedAppsCount == 0 ? "Choose" : "\(viewModel.selectedAppsCount) Selected")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.white.opacity(0.6))

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.45))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                }
                .glassEffect(.clear, in: .rect)
                .cornerRadius(16)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Section 4: Hard Mode

    private var hardModeSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Hard Mode")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("PRO")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(mintColor))
                        .glassEffect(.clear, in: .capsule)
                }

                Text("No unblocks allowed")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Toggle("", isOn: $viewModel.draftHardMode)
                .tint(mintColor)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        }
        .glassEffect(.clear, in: .rect)
        .cornerRadius(16)
    }

    // MARK: - Commit & Completion Animation Trigger

    private func triggerCommitWithAnimation() {
        // Record whether this is initial setup or an edit
        isFirstSetup = !viewModel.isEditing
        viewModel.commitDraft(dismissImmediately: false)

        // Show overlay with animated checkmark flying up from the bottom
        withAnimation(.easeInOut(duration: 0.15)) {
            isShowingCompletionOverlay = true
        }

        withAnimation(.spring(response: 0.72, dampingFraction: 0.76)) {
            checkmarkAnimatedIn = true
        }

        // Close animation and dismiss sheet after exactly two seconds
        Task {
            try? await Task.sleep(for: .seconds(2.0))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.25)) {
                    isShowingCompletionOverlay = false
                }
                viewModel.showPopup = false
                dismiss()
            }
        }
    }

    // MARK: - Completion Overlay View

    private var completionOverlayView: some View {
        GeometryReader { geo in
            let screenWidth = geo.size.width
            let screenHeight = geo.size.height
            // Animates from width 1.5x of phone's width to 0.5x at the screen center
            let initialSize = screenWidth * 1.5
            let targetSize = screenWidth * 0.5

            ZStack {
                // Dimmed translucent backdrop
                Color.black.opacity(0.92)
                    .glassEffect(.clear, in: .rect)
                    .ignoresSafeArea()

                VStack(spacing: 22) {
                    ZStack {
                        if isFirstSetup {
                            // Multi-layer glowing aura all around the fill checkmark
                            Circle()
                                .fill(mintColor.opacity(0.42))
                                .frame(
                                    width: checkmarkAnimatedIn ? targetSize * 1.4 : initialSize * 1.1,
                                    height: checkmarkAnimatedIn ? targetSize * 1.4 : initialSize * 1.1
                                )
                                .blur(radius: 36)

                            Circle()
                                .fill(mintColor.opacity(0.24))
                                .frame(
                                    width: checkmarkAnimatedIn ? targetSize * 1.9 : initialSize * 1.35,
                                    height: checkmarkAnimatedIn ? targetSize * 1.9 : initialSize * 1.35
                                )
                                .blur(radius: 56)

                            Image(systemName: "checkmark.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(Color.black, mintColor)
                                .shadow(color: mintColor.opacity(0.95), radius: 30, x: 0, y: 0)
                                .shadow(color: mintColor.opacity(0.60), radius: 54, x: 0, y: 0)
                                .shadow(color: .white.opacity(0.40), radius: 14, x: 0, y: 0)
                        } else {
                            // Simpler checkmark SF symbol when edited
                            Image(systemName: "checkmark")
                                .resizable()
                                .scaledToFit()
                                .fontWeight(.bold)
                                .foregroundStyle(mintColor)
                                .shadow(color: mintColor.opacity(0.50), radius: 16, x: 0, y: 0)
                        }
                    }
                    .frame(
                        width: checkmarkAnimatedIn ? targetSize : initialSize,
                        height: checkmarkAnimatedIn ? targetSize : initialSize
                    )

                    // Text Below Checkmark
                    if isFirstSetup {
                        Text("Setup Complete")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: mintColor.opacity(0.95), radius: 18, x: 0, y: 0)
                            .shadow(color: mintColor.opacity(0.50), radius: 36, x: 0, y: 0)
                            .opacity(checkmarkAnimatedIn ? 1.0 : 0.0)
                            .scaleEffect(checkmarkAnimatedIn ? 1.0 : 0.75)
                    } else {
                        Text("App Block Updated")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                            .opacity(checkmarkAnimatedIn ? 1.0 : 0.0)
                            .scaleEffect(checkmarkAnimatedIn ? 1.0 : 0.8)
                    }
                }
                .position(
                    x: screenWidth / 2,
                    y: checkmarkAnimatedIn ? (screenHeight / 2 - 20) : (screenHeight + initialSize / 2)
                )
            }
            .ignoresSafeArea()
        }
    }
}

#Preview("Sheet Direct - New Block") {
    let vm = AppBlockingViewModel()
    AppBlockingPopupView(viewModel: vm)
}

#Preview("Sheet Direct - Edit Block") {
    let vm = AppBlockingViewModel()
    let _ = vm.openEditBlock(ScheduledBlock.defaultBlock)
    AppBlockingPopupView(viewModel: vm)
}

#Preview("Interactive Sheet Host") {
    struct HostView: View {
        @State private var vm = AppBlockingViewModel()
        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                Button("Open Block Sheet") {
                    vm.openNewBlock()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 52/255, green: 211/255, blue: 153/255))
            }
            .sheet(isPresented: $vm.showPopup) {
                AppBlockingPopupView(viewModel: vm)
            }
        }
    }
    return HostView()
}
