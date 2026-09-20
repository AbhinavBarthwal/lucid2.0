//
//  LucidMonitorExtension.swift
//  LucidMonitor
//
//  Created by Antigravity on 20/09/26.
//

import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

// The DeviceActivityMonitor runs in the background extension process
// when schedule intervals begin or end.
class LucidMonitorExtension: DeviceActivityMonitor {
    private let store = ManagedSettingsStore()
    private let appGroupSuiteName = "group.com.lucid2.appgroup"

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        guard let defaults = UserDefaults(suiteName: appGroupSuiteName) else {
            return
        }

        // Activity name is formatted as "lucid.block.<UUID>"
        let blockIdString = activity.rawValue.replacingOccurrences(of: "lucid.block.", with: "")

        // Attempt to load specific selection for this block
        if let specificData = defaults.data(forKey: "selection_\(blockIdString)"),
           let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: specificData) {
            applyShields(selection: selection)
            return
        }

        // Fallback to active general selection
        if let generalData = defaults.data(forKey: "active_selection"),
           let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: generalData) {
            applyShields(selection: selection)
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        clearShields()
    }

    override func eventDidReachThreshold(for activity: DeviceActivityName, event: DeviceActivityEvent.Name) {
        super.eventDidReachThreshold(for: activity, event: event)
    }

    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
    }

    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
    }

    // MARK: - Private Helpers

    private func applyShields(selection: FamilyActivitySelection) {
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
    }

    private func clearShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }
}
