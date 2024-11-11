//
//  OutletTypeDescription.swift
//  ShowerController
//
//  Created by Nigel Hannam on 31/10/2024.
//

import SwiftUI

extension OutletType {
    var description: String {
        switch self {
        case .overhead:
            "Overhead Shower"
        case .bath:
            "Bath"
        }
    }
}
