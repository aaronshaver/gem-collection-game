struct FreshField {
    let seed: UInt64
    let pieces: [BoardPiece]
    let attempts: Int
}

extension PopulationGenerator {
    enum FieldError: Error { case noValidField }

    /// Re-roll the entire board. Incrementing avoids duplicate seeds within one millisecond.
    func freshField(seed: UInt64, maximumAttempts: Int = 10_000, existingRocks: [Rock] = []) throws -> FreshField {
        for attempt in 0..<max(0, maximumAttempts) {
            let candidateSeed = seed &+ UInt64(attempt)
            let candidate = generate(seed: candidateSeed, count: BoardLayout.cellCount,
                                     existingRocks: attempt == 0 ? existingRocks : [])
            if !MatchRules.hasMatch(in: candidate) {
                return FreshField(seed: candidateSeed, pieces: candidate, attempts: attempt + 1)
            }
        }
        // A future catalog (e.g. 100% one color) must not cause an infinite loop.
        throw FieldError.noValidField
    }
}
