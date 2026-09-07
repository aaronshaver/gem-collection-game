struct MatchReward {
    let indices: [Int]
    let coinsPerGem: Int
    let banner: String

    init(indices: [Int], pieces: [BoardPiece]) {
        self.indices = indices
        let gems = indices.compactMap { index -> Gem? in
            if case .gem(let gem) = pieces[index] { return gem }
            return nil
        }
        precondition(gems.count == indices.count && gems.count >= 3)
        let first = gems[0]
        let sameClass = gems.allSatisfy { $0.grade.id == first.grade.id }
        let sameShape = gems.allSatisfy { $0.shape.sides == first.shape.sides }
        coinsPerGem = sameClass && sameShape ? 8 : sameClass ? 4 : sameShape ? 5 : 1
        var words = [String(gems.count), first.color.name]
        if sameClass { words.append(first.grade.name) }
        if sameShape { words.append("\(first.shape.sides)-sided") }
        words.append("matched")
        banner = words.joined(separator: " ")
    }
}
