import EventKit
import Foundation

struct CalendarService {
    private let eventStore = EKEventStore()

    func addCalendarEvent(from item: ParsedItem) async throws {
        try validate(item)
        try await requestCalendarAccessIfNeeded()

        guard let startDate = item.startDate,
              let endDate = item.endDate else {
            throw CalendarServiceError.missingFields(["开始时间", "结束时间"])
        }

        guard let calendar = eventStore.defaultCalendarForNewEvents else {
            throw CalendarServiceError.noDefaultCalendar
        }

        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        event.title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
        event.startDate = startDate
        event.endDate = endDate
        event.location = item.location.trimmingCharacters(in: .whitespacesAndNewlines)
        event.notes = item.notes.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            throw CalendarServiceError.saveFailed(error.localizedDescription)
        }

        guard let eventIdentifier = event.eventIdentifier,
              eventStore.event(withIdentifier: eventIdentifier) != nil else {
            throw CalendarServiceError.verificationFailed
        }
    }

    private func validate(_ item: ParsedItem) throws {
        guard item.type == .calendarEvent else {
            throw CalendarServiceError.notCalendarEvent
        }

        var missingFields: [String] = []

        if item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missingFields.append("标题")
        }

        if item.startDate == nil {
            missingFields.append("开始时间")
        }

        if item.endDate == nil {
            missingFields.append("结束时间")
        }

        if !missingFields.isEmpty {
            throw CalendarServiceError.missingFields(missingFields)
        }
    }

    private func requestCalendarAccessIfNeeded() async throws {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess, .writeOnly:
            return
        case .notDetermined:
            let granted = try await eventStore.requestFullAccessToEvents()

            if !granted {
                throw CalendarServiceError.noPermission
            }
        case .denied, .restricted:
            throw CalendarServiceError.noPermission
        @unknown default:
            throw CalendarServiceError.noPermission
        }
    }
}

enum CalendarServiceError: LocalizedError {
    case notCalendarEvent
    case missingFields([String])
    case noPermission
    case noDefaultCalendar
    case saveFailed(String)
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .notCalendarEvent:
            "只有日历事件可以添加到日历。"
        case .missingFields(let fields):
            "缺少字段：\(fields.joined(separator: "、"))"
        case .noPermission:
            "没有日历权限，请在系统设置中允许访问日历。"
        case .noDefaultCalendar:
            "没有可用的默认日历。"
        case .saveFailed(let message):
            "添加失败：\(message)"
        case .verificationFailed:
            "可能已添加，但验证失败。"
        }
    }
}
