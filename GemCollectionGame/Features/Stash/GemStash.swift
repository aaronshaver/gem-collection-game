import Foundation

/// Slots retain individual gems (including duplicate combinations) in row-major order.
struct GemStash: Codable, Equatable {
    private(set) var slots: [Gem?]

    init(capacity: Int = 1) {
        slots = Array(repeating: nil, count: max(1, capacity))
    }

    var hasFreeSlot: Bool { slots.contains { $0 == nil } }
    var isEmpty: Bool { slots.allSatisfy { $0 == nil } }

    @discardableResult
    mutating func insert(_ gem: Gem) -> Bool {
        guard let index = slots.firstIndex(where: { $0 == nil }) else { return false }
        slots[index] = gem
        return true
    }

    @discardableResult
    mutating func remove(at index: Int) -> Gem? {
        guard slots.indices.contains(index) else { return nil }
        let gem = slots[index]
        slots[index] = nil
        return gem
    }
}
