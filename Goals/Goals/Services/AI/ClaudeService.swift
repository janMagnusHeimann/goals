import Foundation

enum ClaudeError: Error, LocalizedError {
    case emptyResponse
    case parsingFailed
    case apiKeyMissing
    case networkError(Error)
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .emptyResponse:
            return "Received empty response from Claude"
        case .parsingFailed:
            return "Failed to parse Claude response"
        case .apiKeyMissing:
            return "Anthropic API key not configured"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}

// MARK: - Request/Response Models

struct ClaudeRequest: Encodable {
    let model: String
    let maxTokens: Int
    let messages: [ClaudeMessage]

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case messages
    }
}

struct ClaudeMessage: Codable {
    let role: String
    let content: String
}

struct ClaudeResponse: Codable {
    let id: String
    let content: [ClaudeContent]
    let model: String
    let stopReason: String?

    enum CodingKeys: String, CodingKey {
        case id, content, model
        case stopReason = "stop_reason"
    }
}

struct ClaudeContent: Codable {
    let type: String
    let text: String
}

struct ClaudeErrorResponse: Codable {
    let error: ClaudeAPIError

    struct ClaudeAPIError: Codable {
        let type: String
        let message: String
    }
}

// MARK: - Goal Structure Suggestions

enum GoalStructureSuggestion {
    case book(BookGoalSuggestion)
    case fitness(FitnessGoalSuggestion)
    case programming(ProgrammingGoalSuggestion)
}

struct BookGoalSuggestion: Codable {
    let suggestedTarget: Int?
    let milestones: [BookMilestone]?
    let readingTips: [String]?
    let suggestedCategories: [String]?
    let summary: String?
}

struct BookMilestone: Codable {
    let title: String
    let targetBooks: Int
}

struct FitnessGoalSuggestion: Codable {
    let suggestedWeeklyHours: Double?
    let weeklyBreakdown: WorkoutBreakdown?
    let phaseStructure: [TrainingPhase]?
    let keyWorkouts: [String]?
    let summary: String?
}

struct WorkoutBreakdown: Codable {
    let swim: Double?
    let bike: Double?
    let run: Double?
    let strength: Double?
    let recovery: Double?
}

struct TrainingPhase: Codable {
    let name: String
    let weeks: Int
    let focus: String
}

struct ProgrammingGoalSuggestion: Codable {
    let suggestedMetrics: [String]?
    let milestones: [ProgrammingMilestone]?
    let focusAreas: [String]?
    let learningResources: [String]?
    let summary: String?
}

struct ProgrammingMilestone: Codable {
    let title: String
    let description: String
}

// MARK: - Claude Service

