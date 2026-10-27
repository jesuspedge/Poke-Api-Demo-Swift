import Testing
@testable import Poke_Api_Demo

struct TeamAnalysisTests {
    private func matchup(_ type: PokemonType, in analysis: TeamAnalysis) -> TeamAnalysis.DefensiveMatchup? {
        analysis.defense.first { $0.type == type }
    }

    @Test func emptyTeamHasNoMatchupsOrCoverage() {
        let analysis = TeamAnalysis(team: [])

        #expect(analysis.defense.allSatisfy { $0.weak == 0 && $0.resistant == 0 && $0.immune == 0 })
        #expect(analysis.covered.isEmpty)
        #expect(analysis.uncovered == PokemonType.allCases)
        #expect(analysis.sharedWeaknesses.isEmpty)
    }

    @Test func defenseRowsFollowTypeOrder() {
        let analysis = TeamAnalysis(team: [.fixture(types: [.water])])

        #expect(analysis.defense.map(\.type) == PokemonType.allCases)
    }

    @Test func dualTypeMemberIsCountedOncePerAttackingType() {
        let charizard = PokemonEntity.fixture(id: 6, name: "charizard", types: [.fire, .flying])
        let analysis = TeamAnalysis(team: [charizard])

        // Rock is 4× against Fire/Flying but still one weak member.
        #expect(matchup(.rock, in: analysis) == .init(type: .rock, weak: 1, resistant: 0, immune: 0))
        #expect(matchup(.ground, in: analysis) == .init(type: .ground, weak: 0, resistant: 0, immune: 1))
        #expect(matchup(.grass, in: analysis) == .init(type: .grass, weak: 0, resistant: 1, immune: 0))
        // Water is 2× against Fire and 1× against Flying.
        #expect(matchup(.water, in: analysis)?.weak == 1)
    }

    @Test func twoWeakMembersMakeASharedWeakness() {
        // Water and Ground both hit Fire and Rock/Ground super-effectively.
        let team = [
            PokemonEntity.fixture(id: 4, types: [.fire]),
            .fixture(id: 74, types: [.rock, .ground]),
        ]

        #expect(TeamAnalysis(team: team).sharedWeaknesses == [.water, .ground])
    }

    @Test func aResistantMemberClearsTheSharedWeakness() {
        let team = [
            PokemonEntity.fixture(id: 4, types: [.fire]),
            .fixture(id: 74, types: [.rock, .ground]),
            .fixture(id: 7, types: [.water]),
            .fixture(id: 60, types: [.water]),
        ]
        let water = matchup(.water, in: TeamAnalysis(team: team))

        #expect(water?.weak == 2)
        #expect(water?.resistant == 2)
        #expect(water?.isSharedWeakness == false)
    }

    @Test func offenseCoverageUsesTheTeamsOwnTypes() {
        let team = [
            PokemonEntity.fixture(id: 4, types: [.fire]),
            .fixture(id: 25, types: [.electric]),
        ]
        let analysis = TeamAnalysis(team: team)

        #expect(analysis.covered == [.water, .grass, .ice, .flying, .bug, .steel])
        #expect(Set(analysis.covered).isDisjoint(with: analysis.uncovered))
        #expect(analysis.covered.count + analysis.uncovered.count == PokemonType.allCases.count)
    }
}
