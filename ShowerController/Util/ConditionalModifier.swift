//
//  ConditionalModifier.swift
//  ShowerController
//
//  Created by Nigel Hannam on 20/11/2024.
//

import Foundation
import SwiftUI

extension View {
    @ViewBuilder func `if`<T>(_ condition: Bool, transform: (Self) -> T) -> some View where T : View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
