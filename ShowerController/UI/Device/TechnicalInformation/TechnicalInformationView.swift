//
//  TechnicalInformationView.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI

struct TechnicalInformationView: View {
    private static let logger = LoggerFactory.logger(SettingsView.self)
    
    @Environment(Toolbox.self) private var tools
    
    var device: Device

    @State private var errorHandler = ErrorHandler()

    func makeItem(label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
    
    func makeItem(label: String, value: UInt16) -> some View {
        return makeItem(label: label, value: String(value))
    }
    
    var body: some View {
        List {
            Section(
                header: Text("Device Information"),
                content: {
                    makeItem(label: "Manufacturer", value: device.manufacturerName)
                    makeItem(label: "Model Number", value: device.modelNumber)
                    makeItem(label: "Hardware Revision", value: device.hardwareRevision)
                    makeItem(label: "Firmware Revision", value: device.firmwareRevision)
                    makeItem(label: "Serial Number", value: device.serialNumber)
                }
            )
            
            if let technicalInformation = device.technicalInformation {
                Section(
                    header: Text("Valve"),
                    content: {
                        makeItem(label: "Type", value: technicalInformation.valveType)
                        makeItem(label: "Software Version", value: technicalInformation.valveSoftwareVersion)
                    }
                )
                
                if let userInterface = device.userInterface {
                    Section(
                        header: Text("UI"),
                        content: {
                            makeItem(label: "Type", value: userInterface.type)
                            makeItem(label: "Software Version", value: userInterface.softwareVersion)
                        }
                    )
                }
                
                Section(
                    header: Text("Bluetooth"),
                    content: {
                        makeItem(label: "Type", value: technicalInformation.bluetoothType)
                        makeItem(label: "Software Version", value: technicalInformation.bluetoothSoftwareVersion)
                    }
                )
            }
        }
        .navigationTitle("Technical Information")
        .alertingErrorHandler(errorHandler)
        .deviceStatePolling(device.id)
        .suspendable(
            onResume: refresh
        )
        .refreshable(action: refresh)
        .task(refresh)
    }
    
    func refresh() async {
        await errorHandler.handleError {
            try await tools.deviceService.requestTechnicalInformation(device.id)
        }
    }
}


#Preview {
    Preview {
        TechnicalInformationView(
            device: PreviewData.data.device
        )
    }
}
