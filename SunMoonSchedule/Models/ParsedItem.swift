import Foundation

enum ParsedItemPriority: String, CaseIterable, Identifiable {
    case none
    case low
    case medium
    case high

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .none:
            "None"
        case .low:
            "Low"
        case .medium:
            "Medium"
        case .high:
            "High"
        }
    }

    var reminderPriorityValue: Int {
        switch self {
        case .high:
            1
        case .medium:
            5
        case .low:
            9
        case .none:
            0
        }
    }
}

struct ParsedItem: Identifiable, Equatable {
    let id: UUID
    var type: ParsedItemType
    var title: String
    var startDate: Date?
    var endDate: Date?
    var dueDate: Date?
    var location: String
    var notes: String
    var priority: ParsedItemPriority
    var confidence: Double
    var missingFields: [String]

    init(
        id: UUID = UUID(),
        type: ParsedItemType,
        title: String,
        startDate: Date? = nil,
        endDate: Date? = nil,
        dueDate: Date? = nil,
        location: String = "",
        notes: String = "",
        priority: ParsedItemPriority = .none,
        confidence: Double = 0,
        missingFields: [String] = []
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.dueDate = dueDate
        self.location = location
        self.notes = notes
        self.priority = priority
        self.confidence = confidence
        self.missingFields = missingFields
    }
}
