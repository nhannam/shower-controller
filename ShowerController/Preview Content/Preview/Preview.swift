//
//  Preview.swift
//  ShowerController
//
//  Created by Nigel Hannam on 18/11/2024.
//

import Foundation
import SwiftData
import SwiftUI

struct Preview<Component: View>: View {
    @State private var tools: Toolbox
    
    var component: () -> Component
    
    var modelContext: ModelContext {
        tools.modelContainer.mainContext
    }
    
    init(component: @escaping () -> Component) {
        do {
            self.tools = try Toolbox(.mock)
            self.component = component
        } catch {
            fatalError("Could not initialize ModelContainer")
        }

        do {
            try modelContext.transaction {
                insertClients()
                insertDevices()
            }
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some View {
        Group {
            NavigationStack {
                component()
            }
            .task {
                await tools.startBluetoothProcessing()
            }
            .environment(tools)
            .monitoModelContextTransactions(modelContext)
        }
        .modelContainer(tools.modelContainer)
        .alertingErrorHandler(tools.errorHandler)
        .asyncJobExecutor(tools.asyncJobs)
    }
    
    func insertClients() {
        modelContext.insert(PreviewData.data.client)
    }
    
    func insertDevices() {
        modelContext.insert(PreviewData.data.device)
        modelContext.insert(PreviewData.data.unpairedDevice)
    }
}

@MainActor
class PreviewData {
    @MainActor static let data = PreviewData()
    
    let client = Client(clientId: UUID(), name: "Preview Client", secret: Data([0x00, 0x01, 0x02, 0x03]))
    
    static let outlet0 = Outlet(outletSlot: Device.outletSlot0, type: .overhead, minimumTemperature: 30, maximumTemperature: 48, maximumDurationSeconds: 1800)
    static let outlet1 = Outlet(outletSlot: Device.outletSlot1, type: .bath, minimumTemperature: 30, maximumTemperature: 48, maximumDurationSeconds: 1800)
    let device = Device(
        id: UUID(),
        name: "Preview Device",
        nickname: "Bathroom",
        manufacturerName: "Moira",
        modelNumber: "1001",
        hardwareRevision: "2001",
        firmwareRevision: "3001",
        serialNumber: "4001",
        outlets: [ outlet0, outlet1 ],
        outletsSwitched: false,
        presets: [
            Preset(presetSlot: 0, name: "Warm Bath", outlet: outlet1, targetTemperature: 45, durationSeconds: 2420)
        ],
        defaultPresetSlot: 0,
        clientSlot: 0,
        pairedClients: [
            PairedClient(clientSlot: 0, name: "Paired Client 0"),
            PairedClient(clientSlot: 1, name: "Paired Client 1")
        ],
        technicalInformation: TechnicalInformation(
            valveType: 44,
            valveSoftwareVersion: 8,
            uiType: 33,
            uiSoftwareVersion: 6,
            bluetoothSoftwareVersion: 4
        ),
        standbyLightingEnabled: true,
        timerState: .off,
        lastTimerStateReceived: Date.distantPast,
        updatesLockedOutUntil: Date.distantPast,
        selectedTemperature: 42,
        targetTemperature: 42,
        actualTemperature: 30,
        secondsRemaining: 320
    )
    let unpairedDevice = Device(
        id: UUID(),
        name: "Unpaired Device",
        outlets: [
            Outlet(outletSlot: Device.outletSlot0, type: .overhead),
            Outlet(outletSlot: Device.outletSlot1, type: .bath)
        ]
    )
}
