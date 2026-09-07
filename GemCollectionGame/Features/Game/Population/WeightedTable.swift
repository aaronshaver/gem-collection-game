import Foundation

/// Relative weights need not add up to one. Zero-weight entries are disabled.
struct WeightedTable<Value> {
    enum ValidationError: Error { case invalidWeights }
    let entries: [(value: Value, weight: Double)]
    let total: Double

    init(_ entries: [(value: Value, weight: Double)]) throws {
        let total = entries.reduce(0) { $0 + $1.weight }
        guard !entries.isEmpty, entries.allSatisfy({ $0.weight.isFinite && $0.weight >= 0 }),
              total.isFinite, total > 0 else { throw ValidationError.invalidWeights }
        self.entries = entries
        self.total = total
    }

    func select(unit: Double) -> Value {
        let position = min(max(unit, 0), 1.nextDown) * total
        var boundary = 0.0
        for entry in entries where entry.weight > 0 {
            boundary += entry.weight
            if position < boundary { return entry.value }
        }
        return entries.last(where: { $0.weight > 0 })!.value
    }
}
