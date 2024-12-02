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

    var onSuspend: (() async -> Void)?
    var onResume: (() async -> Void)?

    func body(content: Content) -> some View {
        content
            .task(id: scenePhase) {
                Self.logger.debug("Scene phase changing to \(String(describing: scenePhase))")
                if (scenePhase == .active) {
                    await onResume?()
                } else {
                    await onSuspend?()
                }
            }
    }
}

extension View {
    func suspendable(
        onSuspend: (@MainActor @Sendable () async -> Void)? = nil,
        onResume: (@MainActor @Sendable () async -> Void)? = nil
    ) -> some View {
        modifier(
            SuspendResumeModifier(onSuspend: onSuspend, onResume: onResume)
        )
    }
}
