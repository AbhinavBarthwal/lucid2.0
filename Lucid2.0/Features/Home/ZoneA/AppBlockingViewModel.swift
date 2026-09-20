//
//  AppBlockingViewModel.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import SwiftUI
import Combine
import FamilyControls

@Observable
public final class AppBlockingViewModel {
    public var blocks: [ScheduledBlock] = []
    public var showPopup: Bool = false
    public var showAppPicker: Bool = false
    public var isAuthorized: Bool = false
    public var errorMessage: String?
    public var isEditing: Bool = false

    // MARK: - Draft State for Popup Sheet
    public var draftId: UUID = UUID()
    public var draftName: String = "Focus Time"
    public var isRenaming: Bool = false

    public var draftFromDate: Date = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date() {
        didSet {
            // End time cannot precede or equal start time
            if draftToDate <= draftFromDate {
                draftToDate = draftFromDate.addingTimeInterval(45 * 60)
            }
        }
    }

    public var draftToDate: Date = Calendar.current.date(bySettingHour: 18, minute: 45, second: 0, of: Date()) ?? Date() {
        didSet {
            // End time cannot precede or equal start time
            if draftToDate <= draftFromDate {
                draftToDate = draftFromDate.addingTimeInterval(30 * 60)
            }
        }
    }

    public var draftDays: Set<Weekday> = [.mon, .tue, .wed, .thu, .fri]
    public var draftHardMode: Bool = false
    public var draftSelection: FamilyActivitySelection = FamilyActivitySelection()

    // Expanded states for pickers
    public var showFromTimePicker: Bool = false
    public var showToTimePicker: Bool = false

    private let repository = BlockRepository.shared
    private let service = ScreenTimeService.shared

    public init() {
        loadBlocks()
        checkAuthorization()
    }

    // MARK: - Authorization

    public func checkAuthorization() {
        self.isAuthorized = service.isAuthorized
    }

    public func requestAuthorization() async {
        do {
            try await service.requestAuthorization()
            await MainActor.run {
                self.isAuthorized = self.service.isAuthorized
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Screen Time access was not granted: \(error.localizedDescription)"
                print("[AppBlockingViewModel] Auth failed: \(error)")
            }
        }
    }

    // MARK: - Data Loading

    public func loadBlocks() {
        self.blocks = repository.fetchAllBlocks()
    }

    // MARK: - Modal Triggers

    public func openNewBlock() {
        self.draftId = UUID()
        self.draftName = "Focus Time"
        self.isRenaming = false
        self.isEditing = false

        let calendar = Calendar.current
        let from = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
        let to = calendar.date(bySettingHour: 18, minute: 45, second: 0, of: Date()) ?? Date()
        self.draftFromDate = from
        self.draftToDate = to
        self.draftDays = [.mon, .tue, .wed, .thu, .fri]
        self.draftHardMode = false
        self.draftSelection = FamilyActivitySelection()
        self.showFromTimePicker = false
        self.showToTimePicker = false
        self.showPopup = true

        Task {
            if !isAuthorized {
                await requestAuthorization()
            }
        }
    }

    public func openEditBlock(_ block: ScheduledBlock) {
        self.draftId = block.id
        self.draftName = block.name
        self.isRenaming = false
        self.isEditing = true

        let calendar = Calendar.current
        var from = calendar.date(bySettingHour: block.fromHour, minute: block.fromMinute, second: 0, of: Date()) ?? Date()
        var to = calendar.date(bySettingHour: block.toHour, minute: block.toMinute, second: 0, of: Date()) ?? Date()
        if to <= from {
            to = from.addingTimeInterval(45 * 60)
        }
        self.draftFromDate = from
        self.draftToDate = to
        self.draftDays = block.days
        self.draftHardMode = block.hardMode

        if let selection = repository.fetchSelection(for: block.id) {
            self.draftSelection = selection
        } else {
            self.draftSelection = FamilyActivitySelection()
        }

        self.showFromTimePicker = false
        self.showToTimePicker = false
        self.showPopup = true

        Task {
            if !isAuthorized {
                await requestAuthorization()
            }
        }
    }

