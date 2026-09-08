import SwiftUI

struct GameView: View {
    @ObservedObject var board: GameBoard
    let onMainMenu: () -> Void
    @State private var fieldID = UUID()
    @State private var showingCollection = false

    var body: some View {
        VStack(spacing: 0) {
            if showingCollection {
                CollectionView(collection: board.collection, onClose: { showingCollection = false })
            } else {
                StatsBarView(coins: board.coins)
                GemBoardView(pieces: board.pieces, collectedIDs: board.collectedIDs, spawnRows: board.spawnRows, isResolving: board.isResolving, onSwap: board.swap)
                    .id(fieldID)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(SoilBackground())
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            GameNavigationBar(onMainMenu: onMainMenu, onCollection: {
                board.markCollectionRead()
                showingCollection = true
            }, collectionSelected: showingCollection, hasUnread: board.collection.hasUnread)
        }
        .onAppear { board.resolveIfNeeded() }
        .overlay {
            #if DEBUG
            if !showingCollection {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        DebugRefreshButton {
                            fieldID = UUID()
                            board.regenerate()
                        }
                    }
                }
                .ignoresSafeArea(edges: .bottom)
            }
            #endif
        }
    }
}

#Preview {
    ZStack {
        GameBackground()
        GameView(board: GameBoard(), onMainMenu: {})
    }
    .preferredColorScheme(.dark)
}
