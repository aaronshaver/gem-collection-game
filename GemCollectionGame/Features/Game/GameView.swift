import SwiftUI
import UIKit

struct GameView: View {
    @ObservedObject var board: GameBoard
    let onMainMenu: () -> Void
    @State private var fieldID = UUID()
    @State private var showingCollection = false
    @State private var stashMode: StashMode = .closed
    @State private var banner: String?

    private enum StashMode: Equatable {
        case closed, drawer, adding, choosing
        case placing(Int)
        case destroying
        var showsDrawer: Bool { self == .drawer || self == .choosing }
        var choosesBoard: Bool {
            switch self {
            case .adding, .placing: return true
            default: return false
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            gameContent
                .accessibilityElement(children: .contain)
                .allowsHitTesting(!stashMode.showsDrawer)
                .accessibilityHidden(stashMode.showsDrawer)

            if stashMode.showsDrawer {
                Color.black.opacity(0.4)
                    .onTapGesture { closeStash() }
                    .accessibilityHidden(true)
                stashDrawer
                    .transition(.move(edge: .bottom))
            }
        }
        .overlay(alignment: .top) { selectionPrompt }
        .task(id: banner) {
            guard banner != nil else { return }
            do { try await Task.sleep(nanoseconds: 2_000_000_000) } catch { return }
            banner = nil
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            GameNavigationBar(
                onMainMenu: {
                    closeStash()
                    onMainMenu()
                },
                onCollection: {
                    closeStash()
                    board.markCollectionRead()
                    showingCollection = true
                },
                onStash: {
                    showingCollection = false
                    if stashMode == .closed { stashMode = .drawer } else { closeStash() }
                }, stashSelected: stashMode != .closed,
                collectionSelected: showingCollection, hasUnread: board.collection.hasUnread)
        }
        .onAppear { board.resolveIfNeeded() }
        .onChange(of: board.destructionIndex) { index in
            if index == nil && stashMode == .destroying { closeStash() }
        }
        .overlay {
            #if DEBUG
                if !showingCollection && stashMode == .closed && !board.isResolving {
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

    private var gameContent: some View {
        VStack(spacing: 0) {
            if showingCollection {
                CollectionView(collection: board.collection, onClose: { showingCollection = false })
            } else {
                StatsBarView(coins: board.coins)
                GemBoardView(
                    pieces: board.pieces, collectedIDs: board.collectedIDs,
                    spawnRows: board.spawnRows, isResolving: board.isResolving,
                    onSwap: board.swap,
                    onTap: boardTap,
                    destructionIndex: board.destructionIndex
                )
                .id(fieldID)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(SoilBackground())
            }
        }
    }

    private var stashDrawer: some View {
        GeometryReader { geometry in
            StashView(
                stash: board.stash, choosingGem: stashMode == .choosing,
                isResolving: board.isResolving, onClose: closeStash,
                onAdd: {
                    stashMode = .adding
                    showBanner("Choose a gem")
                },
                onPut: {
                    stashMode = .choosing
                    showBanner("Choose a gem to place on the board")
                },
                onChoose: { slot in
                    guard stashMode == .choosing else { return }
                    stashMode = .placing(slot)
                    showBanner("Pick a location")
                }
            )
            .frame(height: geometry.size.height * 0.88)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }

    @ViewBuilder
    private var selectionPrompt: some View {
        if stashMode.choosesBoard {
            HStack {
                Text(stashMode == .adding ? "Choose a gem" : "Pick a location")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button("Cancel") {
                    stashMode = .drawer
                    banner = nil
                }
                .tint(.mint)
            }
            .padding(14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 20)
            .padding(.top, 4)
        } else if let banner {
            Text(banner)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 22).padding(.vertical, 12)
                .background(.regularMaterial, in: Capsule())
                .padding(.top, 8)
                .allowsHitTesting(false)
        }
    }

    private var boardTap: ((Int) -> Void)? {
        guard stashMode.choosesBoard else { return nil }
        return { index in handleBoardTap(index) }
    }

    private func handleBoardTap(_ index: Int) {
        switch stashMode {
        case .adding:
            if board.stashGem(at: index) {
                stashMode = .drawer
                banner = nil
            }
        case .placing(let slot):
            if board.placeStashedGem(from: slot, at: index) {
                stashMode = .destroying
                banner = nil
            }
        default: break
        }
    }

    private func closeStash() {
        stashMode = .closed
        banner = nil
    }

    private func showBanner(_ text: String) {
        banner = text
        UIAccessibility.post(notification: .announcement, argument: text)
    }
}

#Preview {
    ZStack {
        GameBackground()
        GameView(board: GameBoard(), onMainMenu: {})
    }
    .preferredColorScheme(.dark)
}
