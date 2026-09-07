/// One instance per resolution chain: separate player moves never inherit “again”.
struct MatchBannerSequence {
    private var previousBase: String?

    mutating func message(for base: String, isCascade: Bool) -> String {
        let repeated = isCascade && previousBase == base
        previousBase = base
        return repeated ? base + ", again!" : base
    }
}
