//
//  CirclePickerTrackView.swift
//  ShowerController
//
//  Created by Nigel Hannam on 26/11/2024.
//

import SwiftUI

struct CirclePickerHandleView: View {
    var handle: CirclePickerHandleConfig

    var body: some View {
        Capsule()
            .stroke(.black, lineWidth: handle.lineWidth)
            .fill(.white)
            .frame(
                width: handle.width,
                height: handle.height
            )
    }
}

#Preview {
    @Previewable @State var value = 32.0
    @Previewable @State var pendingValue: Double? = nil
    let valueRange = 30.0...48.0
    Preview {
        CirclePickerHandleView(
            handle: CirclePickerHandleConfig(
                value: $value,
                valueRange: valueRange,
                height: 40,
                width: 10,
                lineWidth: 2,
                updateValueWhileDragging: false,
                pendingValue: $pendingValue
            )
        )
    }
}
