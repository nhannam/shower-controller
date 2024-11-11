//
//  OperationInProgressModifier.swift
//  ShowerController
//
//  Created by Nigel Hannam on 27/10/2024.
//

import Foundation
import SwiftUI

struct OperationInProgressModifier: ViewModifier {
    var inProgress: Bool

    func body(content: Content) -> some View {
        content
            .disabled(inProgress)
            .overlay(
                content: {
                    if inProgress {
                        ZStack {
                            Color(.white)
                                .opacity(0.25)
                            ProgressView()
                                .scaleEffect(3)
                        }
                    }
                }
            )
    }
}

extension View {
    func operationInProgress(
        _ inProgress: Bool
    ) -> some View {
        modifier(
            OperationInProgressModifier(inProgress: inProgress)
        )
    }
}
