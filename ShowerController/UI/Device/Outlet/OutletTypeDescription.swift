//
//  OutletTypeDescription.swift
//  ShowerController
//
//  Created by Nigel Hannam on 31/10/2024.
//

import SwiftUI

extension Outlet.OutletType {
    var description: String {
        switch self {
        case .overhead:
            "Shower"
        case .handset:
            "Handset"
        case .bath:
            "Bath"
        }
    }
}
