//
//  ErrorHandlingModifier.swift
//  ShowerController
//
//  Created by Nigel Hannam on 27/10/2024.
//

import Foundation
import SwiftUI

@Observable
@MainActor
class AlertingErrorHandler {
    private static let logger = LoggerFactory.logger(AlertingErrorHandler.self)
    
    enum WrappedError: LocalizedError {
        case wrapped(error: Error)
    }

    fileprivate var localizedError: (any LocalizedError)? = nil
    fileprivate var showError = false
    
    func alertOnError(_ job: @escaping @MainActor () async throws -> Void) async {
        do {
            try await job()
            localizedError = nil
        } catch BluetoothServiceError.cancelled {
            Self.logger.info("Bluetooth operation cancelled")
        } catch let error as LocalizedError {
            localizedError = error
        } catch {
            localizedError = WrappedError.wrapped(error: error)
        }
        
        showError = localizedError != nil
    }
}

struct AlertingErrorHandlerModifier: ViewModifier {
    private static let logger = LoggerFactory.logger(AlertingErrorHandlerModifier.self)
    
    @Bindable var errorHandler: AlertingErrorHandler

    func body(content: Content) -> some View {
        content
            .alert(
                errorHandler.localizedError?.localizedDescription ?? "Unexpected Error",
                isPresented: $errorHandler.showError,
                presenting: errorHandler.localizedError,
                actions: {_ in
                    Button("OK") {
                        errorHandler.localizedError = nil
                    }
                },
                message:  { error in
                    VStack {
                        if let recoverySuggestion = error.recoverySuggestion {
                            Text(recoverySuggestion)
                        } else if let failureReason = error.failureReason {
                            Text(failureReason)
                        }
                    }
                }
            )
    }
    
}

extension View {
    func alertingErrorHandler(_ errorHandler: AlertingErrorHandler) -> some View {
        return environment(errorHandler)
            .modifier(
                AlertingErrorHandlerModifier(errorHandler: errorHandler)
            )
    }
}
