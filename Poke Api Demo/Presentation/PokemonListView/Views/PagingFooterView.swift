import SwiftUI

struct PagingFooterView: View {
    let state: PagingState
    let onRetry: () async -> Void

    var body: some View {
        Group {
            switch state {
            case .idle, .loading:
                ProgressView()

            case .failed(let message):
                VStack(spacing: 8) {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Try Again") {
                        Task { await onRetry() }
                    }
                    .buttonStyle(.bordered)
                }

            case .exhausted:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }
}

#Preview {
    VStack {
        PagingFooterView(state: .loading, onRetry: {})
        PagingFooterView(state: .failed(AppError.networkError("offline").localizedDescription), onRetry: {})
    }
}
