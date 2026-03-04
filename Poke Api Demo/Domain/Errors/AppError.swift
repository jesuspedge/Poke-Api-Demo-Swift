//
//  AppError.swift
//  Poke Api Demo
//
//  Created by Roger Bacab on 04/03/26.
//

enum AppError: Error {
    case networkError(String)
    case decodingError(String)
    case unknown
}
