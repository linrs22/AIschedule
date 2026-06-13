import AppKit
import Foundation
import Vision

struct OCRService {
    func recognizeText(in image: NSImage) async throws -> String {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw OCRServiceError.invalidImage
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
        } catch {
            throw OCRServiceError.recognitionFailed(error.localizedDescription)
        }

        let lines = request.results?
            .compactMap { $0.topCandidates(1).first?.string }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty } ?? []

        guard !lines.isEmpty else {
            throw OCRServiceError.noTextFound
        }

        return lines.joined(separator: "\n")
    }
}

enum OCRServiceError: LocalizedError {
    case invalidImage
    case noTextFound
    case recognitionFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            "OCR 失败：无法读取图片。"
        case .noTextFound:
            "OCR 失败：未识别到文字。"
        case .recognitionFailed(let message):
            "OCR 失败：\(message)"
        }
    }
}
