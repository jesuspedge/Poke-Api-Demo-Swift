import SwiftUI

// How many team members are weak to, resist, or are immune to one attacking type.
struct DefenseRow: View {
    let matchup: TeamAnalysis.DefensiveMatchup

    var body: some View {
        HStack(spacing: 8) {
            Label(matchup.type.displayName, systemImage: matchup.type.icon)
                .foregroundStyle(matchup.type.color)
                .frame(maxWidth: .infinity, alignment: .leading)

            if matchup.isSharedWeakness {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .accessibilityLabel("Shared weakness")
            }

            CountBadge(count: matchup.weak, label: "weak", color: .red)
            CountBadge(count: matchup.resistant, label: "resist", color: .green)
            CountBadge(count: matchup.immune, label: "immune", color: .blue)
        }
        .font(.subheadline)
        .listRowBackground(matchup.isSharedWeakness ? Color.orange.opacity(0.12) : nil)
        .accessibilityElement(children: .combine)
    }
}

private struct CountBadge: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        Text("\(count) \(label)")
            .font(.caption.weight(.semibold).monospacedDigit())
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .foregroundStyle(count > 0 ? color : .secondary)
            .background((count > 0 ? color : .secondary).opacity(0.12), in: .capsule)
    }
}

#Preview {
    List {
        DefenseRow(matchup: .init(type: .rock, weak: 3, resistant: 1, immune: 0))
        DefenseRow(matchup: .init(type: .ground, weak: 0, resistant: 1, immune: 2))
    }
}
