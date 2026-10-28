import SwiftUI

struct TeamPickerView: View {
    @State private var viewModel: TeamPickerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var didAdd = false

    init(viewModel: TeamPickerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .searchable(text: $viewModel.query, prompt: "Search by name or number")
                .navigationTitle("Add to Team")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
                .sensoryFeedback(.success, trigger: didAdd) { _, new in new }
                .sensoryFeedback(.error, trigger: viewModel.pickErrorMessage) { _, new in new != nil }
                .alert(
                    "Couldn't Add Pokémon",
                    isPresented: Binding(
                        get: { viewModel.pickErrorMessage != nil },
                        set: { if !$0 { viewModel.pickErrorMessage = nil } }
                    )
                ) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(viewModel.pickErrorMessage ?? "")
                }
        }
        .task(id: viewModel.query) {
            await viewModel.loadResults()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()

        case .results(let matches) where matches.isEmpty:
            ContentUnavailableView.search(text: viewModel.query)

        case .results(let matches):
            List(matches, id: \.id) { summary in
                Button {
                    Task {
                        if await viewModel.pick(summary) {
                            didAdd = true
                            dismiss()
                        }
                    }
                } label: {
                    HStack {
                        Text(verbatim: "#" + String(format: "%03d", summary.id))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                        Text(summary.name.capitalized)
                            .foregroundStyle(.primary)
                        Spacer()
                        if viewModel.pickingID == summary.id {
                            ProgressView()
                        }
                    }
                }
                .disabled(viewModel.pickingID != nil)
            }
            .listStyle(.plain)

        case .error(let message):
            ErrorStateView(message: message, onRetry: viewModel.retry)
        }
    }
}

#Preview {
    let repository = MockPokemonRepository()
    TeamPickerView(
        viewModel: TeamPickerViewModel(
            search: SearchPokemonUseCase(repository: repository),
            repository: repository,
            team: MockTeamRepository(),
            excludedIDs: [1]
        )
    )
}
