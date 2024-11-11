//
//  WithTimeout.swift
//  ShowerController
//
//  Created by Nigel Hannam on 10/11/2024.
//

import Foundation

enum TimeoutError: Error {
    case operationTimedOut
}

func withTimeout<R: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    _ duration: Duration = .seconds(5),
    error: Error = TimeoutError.operationTimedOut,
    @_inheritActorContext _ operation: @escaping @Sendable () async throws -> R
) async throws -> R {
    return try await withThrowingTaskGroup(of: R.self) { group in
        group.addTask {
            do {
                let response = try await operation()
                return response
            } catch {
                throw error
            }
        }
        group.addTask {
            try await Task.sleep(for: duration)
            throw error
        }
        
        defer {
            group.cancelAll()
        }
        
        if let response = try await group.next() {
            return response
        } else {
            // This is only likely to happen if the task is cancelled
            // before either task finishes
            throw error
        }
    }
}
