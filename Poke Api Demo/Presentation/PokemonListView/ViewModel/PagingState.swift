enum PagingState: Equatable {
    case idle
    case loading
    case failed(String)
    case exhausted
}
