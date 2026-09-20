//
//  ScreenTimeService.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import Foundation
import Combine
import FamilyControls
import DeviceActivity
import ManagedSettings

public final class ScreenTimeService: @unchecked Sendable {
    public static let shared = ScreenTimeService()

    private let center = DeviceActivityCenter()
    private let store = ManagedSettingsStore()

    private init() {}

    // MARK: - Authorization

    @MainActor
    public func requestAuthorization() async throws {
        #if targetEnvironment(simulator)
        print("[ScreenTimeService] Running on Simulator. FamilyControls authorization is simulated.")
        #else
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        #endif
    }

    public var isAuthorized: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return AuthorizationCenter.shared.authorizationStatus == .approved
        #endif
    }

    // MARK: - Schedule Monitoring

    public func scheduleBlock(_ block: ScheduledBlock, selection: FamilyActivitySelection) {
        let activityName = DeviceActivityName("lucid.block.\(block.id.uuidString)")

        let startComponents = DateComponents(hour: block.fromHour, minute: block.fromMinute)
        let endComponents = DateComponents(hour: block.toHour, minute: block.toMinute)

        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: true
        )

        do {
            try center.startMonitoring(activityName, during: schedule)
            print("[ScreenTimeService] Successfully scheduled activity: \(activityName.rawValue)")
        } catch {
            print("[ScreenTimeService] Failed to schedule activity \(activityName.rawValue): \(error)")
        }

        // If block is active right now and matches today's weekday, apply shields immediately
        if isBlockActiveNow(block) {
            applyShield(for: selection)
        }
    }

    public func stopMonitoringBlock(id: UUID) {
        let activityName = DeviceActivityName("lucid.block.\(id.uuidString)")
        center.stopMonitoring([activityName])
        print("[ScreenTimeService] Stopped monitoring: \(activityName.rawValue)")
    }

    public func stopAllMonitoring() {
        center.stopMonitoring()
        clearShield()
    }

    // MARK: - Direct Shield Control

    public func applyShield(for selection: FamilyActivitySelection) {
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        print("[ScreenTimeService] Applied shields for \(selection.applicationTokens.count) apps and \(selection.categoryTokens.count) categories")
    }

    public func clearShield() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        print("[ScreenTimeService] Cleared all shields")
    }

    // MARK: - Time Calculations

    public func isBlockActiveNow(_ block: ScheduledBlock) -> Bool {
        guard block.isEnabled else { return false }

        let now = Date()
        let calendar = Calendar.current
        let currentWeekdayInt = calendar.component(.weekday, from: now) // 1=Sun, 2=Mon...
        guard let currentWeekday = Weekday(rawValue: currentWeekdayInt) else { return false }

        guard block.days.contains(currentWeekday) else { return false }

        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTotalMinutes = currentHour * 60 + currentMinute

        let fromTotalMinutes = block.fromHour * 60 + block.fromMinute
        let toTotalMinutes = block.toHour * 60 + block.toMinute

        if fromTotalMinutes <= toTotalMinutes {
            // Normal range within same day (e.g. 18:00 to 18:45)
            return currentTotalMinutes >= fromTotalMinutes && currentTotalMinutes < toTotalMinutes
        } else {
            // Spans midnight (e.g. 23:00 to 02:00)
            return currentTotalMinutes >= fromTotalMinutes || currentTotalMinutes < toTotalMinutes
        }
    }
}
