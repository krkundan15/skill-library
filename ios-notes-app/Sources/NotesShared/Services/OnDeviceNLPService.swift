import Foundation
import NaturalLanguage

/// Offline fallback: uses Apple's NaturalLanguage framework to extract
/// key noun phrases as pseudo-action items and build a simple summary.
public final class OnDeviceNLPService: Sendable {

    public init() {}

    public func process(noteContent: String) -> AIProcessingResult {
        let summary = buildSummary(from: noteContent)
        let actions = extractKeyPhrases(from: noteContent)
        return AIProcessingResult(summary: summary, actions: actions)
    }

    // MARK: - Private

    private func buildSummary(from text: String) -> String {
        // Use the first sentence as summary, capped at 120 chars
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
        let first = sentences.first?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !first.isEmpty else { return String(text.prefix(120)) }
        return first.count > 120 ? String(first.prefix(120)) + "…" : first
    }

    private func extractKeyPhrases(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType])
        tagger.string = text

        var phrases: [String] = []
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]

        // Collect noun phrases and named entities as candidate actions
        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .lexicalClass,
            options: options
        ) { tag, range in
            if let tag, tag == .noun || tag == .verb {
                let word = String(text[range])
                if word.count > 3 { phrases.append(word) }
            }
            return true
        }

        // De-duplicate and cap at 5 items
        let unique = Array(NSOrderedSet(array: phrases)) as? [String] ?? phrases
        return Array(unique.prefix(5))
    }
}
