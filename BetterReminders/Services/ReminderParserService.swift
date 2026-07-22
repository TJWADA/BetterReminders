import Foundation

struct ParsedReminder: Codable {
    let title: String
    let list: String
    let dueDate: String?
    let priority: String?
}

struct ParsedReminderResponse: Codable {
    let reminders: [ParsedReminder]
    let confidence: Double?
}

enum ReminderParserService {
    static func parse(
        transcript: String,
        listNames: [String],
        recentCorrections: [String] = []
    ) async throws -> ParsedReminderResponse {
        guard let apiKey = KeychainHelper.loadAPIKey(), !apiKey.isEmpty else {
            throw ParserError.missingAPIKey
        }

        let now = ISO8601DateFormatter().string(from: Date())
        let listsText = listNames.joined(separator: ", ")
        let correctionsText = recentCorrections.isEmpty
            ? "None"
            : recentCorrections.joined(separator: "; ")

        let systemPrompt = """
        You extract structured reminders from voice transcripts.
        Current date/time: \(now)
        Available lists: \(listsText)
        Recent user corrections: \(correctionsText)

        Rules:
        - Return JSON only with keys "reminders" and "confidence".
        - Each reminder has: title, list, dueDate (ISO8601 or null), priority (none|low|medium|high).
        - Pick the best matching list from available lists.
        - If none fit, use "Ideas".
        - Support multiple reminders from one transcript.
        - Summarize titles concisely (under 80 chars).
        - Parse relative dates like "tomorrow", "next Tuesday", "in 2 hours".
        """

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "response_format": ["type": "json_object"],
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": transcript],
            ],
        ]

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ParserError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ParserError.apiError(statusCode: http.statusCode, message: message)
        }

        let completion = try JSONDecoder().decode(OpenAICompletion.self, from: data)
        guard let content = completion.choices.first?.message.content,
              let contentData = content.data(using: .utf8) else {
            throw ParserError.invalidResponse
        }

        return try JSONDecoder().decode(ParsedReminderResponse.self, from: contentData)
    }

    static func priorityValue(from string: String?) -> Int {
        switch string?.lowercased() {
        case "high": return 3
        case "medium": return 2
        case "low": return 1
        default: return 0
        }
    }

    static func parseDueDate(_ string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }

    enum ParserError: LocalizedError {
        case missingAPIKey
        case invalidResponse
        case apiError(statusCode: Int, message: String)

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "OpenAI API key not configured. Add it in Settings."
            case .invalidResponse:
                return "Invalid response from AI service"
            case .apiError(let code, let message):
                return "AI service error (\(code)): \(message)"
            }
        }
    }
}

private struct OpenAICompletion: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: Message
    }

    struct Message: Codable {
        let content: String
    }
}
