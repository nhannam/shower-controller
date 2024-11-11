//
//  UnpairedDeviceSectionView.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI
import SwiftData

struct UnpairedDeviceSectionView: View {
    @Query(filter: DeviceService.UNPAIRED_PREDICATE) private var devices: [Device]
    
    var isScanning: Bool
    
    var body: some View {
        Section(
            content: {
                ForEach(devices) { device in
                    PairDeviceButton(device: device)
                }
            },
            header: {
                HStack() {
                    Text("Unpaired")
                    if isScanning {
                        ProgressView()
                    }
                }
            }
        )
    }
}

#Preview {
    Preview {
        UnpairedDeviceSectionView(
            isScanning: true
        )
    }
}
