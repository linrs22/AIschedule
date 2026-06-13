import Foundation

struct AIParsingService {
    private let endpoint = URL(string: "https://api.deepseek.com/chat/completions")!
    private let model = "deepseek-v4-flash"
    private let apiKeyAccount = "deepSeekAPIKey"

    func parse(_ text: String) async throws -> [ParsedItem] {
        let apiKey = (try? KeychainHelper.loadAPIKey(account: apiKeyAccount))?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !apiKey.isEmpty else {
            throw AIParsingServiceError.missingAPIKey
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(
            ChatCompletionRequest(
                model: model,
                messages: [
                    ChatMessage(role: "system", content: systemPrompt()),
                    ChatMessage(role: "user", content: text)
                ],
                responseFormat: ResponseFormat(type: "json_object"),
                thinking: ThinkingConfiguration(type: "disabled"),
                temperature: 0.1,
                maxTokens: 1200,
                stream: false
            )
        )

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AIParsingServiceError.network(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIParsingServiceError.network("Invalid response")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw AIParsingServiceError.api(message)
        }

        let completion: ChatCompletionResponse
        do {
            completion = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        } catch {
            throw AIParsingServiceError.invalidAPIResponse
        }

        guard let content = completion.choices.first?.message.content,
              let contentData = content.data(using: .utf8) else {
            throw AIParsingServiceError.invalidJSON
        }

        do {
            let decoder = JSONDecoder()
            let aiResponse = try decoder.decode(AIParsedResponse.self, from: contentData)
            return aiResponse.items.map { $0.toParsedItem() }
        } catch {
            throw AIParsingServiceError.invalidJSON
        }
    }

    private func systemPrompt() -> String {
        let currentDate = Date().formatted(.iso8601.year().month().day().time(includingFractionalSeconds: false).timeZone(separator: .colon))
        let timeZone = TimeZone.current.identifier

        return """
        你是一个日程和提醒事项解析器。请从用户提供的文字中提取可以添加到日历或提醒事项的内容。
        当前日期和时间：\(currentDate)
        当前时区：\(timeZone)

        只输出 JSON，不要输出 Markdown，不要解释。
        如果事项有明确开始时间和结束时间，type 为 calendar_event。
        如果是待办、截止、提交、购买、提醒等，type 为 reminder。
        如果只有开始时间没有结束时间，默认持续 1 小时，并在 missing_fields 中标注 end_datetime_inferred。
        如果日期不完整，比如“明天”“下周三”，根据当前日期和当前时区推断绝对日期。
        如果时间不完整，比如“下午开会”，不要乱填具体小时，相关时间字段设为 null，并在 missing_fields 中写 time_ambiguous。
        不要编造地点、人物、备注。
        confidence 是 0 到 1 的数字。

        必须返回如下 JSON 格式：
        {
          "items": [
            {
              "type": "calendar_event 或 reminder",
              "title": "string",
              "start_datetime": "ISO8601 string or null",
              "end_datetime": "ISO8601 string or null",
              "due_datetime": "ISO8601 string or null",
              "is_all_day": false,
              "location": "string or null",
              "notes": "string or null",
              "priority": "low | medium | high | null",
              "confidence": 0.0,
              "missing_fields": ["string"]
            }
          ]
        }
        """
    }
}

enum AIParsingServiceError: LocalizedError {
    case missingAPIKey
    case network(String)
    case api(String)
    case invalidAPIResponse
    case invalidJSON

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            "请先在设置中填写 DeepSeek API Key。"
        case .network(let message):
            "网络请求失败：\(message)"
        case .api(let message):
            "DeepSeek API 返回错误：\(message)"
        case .invalidAPIResponse:
            "API 响应格式异常"
        case .invalidJSON:
            "解析失败，请检查返回格式"
        }
    }
}

private struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let responseFormat: ResponseFormat
    let thinking: ThinkingConfiguration
    let temperature: Double
    let maxTokens: Int
    let stream: Bool

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case responseFormat = "response_format"
        case thinking
        case temperature
        case maxTokens = "max_tokens"
        case stream
    }
}

private struct ChatMessage: Codable {
    let role: String
    let content: String
}

private struct ResponseFormat: Encodable {
    let type: String
}

private struct ThinkingConfiguration: Encodable {
    let type: String
}

private struct ChatCompletionResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: ChatMessage
    }
}

private struct AIParsedResponse: Decodable {
    let items: [AIParsedItem]
}

private struct AIParsedItem: Decodable {
    let type: String
    let title: String
    let startDatetime: String?
    let endDatetime: String?
    let dueDatetime: String?
    let isAllDay: Bool?
    let location: String?
    let notes: String?
    let priority: String?
    let confidence: Double
    let missingFields: [String]

    enum CodingKeys: String, CodingKey {
        case type
        case title
        case startDatetime = "start_datetime"
        case endDatetime = "end_datetime"
        case dueDatetime = "due_datetime"
        case isAllDay = "is_all_day"
        case location
        case notes
        case priority
        case confidence
        case missingFields = "missing_fields"
    }

    func toParsedItem() -> ParsedItem {
        ParsedItem(
            type: parsedType,
            title: title,
            startDate: Self.parseDate(startDatetime),
            endDate: Self.parseDate(endDatetime),
            dueDate: Self.parseDate(dueDatetime),
            location: location ?? "",
            notes: notes ?? "",
            priority: parsedPriority,
            confidence: confidence,
            missingFields: missingFields
        )
    }

    private var parsedType: ParsedItemType {
        switch type {
        case "reminder":
            .reminder
        default:
            .calendarEvent
        }
    }

    private var parsedPriority: ParsedItemPriority {
        switch priority {
        case "high":
            .high
        case "medium":
            .medium
        case "low":
            .low
        default:
            .none
        }
    }

    private static func parseDate(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else {
            return nil
        }

        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractionalFormatter.date(from: value) {
            return date
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
}
