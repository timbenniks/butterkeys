import Foundation

public protocol CorrectionStrategy: Sendable {
    var identifier: String { get }
    func candidates(for context: CorrectionContext, language: LanguageServices) -> [CorrectionCandidate]
}

public struct LanguageServices: Sendable {
    public let dictionary: LocalDictionary
    public let adjacency: KeyboardAdjacencyMap
    public let phrases: PhraseFrequencyStore
    public let motorPatterns: MotorPatternSnapshot

    public init(
        dictionary: LocalDictionary,
        adjacency: KeyboardAdjacencyMap = .qwerty,
        phrases: PhraseFrequencyStore = .bundled,
        motorPatterns: MotorPatternSnapshot = .empty
    ) {
        self.dictionary = dictionary
        self.adjacency = adjacency
        self.phrases = phrases
        self.motorPatterns = motorPatterns
    }
}

public struct MotorPatternSnapshot: Sendable {
    public let nearbyKeyPairs: [String: Double]
    public let transpositionBias: Double
    public let earlySpaceBias: Double

    public static let empty = MotorPatternSnapshot(
        nearbyKeyPairs: [:],
        transpositionBias: 0,
        earlySpaceBias: 0
    )

    public init(nearbyKeyPairs: [String: Double], transpositionBias: Double, earlySpaceBias: Double) {
        self.nearbyKeyPairs = nearbyKeyPairs
        self.transpositionBias = transpositionBias
        self.earlySpaceBias = earlySpaceBias
    }

    public func nearbyBoost(from: Character, to: Character) -> Double {
        let key = "\(from)↔\(to)"
        let alt = "\(to)↔\(from)"
        return nearbyKeyPairs[key] ?? nearbyKeyPairs[alt] ?? 0
    }
}
