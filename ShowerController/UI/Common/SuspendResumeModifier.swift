//
//  SuspendResumeModifier.swift
//  ShowerController
//
//  Created by Nigel Hannam on 27/10/2024.
//

import Foundation
import SwiftUI

struct SuspendResumeModifier: ViewModifier {
    private static let logger = LoggerFactory.logger(SuspendResumeModifier.self)
    
    @Environment(\.scenePhase) private var scenePhase

    var onSuspend: (() -> Void)?
    var onResume: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .onChange(of: scenePhase) { old, new in
                Self.logger.debug("Scene phase changing from \(String(describing: old)) to \(String(describing: new))")
                if (scenePhase == .active) {
                    resume()
                } else {
                    suspend()
                }
            }
    }

    func suspend() {
        onSuspend?()
    }
    
    func resume() {
        onResume?()
    }
}

extension View {
    func suspendable(
        onSuspend: (() -> Void)? = nil,
        onResume: (() -> Void)? = nil
    ) -> some View {
        modifier(
            SuspendResumeModifier(onSuspend: onSuspend, onResume: onResume)
        )
    }
    
    func suspendable(
        asyncJobExecutor: AsyncJobExecutor,
        onSuspend: (@MainActor @Sendable () async -> Void)? = nil,
        onResume: (@MainActor @Sendable () async -> Void)? = nil
    ) -> some View {
        modifier(
            SuspendResumeModifier(
                onSuspend: { if let onSuspend { asyncJobExecutor.submit(onSuspend) } },
                onResume: { if let onResume { asyncJobExecutor.submit(onResume) } }
            )
        )
    }
}
