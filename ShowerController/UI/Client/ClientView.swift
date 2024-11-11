//
//  ClientView.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI
import SwiftData

struct ClientView: View {
    @Query var clients: [Client]
    private var client: Client? { clients.first }

    @State private var isEditing = false

    var body: some View {
        VStack {
            if let client {
                Button(
                    action: { isEditing = true },
                    label: {
                        Label(
                            title: { Text(client.name) },
                            icon: { Image(systemName: "iphone")}
                        )
                    }
                )
                .tint(.black)
            }
        }
        .onChange(of: client, initial: true) {
            isEditing = (client == nil)
        }
        .sheet(isPresented: $isEditing) {
            EditClientView(client: client)
        }
    }
}

#Preview {
    Preview {
        return ClientView()
    }
}