actor ClaudeService {
    private let session: URLSession
    private let baseURL = Constants.API.anthropicBaseURL
    private let apiVersion = Constants.API.anthropicVersion
    private let model = "claude-sonnet-4-20250514"

    init(session: URLSession = .shared) {
        self.session = session
    }

    func generateGoalStructure(
        goalType: GoalType,
        title: String,
        description: String?,
        apiKey: String
    ) async throws -> GoalStructureSuggestion {
        guard !apiKey.isEmpty else {
            throw ClaudeError.apiKeyMissing
        }

        let prompt = buildPrompt(goalType: goalType, title: title, description: description)

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ClaudeRequest(
            model: model,
            maxTokens: 2048,
            messages: [
                ClaudeMessage(role: "user", content: prompt)
            ]
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeError.networkError(NSError(domain: "", code: -1))
        }

        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(ClaudeErrorResponse.self, from: data) {
                throw ClaudeError.apiError(errorResponse.error.message)
            }
            throw ClaudeError.apiError("HTTP \(httpResponse.statusCode)")
        }

        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)

        guard let content = claudeResponse.content.first?.text else {
            throw ClaudeError.emptyResponse
        }

        return try parseStructureSuggestion(content, goalType: goalType)
    }

    func generateBookSummary(
        title: String,
        author: String?,
        notes: [String],
        apiKey: String
    ) async throws -> String {
        guard !apiKey.isEmpty else {
            throw ClaudeError.apiKeyMissing
        }

        let notesText = notes.joined(separator: "\n- ")
        let prompt = """
        I've been reading "\(title)"\(author.map { " by \($0)" } ?? "").

        Here are my chapter notes:
        - \(notesText)

        Please provide a brief summary (2-3 paragraphs) of the key insights and themes from my notes.
        Focus on synthesizing the main ideas rather than just listing them.
        """

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ClaudeRequest(
            model: model,
            maxTokens: 1024,
            messages: [
                ClaudeMessage(role: "user", content: prompt)
            ]
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ClaudeError.networkError(NSError(domain: "", code: -1))
        }

        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)

        guard let content = claudeResponse.content.first?.text else {
            throw ClaudeError.emptyResponse
        }

        return content
    }

    private func buildPrompt(goalType: GoalType, title: String, description: String?) -> String {
        let descText = description.map { "\nDescription: \($0)" } ?? ""

        switch goalType {
        case .bookReading:
            return """
            I'm creating a book reading goal titled "\(title)".\(descText)

            Please suggest a structure for tracking this goal. Return a JSON object with:
            - suggestedTarget: number of books (if not specified, suggest based on title)
            - milestones: array of milestone objects with {title, targetBooks}
            - readingTips: array of 3 practical tips
            - suggestedCategories: array of book categories/genres to consider
            - summary: a brief encouraging message about this goal

            Return ONLY valid JSON, no markdown code blocks or explanation.
            """

        case .fitness:
            return """
            I'm creating a fitness goal titled "\(title)".\(descText)

            Please suggest a training structure. Return a JSON object with:
            - suggestedWeeklyHours: total weekly training hours
            - weeklyBreakdown: object with {swim, bike, run, strength, recovery} as hours per week
            - phaseStructure: array of training phases with {name, weeks, focus}
            - keyWorkouts: array of workout descriptions to include
            - summary: a brief encouraging message about this goal

            Return ONLY valid JSON, no markdown code blocks or explanation.
            """

        case .programming:
            return """
            I'm creating a programming goal titled "\(title)".\(descText)

            Please suggest a structure for tracking this goal. Return a JSON object with:
            - suggestedMetrics: array of metrics to track (e.g., commits, PRs, issues)
            - milestones: array of milestone objects with {title, description}
            - focusAreas: array of technical areas to focus on
            - learningResources: array of suggested resources
            - summary: a brief encouraging message about this goal

            Return ONLY valid JSON, no markdown code blocks or explanation.
            """
        }
    }

    private func parseStructureSuggestion(_ json: String, goalType: GoalType) throws -> GoalStructureSuggestion {
        var cleanJSON = json.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove markdown code blocks if present
        if cleanJSON.hasPrefix("```json") {
            cleanJSON = String(cleanJSON.dropFirst(7))
        } else if cleanJSON.hasPrefix("```") {
            cleanJSON = String(cleanJSON.dropFirst(3))
        }

        if cleanJSON.hasSuffix("```") {
            cleanJSON = String(cleanJSON.dropLast(3))
        }

        cleanJSON = cleanJSON.trimmingCharacters(in: .whitespacesAndNewlines)

        // Find JSON object boundaries
        if let startIndex = cleanJSON.firstIndex(of: "{"),
           let endIndex = cleanJSON.lastIndex(of: "}") {
            cleanJSON = String(cleanJSON[startIndex...endIndex])
        }

        let data = Data(cleanJSON.utf8)

        do {
            switch goalType {
            case .bookReading:
                let suggestion = try JSONDecoder().decode(BookGoalSuggestion.self, from: data)
                return .book(suggestion)
            case .fitness:
                let suggestion = try JSONDecoder().decode(FitnessGoalSuggestion.self, from: data)
                return .fitness(suggestion)
            case .programming:
                let suggestion = try JSONDecoder().decode(ProgrammingGoalSuggestion.self, from: data)
                return .programming(suggestion)
            }
        } catch {
            print("JSON parsing error: \(error)")
            print("JSON content: \(cleanJSON)")
            throw ClaudeError.parsingFailed
        }
    }
}
