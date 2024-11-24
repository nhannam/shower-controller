//
//  AsyncJobExecutor.swift
//  ShowerController
//
//  Created by Nigel Hannam on 27/10/2024.
//

import Foundation

@MainActor
class AsyncJobExecutor {
    private static let logger = LoggerFactory.logger(AsyncJobExecutor.self)

    private var stream: AsyncStream<@MainActor () async -> Void>?
    private var continuation: AsyncStream<@MainActor () async -> Void>.Continuation?
    
    func start() async {
        let (stream, continuation) = AsyncStream<@MainActor () async -> Void>
            .makeStream(bufferingPolicy: .unbounded)
        self.stream = stream
        self.continuation = continuation
        
        Self.logger.debug("task starting")
        
        defer {
            Self.logger.debug("task finished")
        }

        for await job in stream {
            if Task.isCancelled {
                Self.logger.debug("task cancelled")
                break
            }
            Self.logger.debug("processing task job")
            await job()
            Self.logger.debug("processed task job")
        }

    }
    
    func submit(_ job: @escaping @MainActor () async -> Void) {
        Self.logger.debug("submitting job")
        self.continuation?.yield(job)
        Self.logger.debug("job submitted")
    }
}
