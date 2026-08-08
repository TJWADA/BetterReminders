import Foundation
import BetterRemindersCore

enum ReminderParserService {
    static func parse(
        transcript: String,
        listContexts: [ListClassificationContext]
    ) async throws -> ParsedReminderResponse {
        guard let apiKey = KeychainHelper.loadAPIKey(), !apiKey.isEmpty else {
            throw ParserError.missingAPIKey
        }

        let now = ISO8601DateFormatter().string(from: Date())
        let fallbackList = AppConfiguration.fallbackListName
        let contexts = listContexts.isEmpty
            ? ListSeeder.defaultLists.map {
                ListClassificationContext(
                    name: $0.name,
                    description: $0.description,
                    exampleTitles: [],
                    misclassificationNotes: []
                )
            }
            : listContexts
        let listsText = ListClassificationContext.formatListsBlock(contexts)

        let systemPrompt = makeSystemPrompt(
            now: now,
            listsText: listsText,
            fallbackList: fallbackList
        )

        let body: [String: Any] = [
            "model": AppConfiguration.OpenAI.model,
            "response_format": ["type": "json_object"],
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": transcript],
            ],
        ]

        var request = URLRequest(url: AppConfiguration.OpenAI.chatCompletionsURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = AppConfiguration.OpenAI.requestTimeout

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ParserError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw ParserError.apiError(statusCode: http.statusCode, message: parseAPIErrorMessage(from: data))
        }

        let completion = try JSONDecoder().decode(OpenAICompletion.self, from: data)
        guard let content = completion.choices.first?.message.content else {
            throw ParserError.invalidResponse
        }

        return try parseResponseContent(content, fallbackList: fallbackList)
    }

    static func makeSystemPrompt(now: String, listsText: String, fallbackList: String) -> String {
        """
        You extract structured reminders from voice transcripts.
        Current date/time: \(now)
        Available lists:
        \(listsText)

        Use each list's description, current incomplete reminders, and past corrections to choose the best list.

        Rules:
        - Return JSON only with keys "reminders" and "confidence".
        - Each reminder has: title, list, dueDate (ISO8601 or null), priority (none|low|medium|high).
        - Pick the best matching list from available lists.
        - If none fit, use "\(fallbackList)".
        - Support multiple reminders from one transcript.
        - Summarize titles concisely (under 80 chars).
        - Parse relative dates like "tomorrow", "next Tuesday", "in 2 hours".
        """
    }

    static func validateAPIKey() async throws {
        guard let apiKey = KeychainHelper.loadAPIKey(), !apiKey.isEmpty else {
            throw ParserError.missingAPIKey
        }

        var request = URLRequest(url: AppConfiguration.OpenAI.modelsURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ParserError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw ParserError.apiError(statusCode: http.statusCode, message: parseAPIErrorMessage(from: data))
        }
    }

    private static func parseAPIErrorMessage(from data: Data) -> String {
        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = object["error"] as? [String: Any],
           let message = error["message"] as? String {
            return message
        }
        return String(data: data, encoding: .utf8) ?? "Unknown error"
    }

    private static func parseResponseContent(_ content: String, fallbackList: String) throws -> ParsedReminderResponse {
        let trimmed = content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let contentData = trimmed.data(using: .utf8) else {
            throw ParserError.invalidResponse
        }

        if let decoded = try? JSONDecoder().decode(ParsedReminderResponse.self, from: contentData) {
            guard !decoded.reminders.isEmpty else {
                throw ParserError.noRemindersFound
            }
            return decoded
        }

        guard let object = try JSONSerialization.jsonObject(with: contentData) as? [String: Any] else {
            throw ParserError.invalidResponse
        }

        let rawReminders = object["reminders"] as? [[String: Any]] ?? []
        let reminders = rawReminders.compactMap { item -> ParsedReminder? in
            guard let title = item["title"] as? String, !title.isEmpty else { return nil }
            let list = (item["list"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return ParsedReminder(
                title: title,
                list: (list?.isEmpty == false ? list! : fallbackList),
                dueDate: item["dueDate"] as? String,
                priority: stringify(item["priority"])
            )
        }

        guard !reminders.isEmpty else {
            throw ParserError.noRemindersFound
        }

        let confidence = parseConfidence(object["confidence"])
        return ParsedReminderResponse(reminders: reminders, confidence: confidence)
    }

    private static func stringify(_ value: Any?) -> String? {
        switch value {
        case let string as String:
            return string
        case let number as NSNumber:
            return number.stringValue
        default:
            return nil
        }
    }

    private static func parseConfidence(_ value: Any?) -> Double? {
        switch value {
        case let number as Double:
            return number
        case let number as Int:
            return Double(number)
        case let string as String:
            return Double(string)
        default:
            return nil
        }
    }

    static func priorityValue(from string: String?) -> Int {
        switch string?.lowercased() {
        case "high", "3": return 3
        case "medium", "2": return 2
        case "low", "1": return 1
        default: return 0
        }
    }

    static func parseDueDate(_ string: String?) -> Date? {
        guard let string, !string.isEmpty, string.lowercased() != "null" else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: string) { return date }

        let fallback = DateFormatter()
        fallback.locale = Locale(identifier: "en_US_POSIX")
        fallback.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return fallback.date(from: string)
    }

    enum ParserError: LocalizedError {
        case missingAPIKey
        case invalidResponse
        case noRemindersFound
        case apiError(statusCode: Int, message: String)

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return APIKeyValidator.missingKeyMessage
            case .invalidResponse:
                return "Invalid response from AI service"
            case .noRemindersFound:
                return "AI could not extract any reminders from the recording"
            case .apiError(let code, let message):
                if code == 401 {
                    return "Invalid OpenAI API key. Create a new key at platform.openai.com/api-keys and save it in Settings."
                }
                if code == 429 {
                    return "OpenAI rate limit or quota exceeded. Check billing at platform.openai.com."
                }
                return "OpenAI error (\(code)): \(message)"
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
