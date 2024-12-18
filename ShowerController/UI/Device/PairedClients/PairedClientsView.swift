//
//  PairedClientsView.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI

struct PairedClientsView: View {
    private static let logger = LoggerFactory.logger(PairedClientsView.self)
    
    @Environment(Toolbox.self) private var tools

    var device: Device

    @State private var errorHandler = ErrorHandler()
    @State private var selected: PairedClient?

    var body: some View {
        List {
            ForEach(device.pairedClients.sorted(by: \.clientSlot)) { client in
                PairedClientListItemView(
                    action: { selected = client },
                    pairedClient: client,
                    isCurrent: device.clientSlot == client.clientSlot)
            }
        }
        .sheet(item: $selected) { pairedClient in
            EditPairedClientView(device: device, pairedClient: pairedClient)
        }
        .navigationTitle("Clients")
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
