//
//  AsyncJobExecutorModifier.swift
//  ShowerController
//
//  Created by Nigel Hannam on 27/10/2024.
//

import Foundation
import SwiftUI

@MainActor
class AsyncJobs {
    private static let logger = LoggerFactory.logger(AsyncJobs.self)

    private var stream: AsyncStream<@MainActor () async -> Void>?
    private var continuation: AsyncStream<@MainActor () async -> Void>.Continuation?
    
    fileprivate func start() -> AsyncStream<@MainActor () async -> Void> {
        let (stream, continuation) = AsyncStream<@MainActor () async -> Void>
            .makeStream(bufferingPolicy: .unbounded)
        self.stream = stream
        self.continuation = continuation
        return stream
    }
    
    func submit(_ job: @escaping @MainActor () async -> Void) {
        Self.logger.debug("submitting job")
        self.continuation?.yield(job)
        Self.logger.debug("job submitted")
    }
}

struct AsyncJobExecutorModifier: ViewModifier {
    private static let logger = LoggerFactory.logger(AsyncJobExecutorModifier.self)
    
    let asyncJobs: AsyncJobs
    
    func body(content: Content) -> some View {
        content
            .task(jobExecutingTask)
    }
    
    func jobExecutingTask() async {
        Self.logger.debug("task starting")
        
        defer {
            AsyncJobExecutorModifier.logger.debug("task finished")
        }
        
        for await job in asyncJobs.start() {
            if Task.isCancelled {
                AsyncJobExecutorModifier.logger.debug("task cancelled")
                break
            }
            AsyncJobExecutorModifier.logger.debug("processing task job")
            await job()
            AsyncJobExecutorModifier.logger.debug("processed task job")
        }
    }
    
    
}

extension View {
    func asyncJobExecutor(_ asyncJobs: AsyncJobs) -> some View {
        return modifier(
            AsyncJobExecutorModifier(
                asyncJobs: asyncJobs
            )
        )
    }
}
