//
//  Notifier.swift
//  ShowerController
//
//  Created by Nigel Hannam on 10/11/2024.
//

import Foundation
@preconcurrency import Combine
import AsyncBluetooth

fileprivate class PublisherAsyncSequenceLogger {
    static let logger = LoggerFactory.logger(PublisherAsyncSequenceLogger.self)
}

class PublisherAsyncSequence<Element: Sendable>: AsyncSequence {
    private let asyncStream: AsyncStream<Element>
    //private let valuesPublisher: any Publisher<Element, Never>
    
    init(valuesPublisher: any Publisher<Element, Never>) {
        self.asyncStream = AsyncStream { continuation in
            
            // Produce item using yield
            let cancellable = valuesPublisher.sink { completion in
                continuation.finish()
            } receiveValue: { value in
                continuation.yield(value)
            }
        
            // Handle termination
            continuation.onTermination = { termination in
                PublisherAsyncSequenceLogger.logger.debug("Terminated notifier")

                // Cancel the publisher's subscription
                cancellable.cancel()
            }
        }
    }
    
    func makeAsyncIterator() -> AsyncStream<Element>.Iterator {
        return asyncStream.makeAsyncIterator()
    }
}
