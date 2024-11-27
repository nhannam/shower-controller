//
//  AsyncRequestResponseChannel.swift
//  ShowerController
//
//  Created by Nigel Hannam on 10/11/2024.
//

import Foundation
import AsyncAlgorithms

enum AsyncRequestResponseChannelError: Error {
    case noResponse
}

class AsyncRequestResponseChannel {
    private let logger = LoggerFactory.logger(AsyncRequestResponseChannel.self)
    
    private var requestChannel: AsyncChannel<any Responding> = AsyncChannel()
    
    func start(isolation: isolated (any Actor)? = #isolation) async {
        logger.info("Starting channel processing")
        for await responding in requestChannel {
            logger.debug("Processing channel request")
            
            await responding.execute()

            logger.debug("Processed channel request")
        }
        logger.info("Finished channel processing")
    }
    
    func finish() {
        requestChannel.finish()
    }

    func submit<Response: Sendable>(isolation: isolated (any Actor)? = #isolation, @_inheritActorContext operation: @escaping @Sendable () async throws -> Response) async throws -> Response {
        // Send request to channel along with a continuation that will be called with the response
        let responding = SendableResponding(operation: operation)
        await requestChannel.send(responding)
        do {
            return try await responding.awaitResponse()
        } catch {
            throw error
        }
    }
    

    protocol Responding: Sendable {
        associatedtype Response : Sendable

        func execute() async
        func awaitResponse() async throws -> Self.Response
    }
    

    final class SendableResponding<Response: Sendable>: Responding {
        private let logger = LoggerFactory.logger(SendableResponding.self)

        private let operation: @Sendable () async throws -> Response
        private let responseStream: AsyncThrowingStream<Response, Error>
        private let responseContinuation: AsyncThrowingStream<Response, Error>.Continuation

        init(operation: @escaping @Sendable () async throws -> Response) {
            let (stream, continuation) = AsyncThrowingStream<Response, Error>
                .makeStream(
                    throwing: Error.self,
                    bufferingPolicy: .unbounded
                )
            self.responseStream = stream
            self.responseContinuation = continuation
            self.operation = operation
        }
        
        func execute() async {
            do {
                // execute operation
                let response = try await operation()

                responseContinuation.yield(response)
                responseContinuation.finish()
            } catch {
                responseContinuation.finish(throwing: error)
            }
        }
        
        func awaitResponse() async throws -> Response {
            for try await response in responseStream {
                return response
            }
            
            throw AsyncRequestResponseChannelError.noResponse
        }
    }
}
