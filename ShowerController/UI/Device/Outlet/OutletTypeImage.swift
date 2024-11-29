//
//  TemperatureLabel.swift
//  ShowerController
//
//  Created by Nigel Hannam on 31/10/2024.
//

import SwiftUI

struct OutletTypeImage: View {
    var type: Outlet.OutletType
    var isActive = false
    var resizable = false
    
    var body: some View {
        let name = switch type {
        case .overhead:
            "shower"
        case .handset:
            "shower.handheld"
        case .bath:
            "bathtub"
        }
        let systemImage = name + (isActive ? ".fill" : "")
        
        if (resizable) {
            Image(systemName: systemImage)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: systemImage)
        }
    }
}

#Preview {
    OutletTypeImage(
        type: Outlet.OutletType.bath,
        isActive: true
    )
}
