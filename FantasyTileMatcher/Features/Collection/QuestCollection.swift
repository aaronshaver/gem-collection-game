import Foundation

struct QuestCollection: Codable, Equatable {
    private(set) var completed: Set<Adventurer> = []
    private(set) var current: Adventurer?
    private(set) var hasUnread = false

    init(current: Adventurer? = nil) { self.current = current ?? Adventurer.all.randomElement()! }

    func count(for race: Race) -> Int { completed.filter { $0.race == race }.count }

    /// Only the assigned target completes a Quest. Multiple matching lines complete it once.
    @discardableResult
    mutating func record(lines: [[Int]], pieces: [Tile]) -> Bool {
        guard let current, lines.contains(where: { line in
            MatchRules.exactRuns(in: line, pieces: pieces).contains { pieces[$0[0]].adventurer == current }
        }) else { return false }
        completed.insert(current)
        hasUnread = true
        self.current = Adventurer.all.filter { !completed.contains($0) }.randomElement()
        return true
    }

    #if DEBUG
    @discardableResult
    mutating func addRandomCompletions<R: RandomNumberGenerator>(using random: inout R) -> Int {
        let total = Adventurer.all.count
        let amount = Int.random(in: (total * 5 / 100)...(total * 30 / 100), using: &random)
        let remaining = Adventurer.all.filter { !completed.contains($0) }
        let additions = remaining.shuffled(using: &random).prefix(amount)
        guard !additions.isEmpty else { return 0 }
        completed.formUnion(additions)
        hasUnread = true
        if let current, completed.contains(current) {
            self.current = Adventurer.all.filter { !completed.contains($0) }.randomElement(using: &random)
        }
        return additions.count
    }
    #endif

    mutating func markRead() { hasUnread = false }
}
