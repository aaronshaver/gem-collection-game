import SwiftUI

struct GameView: View {
    @ObservedObject var board: GameBoard
    let onMainMenu: () -> Void
    @State private var fieldID = UUID()
    @State private var showingQuests = false
    @State private var showingDev = false
    @State private var showingUpgrades = false
    @State private var travelRequested = false
    @State private var showingResetConfirmation = false
    @State private var devPreviewRequest: UUID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .bottom) {
            gameContent
                .accessibilityElement(children: .contain)
                .allowsHitTesting(!showingDev)
                .accessibilityHidden(showingDev)
            #if DEBUG
            if showingDev {
                Color.black.opacity(0.4).onTapGesture { closeDev() }.accessibilityHidden(true)
                DevMenu(isResolving: board.isResolving, onClose: closeDev,
                    onAddRandomCompletion: { closeDev(); board.addRandomCompletion() },
                    onAddGold: { closeDev(); board.addGold() },
                    onReset: { closeDev(); showingResetConfirmation = true },
                    onRefresh: {
                        closeDev()
                        fieldID = UUID()
                        board.regenerate()
                    }, onPreviewDiscovery: {
                        closeDev()
                        devPreviewRequest = UUID()
                    })
                    .transition(.opacity)
            }
            #endif
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            GameNavigationBar(onMainMenu: { closeDev(); onMainMenu() },
                onQuests: {
                    closeDev()
                    board.markCollectionRead()
                    showingQuests.toggle()
                },
                onUpgrades: {
                    closeDev()
                    showingQuests = false
                    showingUpgrades = true
                }, questsSelected: showingQuests, hasUnread: board.collection.hasUnread,
                devSelected: showingDev, onDev: {
                    devPreviewRequest = nil
                    showingQuests = false
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.22)) { showingDev.toggle() }
                })
        }
        .sheet(isPresented: $showingUpgrades, onDismiss: {
            if travelRequested {
                travelRequested = false
                board.travelToNearbyTown()
            }
        }) {
            UpgradesView(board: board, onTravel: {
                guard board.canTravel, !travelRequested else { return }
                travelRequested = true
                showingUpgrades = false
            })
        }
        .alert("Reset all progress?", isPresented: $showingResetConfirmation) {
            Button("Reset All", role: .destructive) {
                board.resetAll()
                showingQuests = false
                fieldID = UUID()
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear { board.resolveIfNeeded() }
        .onChange(of: fieldID) { _ in board.resolveIfNeeded() }
        .onDisappear { closeDev() }
        .task(id: devPreviewRequest) {
            guard devPreviewRequest != nil else { return }
            do { try await Task.sleep(nanoseconds: 1_000_000_000) } catch { return }
            #if DEBUG
            board.previewDiscovery()
            #endif
            devPreviewRequest = nil
        }
    }

    private var gameContent: some View {
        VStack(spacing: 0) {
            if showingQuests {
                QuestsView(collection: board.collection, onClose: { showingQuests = false })
            } else {
                StatsBarView(gold: board.gold, days: board.days)
                TileBoardView(pieces: board.pieces, collectedIDs: board.collectedIDs,
                              spawnRows: board.spawnRows, isResolving: board.isResolving || board.isTraveling, onSwap: board.swap)
                    .id(fieldID)
                    .opacity(board.isTraveling ? 0 : 1)
                    .animation(board.isTraveling ? .easeOut(duration: GameBoard.travelFadeDuration) : nil,
                               value: board.isTraveling)
                    .background(SoilBackground())
                    .modifier(DiscoveryCelebration(event: board.discoveryEvent))
            }
        }
    }

    private func closeDev() {
        devPreviewRequest = nil
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.22)) { showingDev = false }
    }
}
