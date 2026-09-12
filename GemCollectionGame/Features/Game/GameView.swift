import SwiftUI
import UIKit

struct GameView: View {
    @ObservedObject var board: GameBoard
    let onMainMenu: () -> Void
    @State private var fieldID = UUID()
    @State private var showingCollection = false
    @State private var stashMode: StashMode = .closed
    @State private var banner: String?
    @State private var showingDebug = false
    @State private var debugPreviewRequest: UUID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                .allowsHitTesting(!stashMode.showsDrawer && !showingDebug)
                .accessibilityHidden(stashMode.showsDrawer || showingDebug)

            if stashMode.showsDrawer {
                Color.black.opacity(0.4)
                    .onTapGesture { closeStash() }
                    .accessibilityHidden(true)
                stashDrawer
                    .transition(.move(edge: .bottom))
            }
            #if DEBUG
            if showingDebug {
                Color.black.opacity(0.4)
                    .onTapGesture { closeDebug() }
                    .accessibilityHidden(true)
                DebugToolsDrawer(
                    isResolving: board.isResolving,
                    onClose: closeDebug,
                    onRefresh: {
                        closeDebug()
                        fieldID = UUID()
                        board.regenerate()
                    },
                    onPreviewDiscovery: {
                        closeDebug()
                        debugPreviewRequest = UUID()
                    })
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom))
            }
            #endif
        }
        .overlay(alignment: .top) { selectionPrompt }
        .task(id: banner) {
            guard banner != nil else { return }
            do { try await Task.sleep(nanoseconds: 5_000_000_000) } catch { return }
            banner = nil
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            GameNavigationBar(
                onMainMenu: {
                    closeDebug()
                    closeStash()
                    onMainMenu()
                },
                onCollection: {
                    closeDebug()
                    closeStash()
                    board.markCollectionRead()
                    showingCollection = true
                },
                onStash: {
                    closeDebug()
                    showingCollection = false
                    if stashMode == .closed { stashMode = .drawer } else { closeStash() }
                }, stashSelected: stashMode != .closed,
                collectionSelected: showingCollection, hasUnread: board.collection.hasUnread,
                debugSelected: showingDebug,
                onDebug: {
                    debugPreviewRequest = nil
                    closeStash()
                    showingCollection = false
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.22)) {
                        showingDebug.toggle()
                    }
                })
        }
        .onAppear { board.resolveIfNeeded() }
        .onDisappear { closeStash(); closeDebug() }
        .onChange(of: board.destructionIndex) { index in
            if index == nil && stashMode == .destroying { closeStash() }
        }
        .task(id: debugPreviewRequest) {
            guard debugPreviewRequest != nil else { return }
            do { try await Task.sleep(nanoseconds: 1_000_000_000) } catch { return }
            #if DEBUG
            board.previewDiscovery()
            #endif
            debugPreviewRequest = nil
        }
    }

    private var gameContent: some View {
        VStack(spacing: 0) {
            if showingCollection {
                CollectionView(collection: board.collection, onClose: { showingCollection = false })
            } else {
                StatsBarView(coins: board.coins, collected: board.collection.discovered.count)
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
                .modifier(DiscoveryCelebration(event: board.discoveryEvent))
            }
        }
    }

    private var stashDrawer: some View {
        GeometryReader { geometry in
            StashView(
                stash: board.stash, choosingGem: stashMode == .choosing,
                isResolving: board.isResolving, coins: board.coins, onClose: closeStash,
                onAdd: {
                    guard board.beginStashAction(.storing) else { return }
                    stashMode = .adding
                    showBanner("Choose a gem")
                },
                onPut: {
                    guard board.beginStashAction(.placing) else { return }
                    let occupied = board.stash.slots.indices.filter { board.stash.slots[$0] != nil }
                    if occupied.count == 1, let slot = occupied.first {
                        stashMode = .placing(slot)
                        showBanner("Pick a location")
                    } else {
                        stashMode = .choosing
                        showBanner("Choose a gem to place on the board")
                    }
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
        if stashMode.choosesBoard, banner != nil {
            HStack {
                Text(stashMode == .adding ? "Choose a gem" : "Pick a location")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button("Cancel") {
                    board.cancelStashAction()
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
        board.cancelStashAction()
        stashMode = .closed
        banner = nil
    }

    private func closeDebug() {
        debugPreviewRequest = nil
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.22)) { showingDebug = false }
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
