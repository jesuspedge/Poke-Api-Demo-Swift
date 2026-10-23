import SwiftUI

struct ErrorStateView: View {
    let message: String
    let onRetry: () async -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Something went wrong", systemImage: "exclamationmark.circle")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                Task { await onRetry() }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    ErrorStateView(message: AppError.networkError("offline").localizedDescription, onRetry: {})
}
