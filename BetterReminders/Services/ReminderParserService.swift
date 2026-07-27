import Foundation

struct ParsedReminder: Codable {
    let title: String
    let list: String
    let dueDate: String?
    let priority: String?

    init(title: String, list: String, dueDate: String? = nil, priority: String? = nil) {
        self.title = title
        self.list = list
        self.dueDate = dueDate
        self.priority = priority
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        list = try container.decode(String.self, forKey: .list)
        dueDate = try container.decodeIfPresent(String.self, forKey: .dueDate)
        if let priorityString = try? container.decode(String.self, forKey: .priority) {
            priority = priorityString
        } else if let priorityInt = try? container.decode(Int.self, forKey: .priority) {
            priority = String(priorityInt)
        } else {
            priority = nil
        }
    }
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
        let listsText = listNames.isEmpty ? "Groceries, Work, Personal, Health, Errands, Ideas" : listNames.joined(separator: ", ")
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
        request.timeoutInterval = 60

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

        return try parseResponseContent(content)
    }

    static func validateAPIKey() async throws {
        guard let apiKey = KeychainHelper.loadAPIKey(), !apiKey.isEmpty else {
            throw ParserError.missingAPIKey
        }

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/models")!)
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

    private static func parseResponseContent(_ content: String) throws -> ParsedReminderResponse {
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
                list: (list?.isEmpty == false ? list! : "Ideas"),
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
                return "OpenAI API key not configured. Add it in Settings."
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
