import Foundation

enum ParsedItemType: String, CaseIterable, Identifiable {
    case calendarEvent
    case reminder

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .calendarEvent:
            "Calendar Event"
        case .reminder:
            "Reminder"
        }
    }
}
