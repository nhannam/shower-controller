//
//  OutletPicker.swift
//  ShowerController
//
//  Created by Nigel Hannam on 24/11/2024.
//

import SwiftUI

struct OutletPicker: View {
    let outlets: [Outlet]
    @Binding var selected: Outlet?
    
    var body: some View {
        Picker("Outlet", selection: $selected) {
            ForEach(outlets) { outlet in
                OutletTypeLabel(type: outlet.type).tag(outlet)
            }
        }
    }
}

#Preview {
    @Previewable @State var selected: Outlet? = PreviewData.data.device.outletsSortedBySlot[1]
    Preview {
        OutletPicker(
            outlets: PreviewData.data.device.outletsSortedBySlot,
            selected: $selected
        )
    }
}
