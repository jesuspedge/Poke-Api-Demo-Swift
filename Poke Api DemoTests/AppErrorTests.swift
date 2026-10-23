import Foundation
import Testing
@testable import Poke_Api_Demo

struct AppErrorTests {
    @Test(arguments: [
        AppError.networkError("offline"),
        .httpStatus(500),
        .decodingError("bad json"),
        .invalidURL,
        .unknown,
    ])
    func localizedDescriptionUsesCustomMessage(error: AppError) {
        let description = (error as Error).localizedDescription

        #expect(description == error.errorDescription)
        #expect(!description.contains("couldn’t be completed"))
    }

    @Test func httpStatusMessageIncludesStatusCode() {
        #expect(AppError.httpStatus(503).localizedDescription.contains("503"))
    }
}
