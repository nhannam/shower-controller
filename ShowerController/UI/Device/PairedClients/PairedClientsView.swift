//
//  PairedClientsView.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI
import SwiftData

struct PairedClientsView: View {
    private static let logger = LoggerFactory.logger(PairedClientsView.self)
    
    @Environment(Toolbox.self) private var tools

    var device: Device

    @State private var selected: PairedClient?

    @State private var updateCounter: Int64 = 0
    
    var body: some View {
        Group {
            ModelUpdatedMonitorViewModifier.RedrawTrigger(updatedCounter: updateCounter)
            List {
                ForEach(device.pairedClients.sorted(by: { $0.clientSlot < $1.clientSlot })) { client in
                    PairedClientListItemView(
                        action: { selected = client },
                        pairedClient: client,
                        isCurrent: device.clientSlot == client.clientSlot)
                }
            }
        }
        .sheet(item: $selected) { pairedClient in
            EditPairedClientView(device: device, pairedClient: pairedClient)
        }
        .navigationTitle("Clients")
        .deviceStatePolling(device.id)
        .monitoringUpdatesOf(
            [device.persistentModelID] + device.pairedClients.map({ $0.persistentModelID }),
            $updateCounter)
        .suspendable(
            asyncJobs: tools.asyncJobs,
            onResume: refresh
        )
        .refreshable(action: refresh)
        .task(refresh)
    }
    
    func refresh() async {
        await tools.alertOnError {
            try await tools.deviceService.requestPairedClients(device.id)
        }
    }
}

#Preview {
    Preview {
        return PairedClientsView(
            device: PreviewData.data.device
        )
    }
}
