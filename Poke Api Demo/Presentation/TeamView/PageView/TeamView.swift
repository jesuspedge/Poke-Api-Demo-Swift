import SwiftUI

struct TeamView: View {
    @State private var viewModel: TeamViewModel
    @Namespace private var zoom
    @State private var isPickerPresented = false
    // Bumped on swipe-to-remove only, not when the team shrinks after a change on another screen.
    @State private var removeFeedback = 0

    init(viewModel: TeamViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Inside the stack, so it runs again when popping back from a detail screen.
                .task {
                    await viewModel.load()
                }
                .navigationTitle("TEAM")
                .navigationBarTitleDisplayMode(.inline)
                .pokemonDestinations(zoom: zoom)
                .toolbar {
                    Button("Add Pokémon", systemImage: "plus") {
                        isPickerPresented = true
                    }
                    .disabled(!viewModel.canAddMore)
                }
                // A sheet doesn't re-run .task, so reload when it closes.
                .sheet(isPresented: $isPickerPresented, onDismiss: { Task { await viewModel.load() } }) {
                    TeamPickerView(
                        viewModel: AppFactory.makeTeamPickerViewModel(excluding: Set(viewModel.members.map(\.id)))
                    )
                }
                .sensoryFeedback(.impact, trigger: removeFeedback)
                .sensoryFeedback(.error, trigger: viewModel.removeErrorMessage) { _, new in new != nil }
                .alert(
                    "Couldn't Update Team",
                    isPresented: Binding(
                        get: { viewModel.removeErrorMessage != nil },
                        set: { if !$0 { viewModel.removeErrorMessage = nil } }
                    )
                ) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(viewModel.removeErrorMessage ?? "")
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        // .initial must render a real view: .task on an EmptyView never fires.
        case .initial, .loading:
            ProgressView()

        case .success(let members) where members.isEmpty:
            ContentUnavailableView {
                Label("No Team Yet", systemImage: "person.3")
            } description: {
                Text("Add up to \(TeamAnalysis.maxTeamSize) Pokémon to see their weaknesses and coverage.")
            } actions: {
                Button("Add Pokémon") { isPickerPresented = true }
                    .buttonStyle(.borderedProminent)
            }

        case .success(let members):
            let analysis = viewModel.analysis
            List {
                Section("Members (\(members.count)/\(TeamAnalysis.maxTeamSize))") {
                    ForEach(members) { pokemon in
                        PokemonNavigationRow(pokemon: pokemon, namespace: zoom)
                            .swipeActions {
                                Button("Remove", systemImage: "person.crop.circle.badge.minus", role: .destructive) {
                                    removeFeedback += 1
                                    Task { await viewModel.remove(pokemon) }
                                }
                            }
                    }
                }

                Section {
                    ForEach(analysis.defense, id: \.type) { matchup in
                        DefenseRow(matchup: matchup)
                    }
                } header: {
                    Text("Defense")
                } footer: {
                    if !analysis.sharedWeaknesses.isEmpty {
                        Text(
                            "Shared weaknesses: \(analysis.sharedWeaknesses.map(\.displayName).formatted(.list(type: .and)))."
                        )
                    }
                }

                OffenseSection(analysis: analysis)
            }

        case .error(let message):
            ErrorStateView(message: message, onRetry: viewModel.load)
        }
    }
}

#if DEBUG
#Preview {
    TeamView(viewModel: TeamViewModel(team: MockTeamRepository(seedIDs: [1, 4])))
}
#endif
