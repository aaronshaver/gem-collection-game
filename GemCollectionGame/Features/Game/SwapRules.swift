/// Only rejected swaps exist for now; same-color gem mechanics are still pending.
enum SwapRules {
    static func rejects(_ first: BoardPiece, _ second: BoardPiece) -> Bool {
        switch (first, second) {
        case (.gem(let a), .gem(let b)): return a.color.id != b.color.id
        default: return true
        }
    }
}
