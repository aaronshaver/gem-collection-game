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

    mutating func markRead() { hasUnread = false }
}
