import SwiftUI

struct GameView: View {
    @ObservedObject var board: GameBoard
    let onMainMenu: () -> Void
    @State private var fieldID = UUID()
    @State private var showingQuests = false
    @State private var showingDev = false
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
                questsSelected: showingQuests, hasUnread: board.collection.hasUnread,
                devSelected: showingDev, onDev: {
                    devPreviewRequest = nil
                    showingQuests = false
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.22)) { showingDev.toggle() }
                })
        }
        .alert("Reset all progress?", isPresented: $showingResetConfirmation) {
            Button("Reset All", role: .destructive) {
                board.resetAll()
                showingQuests = false
                fieldID = UUID()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears all gold and completed Quests, refreshes the board, and assigns a new Quest.")
        }
        .onAppear { board.resolveIfNeeded() }
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
                StatsBarView(gold: board.gold, completed: board.collection.completed.count)
                TileBoardView(pieces: board.pieces, collectedIDs: board.collectedIDs,
                              spawnRows: board.spawnRows, isResolving: board.isResolving, onSwap: board.swap)
                    .id(fieldID)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
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
