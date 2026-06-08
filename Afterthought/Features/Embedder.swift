import Foundation
@preconcurrency import NaturalLanguage

/// Wraps Apple's on-device sentence embedding model for semantic search.
///
/// `NLEmbedding.sentenceEmbedding(for:)` returns a 512-dimensional vector
/// per text. We extract raw `[Double]` vectors, store them as `Data` in
/// SwiftData, and compute brute-force cosine similarity at query time.
///
/// If the model fails to load (shouldn't happen on macOS 15+, but be safe),
/// all methods degrade gracefully to nil/0 so the app still works.
enum Embedder {
    /// The shared sentence embedding model for English. Nil only if the
    /// system doesn't provide one (macOS 11+ guarantees it).
    static let shared: NLEmbedding? = NLEmbedding.sentenceEmbedding(for: .english)

    /// Returns a 512-element `[Double]` vector for the given text,
    /// or nil if embedding fails (empty text, model unavailable).
    static func vector(for text: String) -> [Double]? {
        shared?.vector(for: text)
    }

    /// Embeds `text` and returns it as raw `Data` suitable for SwiftData storage.
    /// Returns nil if embedding fails.
    static func embed(_ text: String) -> Data? {
        guard let vec = vector(for: text) else { return nil }
        return vec.withUnsafeBytes { Data($0) }
    }

    /// Cosine similarity between a query vector and a stored embedding `Data`.
    /// Returns 0 if either is invalid or dimensions mismatch.
    static func cosineSimilarity(query: [Double], stored: Data) -> Double {
        let storedVec = stored.withUnsafeBytes { ptr in
            Array(ptr.bindMemory(to: Double.self))
        }
        guard storedVec.count == query.count, !storedVec.isEmpty else { return 0 }

        var dot = 0.0, magA = 0.0, magB = 0.0
        for i in 0..<query.count {
            dot += query[i] * storedVec[i]
            magA += query[i] * query[i]
            magB += storedVec[i] * storedVec[i]
        }
        guard magA > 0, magB > 0 else { return 0 }
        return dot / (sqrt(magA) * sqrt(magB))
    }
}
