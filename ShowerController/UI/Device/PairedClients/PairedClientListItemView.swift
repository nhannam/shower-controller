//
//  PairedClientListItemView.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI

struct PairedClientListItemView: View {
    var action: () -> Void
    var pairedClient: PairedClient
    var isCurrent: Bool
    
    var body: some View {
        Button(
            action: action,
            label: {
                Label(
                    title: { Text(pairedClient.name) },
                    icon: { Image(systemName: isCurrent ? "iphone" : "iphone.slash")}
                )
            }
        )
        .tint(.secondary)
    }
}

#Preview {
    Preview {
        return PairedClientListItemView(
            action: {},
            pairedClient: PreviewData.data.device.pairedClients[0],
            isCurrent: true
        )
    }
}
