//
//  ScanResult.swift
//  ShowerController
//
//  Created by Nigel Hannam on 27/11/2024.
//

import Foundation
import SwiftData

@Model
class ScanResult {
    @Attribute(.unique)
    private(set) var id: UUID
    private(set)var name: String
    
    init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }
}
