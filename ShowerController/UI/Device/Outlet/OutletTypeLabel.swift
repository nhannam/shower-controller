//
//  OutletTypeLabel.swift
//  ShowerController
//
//  Created by Nigel Hannam on 31/10/2024.
//

import SwiftUI

struct OutletTypeLabel: View {
    var type: Outlet.OutletType
    var isActive = false
    
    var body: some View {
        Label(
            title: { Text(type.description) },
            icon: { OutletTypeImage(type: type, isActive: isActive) }
        )
    }
}

#Preview {
    OutletTypeLabel(
        type: Outlet.OutletType.bath,
        isActive: true
    )
}
