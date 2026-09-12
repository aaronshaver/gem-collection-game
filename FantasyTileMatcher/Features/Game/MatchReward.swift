struct MatchReward {
    let indices: [Int]
    let goldPerTile: Int

    init(indices: [Int], pieces: [Tile]) {
        self.indices = indices
        precondition(indices.count >= 3)
        let first = pieces[indices[0]].adventurer.values
        let shared = first.indices.filter { attribute in
            indices.allSatisfy { pieces[$0].adventurer.values[attribute] == first[attribute] }
        }.count
        goldPerTile = shared < 2 ? 0 : 1 << (shared - 1)
    }
}
