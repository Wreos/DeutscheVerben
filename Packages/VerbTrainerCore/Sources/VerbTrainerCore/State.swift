import Foundation

public struct Progress: Codable, Equatable, Sendable {
    public var attempts = 0
    public var passed = 0
    public var assisted = 0
    public var lastPassed: Bool?
    public var lastAt: String?
    public init() {}
}
public struct Attempt: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let answers: Answers
    public let result: Grade
    public let assisted: Bool
    public let kind, at, sessionId: String
    public var key: String { sessionId + "|" + id + "|" + at }
}
public struct TrainingSession: Codable, Equatable, Identifiable, Sendable {
    public var id = UUID().uuidString
    public var level = "all"
    public var queue: [String] = []
    public var index = 0
    public var results: [Attempt] = []
    public var draft = Answers()
    public var exposed = false
    public var filter = "all"
    public init() {}
    public var finished: Bool { index >= queue.count }
    public var checked: Attempt? { results.indices.contains(index) ? results[index] : nil }
}
public struct HelpEvent: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let at, kind: String
    public let verbIDs: [String]
    public let sessionId: String?
}
public struct TrainerState: Codable, Equatable, Sendable {
    public var version = 1
    public var nativeVersion: Int? = 1
    public var progress: [String: Progress] = [:]
    public var history: [Attempt] = []
    public var session: TrainingSession?
    public var level = "all"
    public var exposures: [String: String]? = [:]
    public var paused: [TrainingSession]? = []
    public var helpEvents: [HelpEvent]? = []
    public init() {}
}
