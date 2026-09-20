//
//  ScheduledBlock.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import Foundation

public enum Weekday: Int, Codable, CaseIterable, Identifiable, Comparable {
    case sun = 1
    case mon = 2
    case tue = 3
    case wed = 4
    case thu = 5
    case fri = 6
    case sat = 7

    public var id: Int { rawValue }

    public static func < (lhs: Weekday, rhs: Weekday) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var symbol: String {
        switch self {
        case .sun: return "S"
        case .mon: return "M"
        case .tue: return "T"
        case .wed: return "W"
        case .thu: return "T"
        case .fri: return "F"
        case .sat: return "S"
        }
    }

    public var shortName: String {
        switch self {
        case .sun: return "Sun"
        case .mon: return "Mon"
        case .tue: return "Tue"
        case .wed: return "Wed"
        case .thu: return "Thu"
        case .fri: return "Fri"
        case .sat: return "Sat"
        }
    }

    public var fullName: String {
        switch self {
        case .sun: return "Sunday"
        case .mon: return "Monday"
        case .tue: return "Tuesday"
        case .wed: return "Wednesday"
        case .thu: return "Thursday"
        case .fri: return "Friday"
        case .sat: return "Saturday"
        }
    }
}

public struct ScheduledBlock: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var fromHour: Int
    public var fromMinute: Int
    public var toHour: Int
    public var toMinute: Int
    public var days: Set<Weekday>
    public var hardMode: Bool
    public var selectionData: Data?
    public var isEnabled: Bool
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String = "Focus Time",
        fromHour: Int = 18,
        fromMinute: Int = 0,
        toHour: Int = 18,
        toMinute: Int = 45,
        days: Set<Weekday> = [.mon, .tue, .wed, .thu, .fri],
        hardMode: Bool = false,
        selectionData: Data? = nil,
        isEnabled: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.fromHour = fromHour
        self.fromMinute = fromMinute
        self.toHour = toHour
        self.toMinute = toMinute
        self.days = days
        self.hardMode = hardMode
        self.selectionData = selectionData
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }

    public var daysSummary: String {
        if days.count == 7 {
            return "Everyday"
        } else if days == [.mon, .tue, .wed, .thu, .fri] {
            return "Weekdays"
        } else if days == [.sun, .sat] {
            return "Weekends"
        } else if days.isEmpty {
            return "Never"
        } else {
            return "Custom"
        }
    }

    public var fromTimeFormatted: String {
        ScheduledBlock.formatTime(hour: fromHour, minute: fromMinute)
    }

    public var toTimeFormatted: String {
        ScheduledBlock.formatTime(hour: toHour, minute: toMinute)
    }

    public static func formatTime(hour: Int, minute: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        let date = Calendar.current.date(from: comps) ?? Date()
        return formatter.string(from: date)
    }

    public static var defaultBlock: ScheduledBlock {
        ScheduledBlock(
            name: "Focus Time",
            fromHour: 18,
            fromMinute: 0,
            toHour: 18,
            toMinute: 45,
            days: [.mon, .tue, .wed, .thu, .fri],
            hardMode: false
        )
    }
}
