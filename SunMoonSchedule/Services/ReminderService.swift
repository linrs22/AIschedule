import EventKit
import Foundation

struct ReminderService {
    private let eventStore = EKEventStore()

    func addReminder(from item: ParsedItem) async throws {
        try validate(item)
        try await requestReminderAccessIfNeeded()

        guard let calendar = eventStore.defaultCalendarForNewReminders() else {
            throw ReminderServiceError.noDefaultReminderList
        }

        let reminder = EKReminder(eventStore: eventStore)
        reminder.calendar = calendar
        reminder.title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
        reminder.notes = item.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        reminder.priority = item.priority.reminderPriorityValue

        if let dueDate = item.dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: dueDate
            )
        }

        do {
            try eventStore.save(reminder, commit: true)
        } catch {
            throw ReminderServiceError.saveFailed(error.localizedDescription)
        }

        let identifier = reminder.calendarItemIdentifier
        guard eventStore.calendarItem(withIdentifier: identifier) is EKReminder else {
            throw ReminderServiceError.verificationFailed
        }
    }

    private func validate(_ item: ParsedItem) throws {
        guard !item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ReminderServiceError.missingFields(["标题"])
        }
    }

    private func requestReminderAccessIfNeeded() async throws {
        switch EKEventStore.authorizationStatus(for: .reminder) {
        case .fullAccess:
            return
        case .notDetermined:
            let granted = try await eventStore.requestFullAccessToReminders()

            if !granted {
                throw ReminderServiceError.noPermission
            }
        case .denied, .restricted, .writeOnly:
            throw ReminderServiceError.noPermission
        @unknown default:
            throw ReminderServiceError.noPermission
        }
    }
}

enum ReminderServiceError: LocalizedError {
    case missingFields([String])
    case noPermission
    case noDefaultReminderList
    case saveFailed(String)
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .missingFields(let fields):
            "缺少字段：\(fields.joined(separator: "、"))"
        case .noPermission:
            "没有提醒事项权限，请在系统设置中允许访问提醒事项。"
        case .noDefaultReminderList:
            "没有可用的默认提醒事项列表。"
        case .saveFailed(let message):
            "添加失败：\(message)"
        case .verificationFailed:
            "可能已添加，但验证失败。"
        }
    }
}
