//
//  UnpairedDeviceSectionView.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI
import SwiftData

struct UnpairedDeviceSectionView: View {
    @Query private var devices: [Device]
    @Query private var scanResults: [ScanResult]
    
    var isScanning: Bool
    
    var body: some View {
        let deviceIds = devices.map(\.id)
        Section(
            content: {
                ForEach(scanResults.filter({ !deviceIds.contains($0.id)})) { scanResult in
                    PairDeviceButton(scanResult: scanResult)
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
