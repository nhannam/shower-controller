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
class ErrorHandler {
    private static let logger = LoggerFactory.logger(ErrorHandler.self)
    
    enum WrappedError: LocalizedError {
        case wrapped(error: Error)
    }

    fileprivate var localizedError: (any LocalizedError)? = nil
    
    func handleError(_ job: @escaping @MainActor () async throws -> Void) async {
        do {
            try await job()
            localizedError = nil
        } catch BluetoothServiceError.cancelled, DeviceServiceError.cancelled {
            Self.logger.info("Operation cancelled")
        } catch let error as LocalizedError {
            localizedError = error
        } catch {
            localizedError = WrappedError.wrapped(error: error)
        }
    }
}

struct AlertingErrorHandlerModifier: ViewModifier {
    private static let logger = LoggerFactory.logger(AlertingErrorHandlerModifier.self)

    var errorHandler: ErrorHandler

    var isShowingError: Binding<Bool> {
        Binding {
            errorHandler.localizedError != nil
        } set: { _ in
            errorHandler.localizedError = nil
        }
    }

    func body(content: Content) -> some View {
        content
            .alert(
                errorHandler.localizedError?.localizedDescription ?? "Unexpected Error",
                isPresented: isShowingError,
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
    func alertingErrorHandler(_ errorHandler: ErrorHandler) -> some View {
        return modifier(
            AlertingErrorHandlerModifier(errorHandler: errorHandler)
        )
    }
}
