enum TeamPickerState: Equatable {
    case loading
    case results([PokemonSummary])
    case error(String)
}
