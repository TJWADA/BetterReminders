import Foundation

public enum AppConfiguration {
    public static let appGroupID = "group.com.betterreminders.shared"
    public static let fallbackListName = "General"

    public enum OpenAI {
        public static let chatCompletionsURL = URL(string: "https://api.openai.com/v1/chat/completions")!
        public static let modelsURL = URL(string: "https://api.openai.com/v1/models")!
        public static let model = "gpt-4o-mini"
        public static let requestTimeout: TimeInterval = 60
    }

    public enum Recording {
        public static let minimumActionButtonDuration: TimeInterval = 0.75
        public static let minimumUsableFileBytes = 1024
    }

    public enum ProcessingJobs {
        public static let retentionDays = 7
        public static let maxJobs = 20
    }
}
