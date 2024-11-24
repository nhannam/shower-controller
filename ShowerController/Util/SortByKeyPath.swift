//
//  ArraySortByKeypath.swift
//  ShowerController
//
//  Created by Nigel Hannam on 24/11/2024.
//

import SwiftUI

extension Sequence {
    func sorted<Value: Comparable>(by keyPath: KeyPath<Self.Element, Value>) -> [Self.Element] {
        return sorted(by: { a, b in a[keyPath: keyPath] < b[keyPath: keyPath] })
    }
}