    // MARK: - Day Selection

    public func toggleDay(_ day: Weekday) {
        if draftDays.contains(day) {
            draftDays.remove(day)
        } else {
            draftDays.insert(day)
        }
    }

    public var selectedDaysSummary: String {
        if draftDays.count == 7 {
            return "Everyday"
        } else if draftDays == [.mon, .tue, .wed, .thu, .fri] {
            return "Weekdays"
        } else if draftDays == [.sun, .sat] {
            return "Weekends"
        } else if draftDays.isEmpty {
            return "Never"
        } else {
            return "Custom"
        }
    }

    // MARK: - Time Formatting

    public var draftFromFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: draftFromDate)
    }

    public var draftToFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: draftToDate)
    }

    // MARK: - App Count

    public var selectedAppsCount: Int {
        draftSelection.applicationTokens.count + draftSelection.categoryTokens.count
    }

    // MARK: - Commit and Delete

    public func commitDraft(dismissImmediately: Bool = true) {
        let calendar = Calendar.current
        let fromHour = calendar.component(.hour, from: draftFromDate)
        let fromMinute = calendar.component(.minute, from: draftFromDate)

        // Safety enforcement: ending time cannot precede starting time
        var effectiveToDate = draftToDate
        if effectiveToDate <= draftFromDate {
            effectiveToDate = draftFromDate.addingTimeInterval(45 * 60)
        }
        let toHour = calendar.component(.hour, from: effectiveToDate)
        let toMinute = calendar.component(.minute, from: effectiveToDate)

        let block = ScheduledBlock(
            id: draftId,
            name: draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Focus Time" : draftName,
            fromHour: fromHour,
            fromMinute: fromMinute,
            toHour: toHour,
            toMinute: toMinute,
            days: draftDays,
            hardMode: draftHardMode,
            isEnabled: true
        )

        // Persist block and selection
        repository.saveBlock(block)
        repository.saveSelection(draftSelection, for: block.id)

        // Schedule monitoring via DeviceActivity
        service.scheduleBlock(block, selection: draftSelection)

        loadBlocks()
        if dismissImmediately {
            showPopup = false
        }
    }

    public func canDeleteBlock(_ block: ScheduledBlock) -> Bool {
        if block.hardMode && service.isBlockActiveNow(block) {
            // Hard Mode strictly locks out mid-session unblocking/deletion
            return false
        }
        return true
    }

    public func deleteBlock(id: UUID) {
        guard let block = blocks.first(where: { $0.id == id }) else { return }
        guard canDeleteBlock(block) else {
            print("[AppBlockingViewModel] Cannot delete block during active Hard Mode session.")
            return
        }

        service.stopMonitoringBlock(id: id)
        repository.deleteBlock(id: id)
        loadBlocks()
    }

    public func isBlockActiveNow(_ block: ScheduledBlock) -> Bool {
        service.isBlockActiveNow(block)
    }

    // MARK: - Active Block and Selection Helpers

    public var primaryBlock: ScheduledBlock? {
        blocks.first
    }

    public var primaryBlockSelection: FamilyActivitySelection? {
        guard let id = blocks.first?.id else { return nil }
        return repository.fetchSelection(for: id)
    }

    public var primaryBlockCategoriesCount: Int {
        primaryBlockSelection?.categoryTokens.count ?? 0
    }

    public var primaryBlockAppsCount: Int {
        primaryBlockSelection?.applicationTokens.count ?? 0
    }

    public var isPrimaryBlockActive: Bool {
        guard let block = primaryBlock else { return false }
        return isBlockActiveNow(block)
    }

    public func selection(for blockId: UUID) -> FamilyActivitySelection? {
        repository.fetchSelection(for: blockId)
    }
}
