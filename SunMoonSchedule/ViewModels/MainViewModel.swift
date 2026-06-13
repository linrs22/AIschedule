import AppKit
import Foundation

@MainActor
final class MainViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var inputImage: NSImage?
    @Published var ocrText: String = ""
    @Published var isOCRTextVisible: Bool = false
    @Published var parsedItems: [ParsedItem] = []
    @Published var statusText: String = "等待输入"
    @Published var isParsing: Bool = false

    private let aiParsingService = AIParsingService()
    private let ocrService = OCRService()
    private let calendarService = CalendarService()
    private let reminderService = ReminderService()

    var canParse: Bool {
        !isParsing && (!trimmedInputText.isEmpty || inputImage != nil)
    }

    var hasMixedInput: Bool {
        !trimmedInputText.isEmpty && inputImage != nil
    }

    func parseInput() async {
        guard canParse else {
            parsedItems = []
            statusText = "等待输入"
            return
        }

        isParsing = true
        if hasMixedInput {
            statusText = "正在识别图片，并与输入文字一起解析..."
        } else {
            statusText = inputImage == nil ? "正在调用 DeepSeek 解析..." : "正在识别图片文字..."
        }

        do {
            let textToParse = try await combinedTextForParsing()
            statusText = hasMixedInput ? "正在合并文字与图片内容..." : "正在调用 DeepSeek 解析..."
            parsedItems = try await aiParsingService.parse(textToParse)
            statusText = parsedItems.isEmpty ? "未识别到日程或提醒事项" : "已解析 \(parsedItems.count) 个事项"
        } catch let error as OCRServiceError {
            parsedItems = []
            statusText = error.localizedDescription
        } catch AIParsingServiceError.missingAPIKey {
            parsedItems = []
            statusText = "请先在设置中填写 DeepSeek API Key。"
        } catch AIParsingServiceError.invalidJSON {
            parsedItems = []
            statusText = "解析失败，请检查返回格式"
        } catch {
            parsedItems = []
            statusText = "API 调用失败：\(error.localizedDescription)"
        }

        isParsing = false
    }

    func clear() {
        inputText = ""
        inputImage = nil
        ocrText = ""
        isOCRTextVisible = false
        parsedItems = []
        statusText = "等待输入"
    }

    func setInputImage(_ image: NSImage) {
        inputImage = image
        ocrText = ""
        isOCRTextVisible = false
        statusText = "已添加图片，点击解析后将先进行 OCR"
    }

    func clearInputImage() {
        inputImage = nil
        ocrText = ""
        statusText = trimmedInputText.isEmpty ? "等待输入" : "已移除图片"
    }

    func addToCalendar(_ item: ParsedItem) async {
        statusText = "正在添加到日历：\(item.title)"

        do {
            try await calendarService.addCalendarEvent(from: item)
            statusText = "已添加到日历：\(item.title)"
        } catch CalendarServiceError.noPermission {
            statusText = "没有日历权限，请在系统设置中允许访问日历。"
        } catch CalendarServiceError.verificationFailed {
            statusText = "可能已添加，但验证失败。"
        } catch {
            statusText = error.localizedDescription
        }
    }

    func addToReminder(_ item: ParsedItem) async {
        statusText = "正在添加到提醒事项：\(item.title)"

        do {
            try await reminderService.addReminder(from: item)
            statusText = "已添加到提醒事项：\(item.title)"
        } catch ReminderServiceError.noPermission {
            statusText = "没有提醒事项权限，请在系统设置中允许访问提醒事项。"
        } catch ReminderServiceError.verificationFailed {
            statusText = "可能已添加，但验证失败。"
        } catch {
            statusText = error.localizedDescription
        }
    }

    private var trimmedInputText: String {
        inputText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func combinedTextForParsing() async throws -> String {
        var parts: [String] = []

        if !trimmedInputText.isEmpty {
            parts.append("""
            用户输入文字：
            \(trimmedInputText)
            """)
        }

        if let inputImage {
            let recognizedText = try await ocrService.recognizeText(in: inputImage)
            ocrText = recognizedText
            isOCRTextVisible = false

            if !recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                parts.append("""
                图片 OCR 文字：
                \(recognizedText)
                """)
            }
        }

        return parts.joined(separator: "\n\n")
    }
}
