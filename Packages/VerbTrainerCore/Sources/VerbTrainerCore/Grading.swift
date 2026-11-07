import Foundation

public struct Answers: Codable, Equatable, Sendable {
    public var past = ""
    public var participle = ""
    public var aux = ""
    public private(set) var perfect: String?

    /// The combined field preserves the exact input while retaining legacy grading components.
    public var perfectInput: String {
        get {
            if let perfect { return perfect }
            let auxiliary = aux == "sein" ? "ist" : aux == "haben" ? "hat" : aux
            return [auxiliary, participle].filter { !$0.isEmpty }.joined(separator: " ")
        }
        set {
            perfect = newValue
            let components = Self.splitPerfect(newValue)
            participle = components.participle
            aux = components.aux
        }
    }

    public var auxiliaryInput: String {
        guard let perfect else { return aux }
        let words = perfect.split(whereSeparator: \.isWhitespace)
        guard !aux.isEmpty || words.count > 1 else { return "" }
        return words.first.map(String.init) ?? ""
    }

    var hasConsistentPerfect: Bool {
        guard let perfect else { return true }
        let components = Self.splitPerfect(perfect)
        return participle == components.participle && aux == components.aux
    }

    private static func splitPerfect(_ input: String) -> (participle: String, aux: String) {
        let words = input.split(whereSeparator: \.isWhitespace)
        guard let first = words.first else { return ("", "") }
        let auxiliary: String
        switch Grading.normalize(String(first)) {
        case "hat", "haben": auxiliary = "haben"
        case "ist", "sein": auxiliary = "sein"
        default: auxiliary = ""
        }
        let hasPrefix = !auxiliary.isEmpty || words.count > 1
        let participle = (hasPrefix ? words.dropFirst() : words[...]).joined(separator: " ")
        return (participle, auxiliary)
    }
    public init(past: String = "", participle: String = "", aux: String = "") {
        self.past = past
        self.participle = participle
        self.aux = aux
    }
    public init(past: String = "", perfect: String) {
        self.past = past
        self.perfectInput = perfect
    }

    public var isEmpty: Bool { past.isEmpty && participle.isEmpty && aux.isEmpty && (perfect?.isEmpty ?? true) }
    public var complete: Bool {
        let hasPast = !past.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if let perfect {
            return hasPast && !perfect.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return hasPast && !participle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !aux.isEmpty
    }
}
public struct FormResult: Codable, Equatable, Sendable {
    public let status: String
    public let score: Int
    public let expected: String
}
public struct Grade: Codable, Equatable, Sendable {
    public let past, participle, aux: FormResult
    public let score: Double
    public let exact, passed: Bool
}
public enum Grading {
    public static func normalize(_ input: String) -> String {
        var value = input.precomposedStringWithCanonicalMapping.lowercased(with: Locale(identifier: "de"))
            .split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        while let last = value.last, ".!?".contains(last) { value.removeLast() }
        return value.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "ae", with: "ä")
            .replacingOccurrences(of: "oe", with: "ö").replacingOccurrences(of: "ue", with: "ü")
    }
    public static func comparable(_ value: String) -> String {
        normalize(value).replacingOccurrences(of: "ß", with: "ss")
    }
    public static func distance(_ lhs: String, _ rhs: String) -> Int {
        let a = Array(lhs.unicodeScalars)
        let b = Array(rhs.unicodeScalars)
        var row = Array(0...b.count)
        for (i, x) in a.enumerated() {
            var next = [i + 1]
            for (j, y) in b.enumerated() { next.append(min(next[j] + 1, row[j + 1] + 1, row[j] + (x == y ? 0 : 1))) }
            row = next
        }
        return row[b.count]
    }
    public static func assess(_ value: String, expected: String, alternatives: [String] = []) -> FormResult {
        let forms = [expected] + alternatives
        if forms.contains(where: { comparable(value) == comparable($0) }) {
            return .init(status: "correct", score: 10, expected: expected)
        }
        if !normalize(value).isEmpty && forms.contains(where: { distance(normalize(value), normalize($0)) == 1 }) {
            return .init(status: "typo", score: 9, expected: expected)
        }
        return .init(status: "wrong", score: 0, expected: expected)
    }
    public static func grade(_ verb: Verb, _ answers: Answers) -> Grade {
        let p = assess(answers.past, expected: verb.past, alternatives: verb.pastAlternatives ?? [])
        let t = assess(answers.participle, expected: verb.participle, alternatives: verb.participleAlternatives ?? [])
        let a = FormResult(
            status: answers.aux == verb.aux ? "correct" : "wrong", score: answers.aux == verb.aux ? 10 : 0,
            expected: verb.aux)
        return .init(
            past: p, participle: t, aux: a, score: (Double(p.score + t.score + a.score) / 3 * 10).rounded() / 10,
            exact: [p, t, a].allSatisfy { $0.status == "correct" },
            passed: [p, t, a].allSatisfy { $0.status != "wrong" })
    }
}
