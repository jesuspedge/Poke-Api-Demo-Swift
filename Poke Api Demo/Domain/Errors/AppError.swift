//
//  AppError.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 04/03/26.
//

import Foundation

enum AppError: Error, Equatable, LocalizedError {
    case networkError(String)
    case httpStatus(Int)
    case decodingError(String)
    case invalidURL
    case persistence(String)
    case teamFull
    case unknown

    var errorDescription: String? {
        switch self {
        case .networkError:
            String(localized: "We couldn't reach the server. Check your connection and try again.")
        case .httpStatus(let code):
            String(localized: "The server responded with an unexpected status (\(code)).")
        case .decodingError:
            String(localized: "We received data we couldn't read.")
        case .invalidURL:
            String(localized: "The request address is invalid.")
        case .persistence:
            String(localized: "We couldn't save your changes.")
        case .teamFull:
            String(localized: "Your team already has \(TeamAnalysis.maxTeamSize) Pokémon.")
        case .unknown:
            String(localized: "An unknown error occurred.")
        }
    }
}
