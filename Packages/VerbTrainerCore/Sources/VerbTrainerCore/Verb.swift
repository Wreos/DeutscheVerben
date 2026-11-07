import Foundation

public struct Verb: Codable, Equatable, Identifiable, Sendable {
    public let id, past, participle, aux, meaning, level, type, context, example: String
    public let pastAlternatives: [String]?
    public let participleAlternatives: [String]?
}

public enum Dictionary {
    public static func load() throws -> [Verb] {
        guard let url = Bundle.module.url(forResource: "verbs", withExtension: "json") else {
            throw TrainerError.invalid("Словарь не найден")
        }
        return try JSONDecoder().decode([Verb].self, from: Data(contentsOf: url))
    }
}

public enum TrainerError: LocalizedError {
    case invalid(String)
    public var errorDescription: String? { if case .invalid(let message) = self { message } else { "Ошибка данных" } }
}
